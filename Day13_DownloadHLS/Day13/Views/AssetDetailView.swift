import SwiftUI

struct AssetDetailView: View {

    @Environment(PlayerModel.self) private var player

    let video: Video

    var body: some View {
        PlayerView()
            .onAppear {
                player.loadVideo(video)
            }
            .onChange(of: video, { _, newValue in
                player.loadVideo(newValue)
            })
            .navigationTitle(video.name)
            .navigationBarTitleDisplayMode(.inline)
            .padding()
    }
}
