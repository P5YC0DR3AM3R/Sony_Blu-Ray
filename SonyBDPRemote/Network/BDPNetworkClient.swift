import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Errors surfaced by the BDP network layer.
enum BDPError: LocalizedError {
    case invalidURL
    case badResponse
    case httpStatus(Int)
    case pinRequired
    case invalidPin
    case soapFault(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Could not build a valid URL from the configured IP/port."
        case .badResponse:
            return "The player returned an unexpected response."
        case .httpStatus(let code):
            return "The player responded with HTTP \(code)."
        case .pinRequired:
            return "The player is showing a PIN on the TV. Enter it to finish pairing."
        case .invalidPin:
            return "The entered PIN was incorrect. Please try again."
        case .soapFault(let detail):
            return "The player rejected the command: \(detail)"
        }
    }
}

/// Result of a pairing attempt against the CERS register endpoint.
enum PairingResult {
    /// Registration accepted immediately (already trusted, or no PIN mode).
    case registered
    /// The player displayed a PIN on the TV; call `completePairing(pin:)`.
    case pinDisplayed
}

/// Async/await network client for a Sony BDP-S5100 Blu-ray player.
///
/// Two operations are supported:
///  - CERS registration/pairing: `GET /cers/api/register`
///  - IRCC keypresses: `POST /IRCC` with a SOAP `X_SendIRCC` envelope
struct BDPNetworkClient {
    let config: EnvConfig
    private let session: URLSession

    init(config: EnvConfig, session: URLSession? = nil) {
        self.config = config
        if let session {
            self.session = session
        } else {
            let cfg = URLSessionConfiguration.ephemeral
            cfg.timeoutIntervalForRequest = 8
            cfg.timeoutIntervalForResource = 15
            self.session = URLSession(configuration: cfg)
        }
    }

    // MARK: - Pairing (CERS register)

    /// Starts the pairing sequence:
    /// `GET http://{IP}:{PORT}/cers/api/register?name=...&registrationType=initial&deviceId=...`
    ///
    /// On first contact the player shows a 4-digit PIN on the TV and answers
    /// 401 Unauthorized — that is the expected "PIN displayed" state. A 200
    /// means the device is already registered/trusted.
    func startPairing() async throws -> PairingResult {
        let (_, response) = try await session.data(for: registerRequest(pin: nil))
        guard let http = response as? HTTPURLResponse else { throw BDPError.badResponse }
        switch http.statusCode {
        case 200: return .registered
        case 401: return .pinDisplayed
        default: throw BDPError.httpStatus(http.statusCode)
        }
    }

    /// Completes pairing by re-issuing the register request with HTTP Basic
    /// authorization carrying the PIN shown on the TV (empty username).
    func completePairing(pin: String) async throws {
        let (_, response) = try await session.data(for: registerRequest(pin: pin))
        guard let http = response as? HTTPURLResponse else { throw BDPError.badResponse }
        switch http.statusCode {
        case 200: return
        case 401: throw BDPError.invalidPin
        default: throw BDPError.httpStatus(http.statusCode)
        }
    }

    private func registerRequest(pin: String?) throws -> URLRequest {
        guard let base = config.baseURL,
              var components = URLComponents(url: base.appendingPathComponent("cers/api/register"),
                                             resolvingAgainstBaseURL: false) else {
            throw BDPError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "name", value: config.deviceName),
            URLQueryItem(name: "registrationType", value: "initial"),
            URLQueryItem(name: "deviceId", value: config.deviceID),
        ]
        guard let url = components.url else { throw BDPError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(config.deviceID, forHTTPHeaderField: "X-CERS-DEVICE-ID")
        if let pin {
            let credentials = Data(":\(pin)".utf8).base64EncodedString()
            request.setValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    // MARK: - IRCC keypress

    /// Sends an IRCC keypress:
    /// `POST http://{IP}:{PORT}/IRCC` with the SOAP `X_SendIRCC` envelope and
    /// the `SOAPACTION` header required by the UPnP IRCC service.
    func send(_ command: IRCCCommand) async throws {
        try await sendIRCC(code: command.rawValue)
    }

    func sendIRCC(code: String) async throws {
        guard let base = config.baseURL else { throw BDPError.invalidURL }
        var request = URLRequest(url: base.appendingPathComponent("IRCC"))
        request.httpMethod = "POST"
        request.setValue("text/xml; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.setValue("\"urn:schemas-sony-com:service:IRCC:1#X_SendIRCC\"",
                         forHTTPHeaderField: "SOAPACTION")
        request.setValue(config.deviceID, forHTTPHeaderField: "X-CERS-DEVICE-ID")
        request.httpBody = Data(Self.soapEnvelope(irccCode: code).utf8)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw BDPError.badResponse }
        guard http.statusCode == 200 else {
            if http.statusCode == 500,
               let body = String(data: data, encoding: .utf8),
               let fault = Self.extractSOAPFault(from: body) {
                throw BDPError.soapFault(fault)
            }
            throw BDPError.httpStatus(http.statusCode)
        }
    }

    /// Builds the SOAP XML wrapper for an `X_SendIRCC` call.
    static func soapEnvelope(irccCode: String) -> String {
        """
        <?xml version="1.0" encoding="utf-8"?>\
        <s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" \
        s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">\
        <s:Body>\
        <u:X_SendIRCC xmlns:u="urn:schemas-sony-com:service:IRCC:1">\
        <IRCCCode>\(irccCode)</IRCCCode>\
        </u:X_SendIRCC>\
        </s:Body>\
        </s:Envelope>
        """
    }

    /// Pulls the `<errorDescription>`/`<faultstring>` text out of a SOAP
    /// fault body, if present. Tolerates namespace prefixes
    /// (`<s:faultstring>`) and attributes (`<faultstring xml:lang="en">`).
    static func extractSOAPFault(from body: String) -> String? {
        for tag in ["errorDescription", "faultstring"] {
            let openPattern = "<(?:[A-Za-z0-9]+:)?\(tag)(?:\\s[^>]*)?>"
            let closePattern = "</(?:[A-Za-z0-9]+:)?\(tag)>"
            guard let open = body.range(of: openPattern, options: .regularExpression),
                  let close = body.range(of: closePattern, options: .regularExpression),
                  open.upperBound <= close.lowerBound else { continue }
            let text = body[open.upperBound..<close.lowerBound]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty { return text }
        }
        return nil
    }
}
