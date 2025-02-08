import SwiftUI

struct ContentView: View {

    @Environment(PlayerModel.self) private var player

    init () {
        AssetPersistenceManager.shared.restorePersistenceManager()
    }

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(AssetListManager.shared.assets) { asset in
                    NavigationLink {
                        if let localUrlAsset = asset.localFileUrlAsset {
                            let video = Video(name: asset.stream.name, url: localUrlAsset.url)
                            AssetDetailView(video: video)
                                .environment(player)
                        } else {
                            Text("Select a downloaded asset")
                        }
                    } label: {
                        AssetRowView(asset: asset) {
                            Task {
                                do { try await AssetPersistenceManager.shared.downloadStream(for: asset) } catch { print(error) }
                            }
                        } onClear: {
                            AssetPersistenceManager.shared.deleteAsset(asset)
                        }
                    }
                }
                .listRowInsets(EdgeInsets())
            }
            .navigationSplitViewColumnWidth(400)
            .listStyle(.inset)
            .padding()
            .navigationTitle("Assets")

        } detail: {
            Text("Select a downloaded asset")
        }
    }
}
