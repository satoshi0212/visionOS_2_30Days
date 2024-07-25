import RealityKit
import SwiftUI

struct DrawingMeshView: View {

    @Environment(AppModel.self) private var appModel
    @State private var anchorEntityInput: AnchorEntityInputProvider?

    private let rootEntity = Entity()
    private let inputEntity = Entity()

    var body: some View {

        RealityView { content in
            SolidBrushSystem.registerSystem()
            SolidBrushComponent.registerComponent()

            rootEntity.position = .zero
            content.add(rootEntity)
            content.add(inputEntity)

            let drawingDocument = await DrawingDocument(brushSettings: appModel.brushSettigns, rootEntity: rootEntity)
            anchorEntityInput = await AnchorEntityInputProvider(rootEntity: inputEntity, document: drawingDocument)
        }
    }
}
