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
