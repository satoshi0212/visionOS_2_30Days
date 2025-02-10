import SwiftUI
import RealityKit

struct ImmersiveView_Garden: View {

    @Environment(\.openWindow) var openWindow

    var loader: EnvironmentLoader

    var body: some View {
        RealityView { content in
            content.add(try! await loader.getEntity_Garden())
        }
        .onDisappear {
            openWindow(id: Day14App.mainWindowID)
        }
    }
}

struct ImmersiveView_MyEnvironment: View {

    @Environment(\.openWindow) var openWindow

    var loader: EnvironmentLoader

    var body: some View {
        RealityView { content in
            content.add(try! await loader.getEntity_MyEnvironment())
        }
        .onDisappear {
            openWindow(id: Day14App.mainWindowID)
        }
    }
}

struct ImmersiveView_Cornell: View {

    @Environment(\.openWindow) var openWindow

    var loader: EnvironmentLoader

    var body: some View {
        RealityView { content in
            content.add(try! await loader.getEntity_CornellBox())
        }
        .onDisappear {
            openWindow(id: Day14App.mainWindowID)
        }
    }
}
