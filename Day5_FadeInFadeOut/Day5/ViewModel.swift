import SwiftUI
import RealityKit
import Observation

@Observable
class ViewModel {

    var rootEntity = Entity()
    private var skyBoxEntity: Entity?

    var skyboxColor: SIMD3<Float> = [0.0, 0.0, 0.0]

    func setup() {
        let entity = Entity()
        entity.components.set(ModelComponent(
            mesh: .generateSphere(radius: 1000),
            materials: [UnlitMaterial(color: .black)]
        ))
        entity.scale *= .init(x: -1, y: 1, z: 1)
        entity.components[OpacityComponent.self] = .init(opacity: 0)
        rootEntity.addChild(entity)
        skyBoxEntity = entity
    }

    func setSkyboxColor(color: UIColor) {
        guard let skyBoxEntity,
              var modelComponent = skyBoxEntity.components[ModelComponent.self]
        else { return }
        modelComponent.materials = [UnlitMaterial(color: color)]
        skyBoxEntity.components.set(modelComponent)
    }

    func fadeIn(animated: Bool, duration: TimeInterval = 2.0) {
        Task {
            await skyBoxEntity?.setOpacity(1.0, animated: animated, duration: duration, completion: {
                print("done: fadeIn")
            })
        }
    }

    func fadeOut(animated: Bool, duration: TimeInterval = 2.0) {
        Task {
            await skyBoxEntity?.setOpacity(0.0, animated: animated, duration: duration, completion: {
                print("done: fadeOut")
            })
        }
    }
}

extension Color {
    static func makeBinding(from simdBinding: Binding<SIMD3<Float>>) -> Binding<Color> {
        return Binding<Color>(get: { simdBinding.wrappedValue.toColor() },
                              set: { simdBinding.wrappedValue = $0.toSIMD() })
    }

    func toSIMD(in environment: EnvironmentValues = EnvironmentValues()) -> SIMD3<Float> {
        let resolved = resolve(in: environment)
        return .init(x: resolved.red, y: resolved.green, z: resolved.blue)
    }
}

extension SIMD3<Float> {
    func toColor() -> Color {
        Color(red: Double(x), green: Double(y), blue: Double(z))
    }

    func toUIColor() -> UIColor {
        UIColor(red: CGFloat(x), green: CGFloat(y), blue: CGFloat(z),alpha: 1.0)
    }
}
