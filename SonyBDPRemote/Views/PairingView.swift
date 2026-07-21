import SwiftUI

/// Initial pairing screen: one prominent button kicks off the CERS register
/// call, which makes the player display a PIN on the TV; the PIN is then
/// entered here to complete registration.
struct PairingView: View {
    @EnvironmentObject private var viewModel: RemoteViewModel
    @FocusState private var pinFieldFocused: Bool

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "opticaldisc.fill")
                .font(.system(size: 64))
                .foregroundStyle(Theme.accent)
                .shadow(color: Theme.accent.opacity(0.5), radius: 18)

            VStack(spacing: 6) {
                Text("Sony BDP-S5100")
                    .font(.title.bold())
                    .foregroundStyle(Theme.textPrimary)
                Text("\(viewModel.config.bdpIP):\(String(viewModel.config.port))")
                    .font(.subheadline.monospaced())
                    .foregroundStyle(Theme.textSecondary)
                Text("Config source: \(viewModel.config.source.rawValue)")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }

            switch viewModel.pairingPhase {
            case .idle, .requesting:
                pairButton
                testConnectionButton
            case .awaitingPIN, .verifying:
                pinEntry
            case .paired:
                EmptyView()
            }

            if let status = viewModel.statusMessage {
                Text(status)
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            if let error = viewModel.lastError {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(Theme.danger)
                    .multilineTextAlignment(.center)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private var pairButton: some View {
        Button(action: viewModel.startPairing) {
            HStack(spacing: 10) {
                if viewModel.pairingPhase == .requesting {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "link")
                }
                Text(viewModel.pairingPhase == .requesting ? "Pairing…" : "Start Pairing")
                    .fontWeight(.semibold)
            }
            .font(.title3)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.accent)
                    .shadow(color: Theme.accent.opacity(0.45), radius: 12, y: 5)
            )
        }
        .buttonStyle(PressedScaleStyle())
        .disabled(viewModel.pairingPhase == .requesting)
    }

    private var testConnectionButton: some View {
        Button(action: viewModel.testConnection) {
            HStack(spacing: 8) {
                if viewModel.isTestingConnection {
                    ProgressView().tint(Theme.textSecondary).scaleEffect(0.8)
                } else {
                    Image(systemName: "dot.radiowaves.left.and.right")
                }
                Text(viewModel.isTestingConnection ? "Testing…" : "Test Connection")
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Theme.textSecondary)
            .padding(.vertical, 10)
            .padding(.horizontal, 18)
            .background(
                Capsule().strokeBorder(Theme.textSecondary.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(PressedScaleStyle())
        .disabled(viewModel.isTestingConnection)
    }

    private var pinEntry: some View {
        VStack(spacing: 14) {
            Text("Enter the PIN shown on your TV")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)

            TextField("PIN", text: $viewModel.enteredPIN)
                .keyboardType(.numberPad)
                .focused($pinFieldFocused)
                .multilineTextAlignment(.center)
                .font(.system(size: 30, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.textPrimary)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14).fill(Theme.surface)
                )
                .onAppear { pinFieldFocused = true }

            Button(action: viewModel.submitPIN) {
                HStack(spacing: 10) {
                    if viewModel.pairingPhase == .verifying {
                        ProgressView().tint(.white)
                    }
                    Text(viewModel.pairingPhase == .verifying ? "Verifying…" : "Complete Pairing")
                        .fontWeight(.semibold)
                }
                .font(.title3)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 16).fill(Theme.accent))
            }
            .buttonStyle(PressedScaleStyle())
            .disabled(viewModel.enteredPIN.isEmpty || viewModel.pairingPhase == .verifying)
        }
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        PairingView().environmentObject(RemoteViewModel(config: .fallback))
    }
}
