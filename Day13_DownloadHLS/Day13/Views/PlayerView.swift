import AVKit
import SwiftUI

struct PlayerView: View {
    
    @Environment(PlayerModel.self) private var player

    var body: some View {
        ZStack {
            VideoContentView()
                .environment(player)
            InlineControlsView()
                .environment(player)
        }
        .padding()
        .onAppear {
            player.play()
        }
        .onDisappear {
            player.reset()
        }
    }
}

private struct VideoContentView: UIViewControllerRepresentable {

    @Environment(PlayerModel.self) private var player

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = player.makePlayerUI()
        controller.showsPlaybackControls = false
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}

private struct InlineControlsView: View {

    @Environment(PlayerModel.self) private var player
    @State private var isShowingControls = false

    var body: some View {
        VStack {
            Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                .padding(8)
                .background(.thinMaterial)
                .clipShape(.circle)
                .opacity(isShowingControls ? 1 : 0)
        }
        .font(.largeTitle)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            player.togglePlayback()
            isShowingControls = true

            // dismissAfterDelay
            Task { @MainActor in
                try! await Task.sleep(for: .seconds(2.0))
                if player.isPlaying {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isShowingControls = false
                    }
                }
            }
        }
    }
}
