import SwiftUI

@main
struct Day13App: App {

    @State private var player: PlayerModel = PlayerModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(player)
        }
     }
}
