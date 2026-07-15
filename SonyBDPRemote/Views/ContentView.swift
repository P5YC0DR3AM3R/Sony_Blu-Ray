import SwiftUI

/// Root view: shows the pairing flow until the player is registered, then
/// the remote control surface.
struct ContentView: View {
    @EnvironmentObject private var viewModel: RemoteViewModel

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            if viewModel.isPaired {
                RemoteControlView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                PairingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.isPaired)
    }
}

#Preview {
    ContentView()
        .environmentObject(RemoteViewModel(config: .fallback))
}
