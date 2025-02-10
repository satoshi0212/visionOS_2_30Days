import SwiftUI
import RealityKit

struct ContentView: View {

    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    @Environment(\.dismissWindow) var dismissWindow

    var loader: EnvironmentLoader

    private let portalPlanes = [
        ModelEntity(mesh: .generatePlane(width: 1.0, height: 1.0), materials: [PortalMaterial()]),
        ModelEntity(mesh: .generatePlane(width: 1.0, height: 1.0), materials: [PortalMaterial()]),
        ModelEntity(mesh: .generatePlane(width: 1.0, height: 1.0), materials: [PortalMaterial()])
    ]

    var body: some View {
        HStack(spacing: 80) {
            portalView_Garden
            portalView_MyEnvironment
            portalView_CornellBox
        }
        .padding(80)
    }

    private var portalView_Garden: some View {
        ZStack {
            GeometryReader3D { geometry in
                RealityView { content in
                    let world = await makeWorldEntity(spaceType: .garden)
                    content.add(world)
                    let plane = getTargetPortalPlane(spaceType: .garden)
                    plane.components.set(PortalComponent(target: world))
                    content.add(plane)
                } update: { content in
                    let plane = getTargetPortalPlane(spaceType: .garden)
                    let size = content.convert(geometry.size, from: .local, to: .scene)
                    plane.model?.mesh = .generatePlane(width: size.x, height: size.y, cornerRadius: 0.03)
                }.frame(depth: 0.4)
            }.frame(depth: 0.4)

            VStack {
                Button("Enter") {
                    Task {
                        await openImmersiveSpace(id: Day14App.ImmersiveSpaceSelection.garden.rawValue)
                        dismissWindow()
                    }
                }.glassBackgroundEffect()
            }
        }
        .frame(width: Day14App.previewSize.width, height: Day14App.previewSize.height)
    }

    private var portalView_MyEnvironment: some View {
        ZStack {
            GeometryReader3D { geometry in
                RealityView { content in
                    let world = await makeWorldEntity(spaceType: .myEnvironment)
                    content.add(world)
                    let plane = getTargetPortalPlane(spaceType: .myEnvironment)
                    plane.components.set(PortalComponent(target: world))
                    content.add(plane)
                } update: { content in
                    let plane = getTargetPortalPlane(spaceType: .myEnvironment)
                    let size = content.convert(geometry.size, from: .local, to: .scene)
                    plane.model?.mesh = .generatePlane(width: size.x, height: size.y, cornerRadius: 0.03)
                }.frame(depth: 0.4)
            }.frame(depth: 0.4)

            VStack {
                Button("Enter") {
                    Task {
                        await openImmersiveSpace(id: Day14App.ImmersiveSpaceSelection.myEnvironment.rawValue)
                        dismissWindow()
                    }
                }.glassBackgroundEffect()
            }
        }
        .frame(width: Day14App.previewSize.width, height: Day14App.previewSize.height)
    }

    private var portalView_CornellBox: some View {
        ZStack {
            GeometryReader3D { geometry in
                RealityView { content in
                    let world = await makeWorldEntity(spaceType: .cornellBox)
                    content.add(world)
                    let plane = getTargetPortalPlane(spaceType: .cornellBox)
                    plane.components.set(PortalComponent(target: world))
                    content.add(plane)
                } update: { content in
                    let plane = getTargetPortalPlane(spaceType: .cornellBox)
                    let size = content.convert(geometry.size, from: .local, to: .scene)
                    plane.model?.mesh = .generatePlane(width: size.x, height: size.y, cornerRadius: 0.03)
                }.frame(depth: 0.4)
            }.frame(depth: 0.4)

            VStack {
                Button("Enter") {
                    Task {
                        await openImmersiveSpace(id: Day14App.ImmersiveSpaceSelection.cornellBox.rawValue)
                        dismissWindow()
                    }
                }.glassBackgroundEffect()
            }
        }
        .frame(width: Day14App.previewSize.width, height: Day14App.previewSize.height)
    }

    private func makeWorldEntity(spaceType: Day14App.ImmersiveSpaceSelection) async -> Entity {
        switch (spaceType) {
        case .garden:
            let world = Entity()
            world.components.set(WorldComponent())
            world.addChild(try! await loader.getEntity_Garden())
            let scale: Float = 0.2
            world.scale *= scale
            world.position.y -= scale * 1.5
            return world
        case .myEnvironment:
            let world = Entity()
            world.components.set(WorldComponent())
            world.addChild(try! await loader.getEntity_MyEnvironment())
            let scale: Float = 0.2
            world.scale *= scale
            world.position.y -= scale * 1.5
            return world
        case .cornellBox:
            let world = Entity()
            world.components.set(WorldComponent())
            world.scale *= 0.5
            world.position.y -= 0.5
            world.position.z -= 0.5
            world.addChild(try! await loader.getEntity_CornellBox())
            return world
        }
    }

    private func getTargetPortalPlane(spaceType: Day14App.ImmersiveSpaceSelection) -> ModelEntity {
        switch (spaceType) {
        case .garden:
            return portalPlanes[0]
        case .myEnvironment:
            return portalPlanes[1]
        case .cornellBox:
            return portalPlanes[2]
        }
    }
}
