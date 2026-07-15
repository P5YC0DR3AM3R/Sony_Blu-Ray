import SwiftUI

/// The main remote surface: utility row, D-pad, and media transport.
struct RemoteControlView: View {
    @EnvironmentObject private var viewModel: RemoteViewModel

    var body: some View {
        VStack(spacing: 26) {
            header
            utilityRow
            Spacer(minLength: 0)
            dPad
            Spacer(minLength: 0)
            mediaControls
            statusFooter
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    // MARK: Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("BDP-S5100")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text(viewModel.config.bdpIP)
                    .font(.caption.monospaced())
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Button {
                viewModel.resetPairing()
            } label: {
                Image(systemName: "link.badge.plus")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(8)
                    .background(Circle().fill(Theme.surface))
            }
            .accessibilityLabel("Re-pair")
        }
    }

    // MARK: Utility (Power, Home, Options, Return)

    private var utilityRow: some View {
        HStack(spacing: 22) {
            RemoteButton(systemImage: "power", label: "Power",
                         tint: Theme.danger, size: 52) {
                viewModel.send(.power)
            }
            RemoteButton(systemImage: "house.fill", label: "Home", size: 52) {
                viewModel.send(.home)
            }
            RemoteButton(systemImage: "slider.horizontal.3", label: "Options", size: 52) {
                viewModel.send(.options)
            }
            RemoteButton(systemImage: "arrow.uturn.backward", label: "Return", size: 52) {
                viewModel.send(.return)
            }
        }
    }

    // MARK: D-pad

    private var dPad: some View {
        ZStack {
            Circle()
                .fill(Theme.surface)
                .frame(width: 230, height: 230)
                .shadow(color: .black.opacity(0.6), radius: 14, y: 6)
                .overlay(Circle().strokeBorder(Color.white.opacity(0.06), lineWidth: 1))

            VStack {
                dPadArrow("chevron.up", label: "Up", command: .up)
                Spacer()
                dPadArrow("chevron.down", label: "Down", command: .down)
            }
            .frame(height: 214)

            HStack {
                dPadArrow("chevron.left", label: "Left", command: .left)
                Spacer()
                dPadArrow("chevron.right", label: "Right", command: .right)
            }
            .frame(width: 214)

            Button {
                viewModel.send(.confirm)
            } label: {
                Circle()
                    .fill(Theme.surfaceHighlight)
                    .frame(width: 86, height: 86)
                    .overlay(
                        Text("OK")
                            .font(.headline.bold())
                            .foregroundStyle(Theme.accent)
                    )
                    .overlay(Circle().strokeBorder(Theme.accent.opacity(0.35), lineWidth: 1.5))
                    .shadow(color: .black.opacity(0.5), radius: 6, y: 3)
            }
            .buttonStyle(PressedScaleStyle())
            .accessibilityLabel("Select")
        }
    }

    private func dPadArrow(_ systemImage: String, label: String,
                           command: IRCCCommand) -> some View {
        Button {
            viewModel.send(command)
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 56, height: 56)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressedScaleStyle())
        .accessibilityLabel(label)
    }

    // MARK: Media transport

    private var mediaControls: some View {
        VStack(spacing: 18) {
            HStack(spacing: 20) {
                RemoteButton(systemImage: "backward.end.fill", label: "Skip Back", size: 54) {
                    viewModel.send(.previous)
                }
                RemoteButton(systemImage: "play.fill", label: "Play",
                             tint: .black, size: 66, fill: Theme.accent) {
                    viewModel.send(.play)
                }
                RemoteButton(systemImage: "pause.fill", label: "Pause", size: 66) {
                    viewModel.send(.pause)
                }
                RemoteButton(systemImage: "forward.end.fill", label: "Skip Forward", size: 54) {
                    viewModel.send(.next)
                }
            }
            HStack(spacing: 20) {
                RemoteButton(systemImage: "backward.fill", label: "Rewind", size: 48) {
                    viewModel.send(.rewind)
                }
                RemoteButton(systemImage: "stop.fill", label: "Stop",
                             tint: Theme.danger, size: 54) {
                    viewModel.send(.stop)
                }
                RemoteButton(systemImage: "forward.fill", label: "Fast Forward", size: 48) {
                    viewModel.send(.forward)
                }
            }
        }
    }

    // MARK: Status footer

    private var statusFooter: some View {
        Group {
            if let error = viewModel.lastError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.danger)
            } else if let status = viewModel.statusMessage {
                Text(status)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            } else {
                Text(" ")
                    .font(.caption)
            }
        }
        .frame(height: 18)
        .lineLimit(1)
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        RemoteControlView().environmentObject(RemoteViewModel(config: .fallback))
    }
}
