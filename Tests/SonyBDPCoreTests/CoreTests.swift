import XCTest
@testable import SonyBDPCore

final class EnvConfigTests: XCTestCase {
    func testParsesDotEnvContents() {
        let config = EnvConfig.parse("""
        # Sony BDP config
        BDP_IP=192.168.1.150
        PORT=50001
        DEVICE_ID=MediaRemote:11-22-33-44-55-66
        DEVICE_NAME=iOS_Custom_Remote
        """)
        XCTAssertEqual(config.bdpIP, "192.168.1.150")
        XCTAssertEqual(config.port, 50001)
        XCTAssertEqual(config.deviceID, "MediaRemote:11-22-33-44-55-66")
        XCTAssertEqual(config.deviceName, "iOS_Custom_Remote")
        XCTAssertEqual(config.source, .dotEnvFile)
        XCTAssertEqual(config.baseURL?.absoluteString, "http://192.168.1.150:50001")
    }

    func testHandlesQuotesCommentsAndWhitespace() {
        let config = EnvConfig.parse("""
        BDP_IP = "10.0.0.9" # inline comment after quoted value
        PORT=50002 # inline comment after bare value

        # comment line
        DEVICE_ID="MediaRemote:#1"
        DEVICE_NAME=My Remote
        """)
        XCTAssertEqual(config.bdpIP, "10.0.0.9")
        XCTAssertEqual(config.port, 50002)
        // A hash inside quotes is part of the value, not a comment.
        XCTAssertEqual(config.deviceID, "MediaRemote:#1")
        XCTAssertEqual(config.deviceName, "My Remote")
    }

    func testMissingKeyFallsBackToDefault() {
        let config = EnvConfig.parse("BDP_IP=10.0.0.9")
        XCTAssertEqual(config.deviceID, EnvConfig.fallback.deviceID)
        XCTAssertEqual(config.deviceName, EnvConfig.fallback.deviceName)
        XCTAssertEqual(config.port, EnvConfig.fallback.port)
    }

    func testEmptyContentsFallsBackToDefaults() {
        let config = EnvConfig.parse("")
        XCTAssertEqual(config, EnvConfig.fallback)
        XCTAssertEqual(config.source, .defaults)
    }
}

final class SOAPEnvelopeTests: XCTestCase {
    func testEnvelopeWrapsIRCCCode() {
        let xml = BDPNetworkClient.soapEnvelope(irccCode: IRCCCommand.play.rawValue)
        XCTAssertTrue(xml.hasPrefix("<?xml version=\"1.0\" encoding=\"utf-8\"?>"))
        XCTAssertTrue(xml.contains("<IRCCCode>AAAAAwAAHFoAAAAaAw==</IRCCCode>"))
        XCTAssertTrue(xml.contains("urn:schemas-sony-com:service:IRCC:1"))
        XCTAssertTrue(xml.contains("<s:Body>"))
        XCTAssertTrue(xml.contains("</s:Envelope>"))
    }

    func testExtractsSOAPFault() {
        let body = "<s:Fault><faultstring>UPnPError</faultstring></s:Fault>"
        XCTAssertEqual(BDPNetworkClient.extractSOAPFault(from: body), "UPnPError")

        let namespaced = "<s:Fault><s:faultstring>Namespaced fault</s:faultstring></s:Fault>"
        XCTAssertEqual(BDPNetworkClient.extractSOAPFault(from: namespaced), "Namespaced fault")

        let attributed = "<s:Fault><faultstring xml:lang=\"en\">Attributed fault</faultstring></s:Fault>"
        XCTAssertEqual(BDPNetworkClient.extractSOAPFault(from: attributed), "Attributed fault")

        XCTAssertNil(BDPNetworkClient.extractSOAPFault(from: "<ok/>"))
    }

    func testAllCommandsHaveValidBase64Codes() {
        for command in IRCCCommand.allCases {
            XCTAssertNotNil(Data(base64Encoded: command.rawValue),
                            "\(command.label) code is not valid base64")
        }
    }
}
