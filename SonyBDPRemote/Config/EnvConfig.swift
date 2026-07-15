import Foundation

/// Runtime configuration for the Sony BDP remote, loaded from a `.env` file.
///
/// The `.env` file lives at the repository root (gitignored) and is copied
/// into the app bundle by the "Copy .env into bundle" build phase. At launch
/// the file is parsed dynamically; if it is missing, the documented defaults
/// are used so the app still runs.
struct EnvConfig: Equatable {
    let bdpIP: String
    let port: Int
    let deviceID: String
    let deviceName: String

    /// Where the parsed values came from, for display/diagnostics.
    let source: Source

    enum Source: String, Equatable {
        case dotEnvFile = ".env file"
        case defaults = "built-in defaults"
    }

    /// Fallback values, matching `.env.example`.
    static let fallback = EnvConfig(
        bdpIP: "192.168.1.150",
        port: 50001,
        deviceID: "MediaRemote:11-22-33-44-55-66",
        deviceName: "iOS_Custom_Remote",
        source: .defaults
    )

    var baseURL: URL? {
        URL(string: "http://\(bdpIP):\(port)")
    }

    // MARK: - Loading

    /// Loads configuration from the `.env` bundled with the app, falling back
    /// to `EnvConfig.fallback` when the file is absent or unreadable.
    static func load(bundle: Bundle = .main) -> EnvConfig {
        // Prefer the standard resource lookup (handles macOS's
        // Contents/Resources layout), then fall back to the flat iOS
        // bundle root where the build phase drops the dotfile.
        var candidates: [URL] = []
        for name in [".env", "env"] {
            if let url = bundle.url(forResource: name, withExtension: nil) {
                candidates.append(url)
            }
            candidates.append(bundle.bundleURL.appendingPathComponent(name))
        }
        for url in candidates {
            if let contents = try? String(contentsOf: url, encoding: .utf8) {
                return parse(contents)
            }
        }
        return .fallback
    }

    /// Parses `.env`-style `KEY=VALUE` text. Blank lines and `#` comments
    /// (full-line or inline) are ignored; values may be wrapped in single or
    /// double quotes, in which case `#` characters inside the quotes are
    /// preserved.
    static func parse(_ contents: String) -> EnvConfig {
        var values: [String: String] = [:]
        for rawLine in contents.split(whereSeparator: \.isNewline) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty, !line.hasPrefix("#") else { continue }
            guard let eq = line.firstIndex(of: "=") else { continue }
            let key = String(line[..<eq]).trimmingCharacters(in: .whitespaces)
            var value = String(line[line.index(after: eq)...]).trimmingCharacters(in: .whitespaces)
            if let quote = value.first, quote == "\"" || quote == "'" {
                let rest = value.dropFirst()
                if let closing = rest.firstIndex(of: quote) {
                    value = String(rest[..<closing])
                } else {
                    value = String(rest)
                }
            } else if let hash = value.firstIndex(of: "#") {
                value = String(value[..<hash]).trimmingCharacters(in: .whitespaces)
            }
            guard !key.isEmpty else { continue }
            values[key] = value
        }

        let fallback = EnvConfig.fallback
        return EnvConfig(
            bdpIP: values["BDP_IP"] ?? fallback.bdpIP,
            port: values["PORT"].flatMap(Int.init) ?? fallback.port,
            deviceID: values["DEVICE_ID"] ?? fallback.deviceID,
            deviceName: values["DEVICE_NAME"] ?? fallback.deviceName,
            source: values.isEmpty ? .defaults : .dotEnvFile
        )
    }
}
