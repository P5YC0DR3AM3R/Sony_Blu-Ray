import Foundation
import SwiftUI

/// Drives both the pairing flow and the remote-control screen.
@MainActor
final class RemoteViewModel: ObservableObject {
    enum PairingPhase: Equatable {
        case idle
        case requesting
        case awaitingPIN
        case verifying
        case paired
    }

    @Published var pairingPhase: PairingPhase = .idle
    @Published var enteredPIN: String = ""
    @Published var statusMessage: String?
    @Published var lastError: String?
    @Published private(set) var lastCommand: IRCCCommand?

    /// Persisted so the app skips the pairing screen on later launches.
    @AppStorage("isPaired") private var storedPaired = false

    let config: EnvConfig
    private let client: BDPNetworkClient

    init(config: EnvConfig = .load()) {
        self.config = config
        self.client = BDPNetworkClient(config: config)
        if storedPaired {
            pairingPhase = .paired
        }
    }

    var isPaired: Bool { pairingPhase == .paired }

    // MARK: - Connectivity self-test

    @Published var isTestingConnection = false

    /// Probes the configured IP/port and reports the result in the status
    /// line, so network problems can be diagnosed without attempting a full
    /// pairing round-trip.
    func testConnection() {
        lastError = nil
        statusMessage = "Testing \(config.bdpIP):\(config.port)…"
        isTestingConnection = true
        Task {
            let result = await client.checkReachability()
            isTestingConnection = false
            switch result {
            case .reachable(let status):
                statusMessage = "Player reachable (HTTP \(status)) — ready to pair."
            case .unreachable(let reason):
                statusMessage = nil
                lastError = reason
            }
        }
    }

    // MARK: - Pairing

    func startPairing() {
        lastError = nil
        statusMessage = "Contacting player at \(config.bdpIP):\(config.port)…"
        pairingPhase = .requesting
        Task {
            do {
                let result = try await client.startPairing()
                switch result {
                case .registered:
                    finishPairing(message: "Already registered — you're all set.")
                case .pinDisplayed:
                    pairingPhase = .awaitingPIN
                    statusMessage = "Check your TV — enter the PIN shown on screen."
                }
            } catch {
                pairingPhase = .idle
                lastError = error.localizedDescription
                statusMessage = nil
            }
        }
    }

    func submitPIN() {
        let pin = enteredPIN.trimmingCharacters(in: .whitespaces)
        guard !pin.isEmpty else { return }
        lastError = nil
        pairingPhase = .verifying
        statusMessage = "Verifying PIN…"
        Task {
            do {
                try await client.completePairing(pin: pin)
                finishPairing(message: "Paired with \(config.deviceName).")
            } catch {
                pairingPhase = .awaitingPIN
                lastError = error.localizedDescription
                statusMessage = nil
            }
        }
    }

    func resetPairing() {
        storedPaired = false
        pairingPhase = .idle
        enteredPIN = ""
        statusMessage = nil
        lastError = nil
    }

    private func finishPairing(message: String) {
        storedPaired = true
        pairingPhase = .paired
        statusMessage = message
        enteredPIN = ""
    }

    // MARK: - Commands

    /// For keys that exist on the physical RMT-B119A but have no reliable
    /// IRCC-over-IP equivalent (VOL drives the TV via IR; SEN's code is
    /// undocumented), so tapping them explains instead of failing silently.
    func noteUnsupported(_ label: String) {
        lastError = nil
        statusMessage = "\(label) isn't available over IP on the BDP-S5100."
    }

    func send(_ command: IRCCCommand) {
        lastCommand = command
        lastError = nil
        statusMessage = command.label
        Task {
            do {
                try await client.send(command)
            } catch {
                lastError = error.localizedDescription
            }
        }
    }
}
