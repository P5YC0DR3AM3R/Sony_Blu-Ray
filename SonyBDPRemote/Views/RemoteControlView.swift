import SwiftUI

/// The main remote surface, laid out to mirror Sony's physical RMT-B119A
/// remote that ships with the BDP-S5100. Top to bottom: eject + power,
/// number pad with volume rocker, AUDIO/SUBTITLE/DISPLAY, color keys,
/// TOP MENU / POP UP-MENU, D-pad ring flanked by RETURN and OPTIONS,
/// the HOME pill, and the media transport cluster ending in
/// NETFLIX / STOP / SEN.
struct RemoteControlView: View {
    @EnvironmentObject private var viewModel: RemoteViewModel
    @State private var showingResetConfirmation = false

    // RMT-B119A palette
    private let bodyColor = Color(red: 0.09, green: 0.09, blue: 0.10)
    private let keyColor = Color(red: 0.17, green: 0.17, blue: 0.19)
    private let powerGreen = Color(red: 0.36, green: 0.67, blue: 0.45)
    private let keyYellow = Color(red: 0.91, green: 0.78, blue: 0.36)
    private let keyBlue = Color(red: 0.62, green: 0.68, blue: 0.88)
    private let keyRed = Color(red: 0.83, green: 0.22, blue: 0.20)
    private let keyGreen = Color(red: 0.33, green: 0.64, blue: 0.44)
    private let homeBlue = Color(red: 0.56, green: 0.63, blue: 0.87)

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    topRow
                    numberPadWithVolume
                    audioRow
                    colorKeyRow
                    discMenuRow
                    dPadCluster
                    homePill
                    transportCluster
                    Text("RMT-B119A")
                        .font(.caption2.bold())
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 26)
                        .fill(bodyColor)
                        .shadow(color: .black.opacity(0.6), radius: 14, y: 6)
                )
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
            statusFooter
        }
    }

    // MARK: Header (connection info + re-pair, kept slim above the remote body)

    private var header: some View {
        HStack {
            Text("BDP-S5100 · \(viewModel.config.bdpIP)")
                .font(.caption.monospaced())
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            Button {
                showingResetConfirmation = true
            } label: {
                Image(systemName: "link.badge.plus")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(6)
                    .background(Circle().fill(Theme.surface))
            }
            .accessibilityLabel("Re-pair")
            .confirmationDialog("Are you sure you want to reset pairing?",
                                isPresented: $showingResetConfirmation,
                                titleVisibility: .visible) {
                Button("Reset Pairing", role: .destructive) {
                    viewModel.resetPairing()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
    }

    // MARK: Top row — OPEN/CLOSE and green power

    private var topRow: some View {
        HStack(alignment: .top) {
            labeledKey("OPEN/\nCLOSE") {
                key(icon: "eject.fill", label: "Eject", width: 74) {
                    viewModel.send(.eject)
                }
            }
            Spacer()
            labeledKey("\u{2160}/\u{23FB}") {
                Button {
                    viewModel.send(.power)
                } label: {
                    Circle()
                        .fill(powerGreen)
                        .frame(width: 58, height: 58)
                        .overlay(
                            Image(systemName: "power")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.black.opacity(0.7))
                        )
                        .shadow(color: .black.opacity(0.5), radius: 5, y: 3)
                }
                .buttonStyle(PressedScaleStyle())
                .accessibilityLabel("Power")
            }
        }
    }

    // MARK: Number pad + VOL rocker

    private var numberPadWithVolume: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(spacing: 12) {
                numberRow([.num1, .num2, .num3])
                numberRow([.num4, .num5, .num6])
                numberRow([.num7, .num8, .num9])
            }
            VStack(spacing: 4) {
                Text("VOL")
                    .font(.caption.bold())
                    .foregroundStyle(Theme.textPrimary)
                VStack(spacing: 2) {
                    volumeKey("plus", label: "Volume Up")
                    volumeKey("minus", label: "Volume Down")
                }
            }
        }
    }

    private func numberRow(_ commands: [IRCCCommand]) -> some View {
        HStack(spacing: 12) {
            ForEach(commands) { command in
                key(text: command.label, label: command.label, width: 62) {
                    viewModel.send(command)
                }
            }
        }
    }

    private func volumeKey(_ symbol: String, label: String) -> some View {
        Button {
            viewModel.noteUnsupported(label)
        } label: {
            RoundedRectangle(cornerRadius: 8)
                .fill(keyColor)
                .frame(width: 60, height: 62)
                .overlay(
                    Image(systemName: symbol)
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundStyle(Theme.textPrimary)
                )
        }
        .buttonStyle(PressedScaleStyle())
        .accessibilityLabel(label)
    }

    // MARK: AUDIO · 0 · SUBTITLE · DISPLAY

    private var audioRow: some View {
        HStack(alignment: .bottom, spacing: 12) {
            labeledKey("AUDIO") {
                key(text: "", label: "Audio", width: 70) { viewModel.send(.audio) }
            }
            key(text: "0", label: "0", width: 62) { viewModel.send(.num0) }
            labeledKey("SUBTITLE") {
                key(text: "", label: "Subtitle", width: 78) { viewModel.send(.subtitle) }
            }
            labeledKey("DISPLAY") {
                key(text: "", label: "Display", width: 74) { viewModel.send(.display) }
            }
        }
    }

    // MARK: Color keys

    private var colorKeyRow: some View {
        HStack(spacing: 14) {
            colorKey("YELLOW", keyYellow, .yellow)
            colorKey("BLUE", keyBlue, .blue)
            colorKey("RED", keyRed, .red)
            colorKey("GREEN", keyGreen, .green)
        }
    }

    private func colorKey(_ title: String, _ color: Color,
                          _ command: IRCCCommand) -> some View {
        labeledKey(title) {
            Button {
                viewModel.send(command)
            } label: {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color)
                    .frame(height: 26)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PressedScaleStyle())
            .accessibilityLabel(command.label)
        }
    }

    // MARK: TOP MENU / POP UP·MENU

    private var discMenuRow: some View {
        HStack {
            labeledKey("TOP MENU") {
                roundKey(label: "Top Menu") { viewModel.send(.topMenu) }
            }
            Spacer()
            labeledKey("POP UP/ MENU") {
                roundKey(label: "Pop-Up Menu") { viewModel.send(.popUpMenu) }
            }
        }
    }

    // MARK: D-pad ring with RETURN and OPTIONS

    private var dPadCluster: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(keyColor)
                    .frame(width: 216, height: 216)
                    .shadow(color: .black.opacity(0.55), radius: 10, y: 5)
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.06), lineWidth: 1))

                VStack {
                    dPadArrow("arrowtriangle.up.fill", label: "Up", command: .up)
                    Spacer()
                    dPadArrow("arrowtriangle.down.fill", label: "Down", command: .down)
                }
                .frame(height: 202)

                HStack {
                    dPadArrow("arrowtriangle.left.fill", label: "Left", command: .left)
                    Spacer()
                    dPadArrow("arrowtriangle.right.fill", label: "Right", command: .right)
                }
                .frame(width: 202)

                Button {
                    viewModel.send(.confirm)
                } label: {
                    Circle()
                        .fill(bodyColor)
                        .frame(width: 78, height: 78)
                        .overlay(
                            Image(systemName: "plus.viewfinder")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                        )
                        .overlay(Circle().strokeBorder(Color.white.opacity(0.15), lineWidth: 1))
                }
                .buttonStyle(PressedScaleStyle())
                .accessibilityLabel("Select")
            }
            HStack {
                labeledKey("RETURN") {
                    roundKey(label: "Return") { viewModel.send(.return) }
                }
                Spacer()
                labeledKey("OPTIONS") {
                    roundKey(label: "Options") { viewModel.send(.options) }
                }
            }
            .padding(.top, -34)
        }
    }

    private func dPadArrow(_ systemImage: String, label: String,
                           command: IRCCCommand) -> some View {
        Button {
            viewModel.send(command)
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 56, height: 52)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressedScaleStyle())
        .accessibilityLabel(label)
    }

    // MARK: HOME pill

    private var homePill: some View {
        Button {
            viewModel.send(.home)
        } label: {
            Capsule()
                .fill(homeBlue)
                .frame(width: 170, height: 42)
                .overlay(
                    Text("HOME")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                )
                .shadow(color: .black.opacity(0.45), radius: 5, y: 3)
        }
        .buttonStyle(PressedScaleStyle())
        .accessibilityLabel("Home")
    }

    // MARK: Transport — PREV/PAUSE/NEXT, REW/PLAY/FF, NETFLIX/STOP/SEN

    private var transportCluster: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                labeledKey("PREV") {
                    key(icon: "backward.end.alt.fill", label: "Skip Back", width: 88) {
                        viewModel.send(.previous)
                    }
                }
                labeledKey("PAUSE") {
                    key(icon: "pause.fill", label: "Pause", width: 88) {
                        viewModel.send(.pause)
                    }
                }
                labeledKey("NEXT") {
                    key(icon: "forward.end.alt.fill", label: "Skip Forward", width: 88) {
                        viewModel.send(.next)
                    }
                }
            }
            HStack(alignment: .bottom, spacing: 14) {
                key(icon: "backward.fill", label: "Rewind", width: 88) {
                    viewModel.send(.rewind)
                }
                labeledKey("PLAY") {
                    key(icon: "play.fill", label: "Play", width: 88) {
                        viewModel.send(.play)
                    }
                }
                key(icon: "forward.fill", label: "Fast Forward", width: 88) {
                    viewModel.send(.forward)
                }
            }
            HStack(alignment: .bottom, spacing: 14) {
                Button {
                    viewModel.send(.netflix)
                } label: {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(keyRed)
                        .frame(width: 88, height: 42)
                        .overlay(
                            Text("NETFLIX")
                                .font(.system(size: 13, weight: .heavy))
                                .foregroundStyle(.white)
                        )
                }
                .buttonStyle(PressedScaleStyle())
                .accessibilityLabel("Netflix")

                labeledKey("STOP") {
                    key(icon: "stop.fill", label: "Stop", width: 88) {
                        viewModel.send(.stop)
                    }
                }

                Button {
                    viewModel.noteUnsupported("SEN")
                } label: {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(homeBlue)
                        .frame(width: 88, height: 42)
                        .overlay(
                            Text("SEN")
                                .font(.system(size: 14, weight: .heavy))
                                .foregroundStyle(.white)
                        )
                }
                .buttonStyle(PressedScaleStyle())
                .accessibilityLabel("Sony Entertainment Network")
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
        .padding(.bottom, 6)
    }

    // MARK: Shared key builders

    /// A dark rounded-rectangle key showing either a short text or an SF
    /// Symbol, matching the physical remote's rubber keys.
    private func key(text: String = "", icon: String? = nil, label: String,
                     width: CGFloat, height: CGFloat = 42,
                     action: @escaping () -> Void) -> some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: 10)
                .fill(keyColor)
                .frame(width: width, height: height)
                .overlay(
                    Group {
                        if let icon {
                            Image(systemName: icon)
                                .font(.system(size: 16, weight: .bold))
                        } else {
                            Text(text)
                                .font(.system(size: 19, weight: .bold))
                        }
                    }
                    .foregroundStyle(Theme.textPrimary)
                )
                .shadow(color: .black.opacity(0.4), radius: 3, y: 2)
        }
        .buttonStyle(PressedScaleStyle())
        .accessibilityLabel(label)
    }

    /// A round black key (TOP MENU, POP UP/MENU, RETURN, OPTIONS).
    private func roundKey(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Circle()
                .fill(keyColor)
                .frame(width: 50, height: 50)
                .shadow(color: .black.opacity(0.4), radius: 3, y: 2)
                .overlay(Circle().strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
        }
        .buttonStyle(PressedScaleStyle())
        .accessibilityLabel(label)
    }

    /// Places the printed caption above a key, like the silkscreen labels on
    /// the physical remote.
    private func labeledKey<Content: View>(_ title: String,
                                           @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            content()
        }
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        RemoteControlView().environmentObject(RemoteViewModel(config: .fallback))
    }
}
