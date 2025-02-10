import SwiftUI

@main
struct Day14App: App {

    @State var loader = EnvironmentLoader()

    static let previewSize = CGSize(width: 720, height: 405)
    static let mainWindowID = "MainWindow"

    enum ImmersiveSpaceSelection: String {
        case garden = "ImmersiveSpace_Garden"
        case myEnvironment = "ImmersiveSpace_MyEnvironment"
        case cornellBox = "ImmersiveSpace_CornellBox"
    }

    var body: some Scene {
        WindowGroup(id: Day14App.mainWindowID) {
            ContentView(loader: loader)
        }
        .windowStyle(.plain)
        .defaultSize(width: 2400, height: 640)

        ImmersiveSpace(id: ImmersiveSpaceSelection.garden.rawValue) {
            ImmersiveView_Garden(loader: loader)
        }
        .immersionStyle(selection: .constant(.full), in: .full)

        ImmersiveSpace(id: ImmersiveSpaceSelection.myEnvironment.rawValue) {
            ImmersiveView_MyEnvironment(loader: loader)
        }
        .immersionStyle(selection: .constant(.full), in: .full)

        ImmersiveSpace(id: ImmersiveSpaceSelection.cornellBox.rawValue) {
            ImmersiveView_Cornell(loader: loader)
        }
        .immersionStyle(selection: .constant(.full), in: .full)
     }
}
