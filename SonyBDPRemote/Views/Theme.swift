import SwiftUI

/// Shared dark-theme palette and reusable button styles for the remote UI.
enum Theme {
    static let background = LinearGradient(
        colors: [Color(red: 0.07, green: 0.08, blue: 0.10),
                 Color(red: 0.02, green: 0.02, blue: 0.04)],
        startPoint: .top, endPoint: .bottom
    )
    static let surface = Color(red: 0.13, green: 0.14, blue: 0.17)
    static let surfaceHighlight = Color(red: 0.19, green: 0.20, blue: 0.24)
    static let accent = Color(red: 0.25, green: 0.62, blue: 1.0)
    static let danger = Color(red: 0.95, green: 0.30, blue: 0.28)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.55)
}

/// A circular, tactile remote button used across the D-pad, media, and
/// utility clusters.
struct RemoteButton: View {
    let systemImage: String
    let label: String
    var tint: Color = Theme.textPrimary
    var size: CGFloat = 58
    var fill: Color = Theme.surface
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.34, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(fill)
                        .shadow(color: .black.opacity(0.55), radius: 6, y: 3)
                )
                .overlay(
                    Circle().strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
                )
        }
        .buttonStyle(PressedScaleStyle())
        .accessibilityLabel(label)
    }
}

/// Scales the button down slightly while pressed for a physical feel.
struct PressedScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.90 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6),
                       value: configuration.isPressed)
    }
}
