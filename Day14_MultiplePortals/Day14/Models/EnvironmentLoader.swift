import Foundation
import RealityKit
import RealityKitContent

actor EnvironmentLoader {

    private weak var entity_Garden: Entity?
    private weak var entity_MyEnvironment: Entity?
    private weak var entity_CornellBox: Entity?

    func getEntity_Garden() async throws -> Entity {
        if let entity = entity_Garden { return entity }
        let entity = try await Entity(named: "Garden", in: realityKitContentBundle)
        entity_Garden = entity
        return entity
    }

    func getEntity_MyEnvironment() async throws -> Entity {
        if let entity = entity_MyEnvironment { return entity }
        let entity = try await Entity(named: "Immersive", in: realityKitContentBundle)
        entity_MyEnvironment = entity
        return entity
    }

    func getEntity_CornellBox() async throws -> Entity {
        if let entity = entity_CornellBox { return entity }
        let assetRoot = try await Entity(named: "CornellBox.usda")
        guard let iblURL = Bundle.main.url(forResource: "TeapotIBL", withExtension: "exr") else { fatalError("Failed to load the Image-Based Lighting file.") }
        let iblEnv = try await EnvironmentResource(fromImage: iblURL)
        let iblEntity = await Entity()
        var iblComp = ImageBasedLightComponent(source: .single(iblEnv))
        iblComp.inheritsRotation = true
        await iblEntity.components.set(iblComp)
        await assetRoot.components.set(ImageBasedLightReceiverComponent(imageBasedLight: iblEntity))
        await assetRoot.addChild(iblEntity)
        return assetRoot
    }
}
