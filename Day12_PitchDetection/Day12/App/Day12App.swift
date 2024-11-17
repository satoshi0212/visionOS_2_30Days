import SwiftUI

@main
struct Day12App: App {

    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
        }
        .windowResizability(.contentSize)
     }
}
