import RealityKit

@MainActor
final class ImmersiveViewModel {

    let rootEntity = Entity()

    func getTargetEntity(name: String) -> Entity? {
        return rootEntity.children.first { $0.name == name}
    }

    func setupRootEntity() async {
        do {
            let portal = try await Entity.makePortal()
            portal.position = [0.0, 1.5, -3.0]
            rootEntity.addChild(portal)

            try await addOccluder(targetEntity: portal)
        } catch {
            print(error)
        }
    }

    private func addOccluder(targetEntity: Entity) async throws {
        let pos = targetEntity.position

        let leftWall = ModelEntity(
            mesh: .generateBox(width: AppModel.portalWidth / 2, height: AppModel.portalHeight, depth: 0.1),
            materials: [OcclusionMaterial()]
            //materials: [SimpleMaterial(color: SimpleMaterial.Color.blue, isMetallic: false)]
        )
        leftWall.position = [pos.x - 1, pos.y, pos.z + 0.01]
        leftWall.name = "leftWall"
        rootEntity.addChild(leftWall)

        let rightWall = ModelEntity(
            mesh: .generateBox(width: AppModel.portalWidth / 2, height: AppModel.portalHeight, depth: 0.1),
            materials: [OcclusionMaterial()]
            //materials: [SimpleMaterial(color: SimpleMaterial.Color.red, isMetallic: false)]
        )
        rightWall.position = [pos.x + 1, pos.y, pos.z + 0.01]
        rightWall.name = "rightWall"
        rootEntity.addChild(rightWall)
    }

    func playAnimation() {
        guard let portal = getTargetEntity(name: "portal"),
              let world = portal.children.first(where: { $0.name == "world" }),
              let text = world.children.first(where: { $0.name == "text" }),
              let leftWall = getTargetEntity(name: "leftWall"),
              let rightWall = getTargetEntity(name: "rightWall")
        else {
            return
        }

        let duration = 6.0

        // Left wall
        let leftWallPosOrigin = leftWall.transform.translation

        let leftWallOpen = FromToByAnimation(
            name: "leftWallOpen",
            //to: Transform(translation: [leftWallPosOrigin.x - 3.0, leftWallPosOrigin.y, leftWallPosOrigin.z]),
            to: Transform(translation: [leftWallPosOrigin.x - AppModel.portalWidth / 2, leftWallPosOrigin.y, leftWallPosOrigin.z]),
            duration: duration,
            timing: .linear,
            bindTarget: .transform,
            delay: 1.0
        )

        let leftWallPause = FromToByAnimation(
            name: "leftWallPause",
            from: Transform(translation: [leftWallPosOrigin.x - AppModel.portalWidth / 2, leftWallPosOrigin.y, leftWallPosOrigin.z]),
            to: Transform(translation: [leftWallPosOrigin.x - AppModel.portalWidth / 2, leftWallPosOrigin.y, leftWallPosOrigin.z]),
            duration: duration,
            timing: .linear,
            bindTarget: .transform
        )

        let leftWallClose = FromToByAnimation(
            name: "leftWallClose",
            from: Transform(translation: [leftWallPosOrigin.x - AppModel.portalWidth / 2, leftWallPosOrigin.y, leftWallPosOrigin.z]),
            to: Transform(translation: leftWallPosOrigin),
            duration: duration,
            timing: .linear,
            bindTarget: .transform
        )

        // Right wall
        let rightWallPosOrigin = rightWall.transform.translation

        let rightWallOpen = FromToByAnimation(
            name: "rightWallOpen",
            to: Transform(translation: [rightWallPosOrigin.x + AppModel.portalWidth / 2, rightWallPosOrigin.y, rightWallPosOrigin.z]),
            duration: duration,
            timing: .linear,
            bindTarget: .transform,
            delay: 1.0
        )

        let rightWallPause = FromToByAnimation(
            name: "rightWallClose",
            from: Transform(translation: [rightWallPosOrigin.x + AppModel.portalWidth / 2, rightWallPosOrigin.y, rightWallPosOrigin.z]),
            to: Transform(translation: [rightWallPosOrigin.x + AppModel.portalWidth / 2, rightWallPosOrigin.y, rightWallPosOrigin.z]),
            duration: duration,
            timing: .linear,
            bindTarget: .transform
        )

        let rightWallClose = FromToByAnimation(
            name: "rightWallClose",
            from: Transform(translation: [rightWallPosOrigin.x + AppModel.portalWidth / 2, rightWallPosOrigin.y, rightWallPosOrigin.z]),
            to: Transform(translation: rightWallPosOrigin),
            duration: duration,
            timing: .linear,
            bindTarget: .transform
        )

        // Text
        let textPosOrigin = text.transform.translation
        let textMove = FromToByAnimation(
            name: "textMove",
            to: Transform(translation: [textPosOrigin.x, textPosOrigin.y, textPosOrigin.z + 4.0]),
            duration: duration,
            timing: .easeInOut,
            bindTarget: .transform,
            delay: 4.0
        )

        let leftWallOpenAnimation = try! AnimationResource.generate(with: leftWallOpen)
        let leftWallPauseAnimation = try! AnimationResource.generate(with: leftWallPause)
        let leftWallCloseAnimation = try! AnimationResource.generate(with: leftWallClose)
        let rightWallOpenAnimation = try! AnimationResource.generate(with: rightWallOpen)
        let rightWallPauseAnimation = try! AnimationResource.generate(with: rightWallPause)
        let rightWallCloseAnimation = try! AnimationResource.generate(with: rightWallClose)
        let textMoveAnimation = try! AnimationResource.generate(with: textMove)

        let leftWallAnimation = try! AnimationResource.sequence(with: [leftWallOpenAnimation, leftWallPauseAnimation, leftWallCloseAnimation])
        leftWall.playAnimation(leftWallAnimation)

        let rightWallAnimation = try! AnimationResource.sequence(with: [rightWallOpenAnimation, rightWallPauseAnimation, rightWallCloseAnimation])
        rightWall.playAnimation(rightWallAnimation)

        let textAnimation = try! AnimationResource.sequence(with: [textMoveAnimation])
        text.playAnimation(textAnimation)
    }
}
