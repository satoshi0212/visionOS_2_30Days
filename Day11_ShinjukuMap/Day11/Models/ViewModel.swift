import Observation
import SwiftUI
import RealityKit

@Observable
class ViewModel {

    private let contentEntity = Entity()
    private let constants = Constants()
    private let decoder = JSONDecoder()

    func setupContentEntity() -> Entity {
        contentEntity.position = [0.0, -0.5, -1.0]
        return contentEntity
    }

    func makePolygon() {
        constants.spaceLists.forEach { fileName in
            makePolygon(fileName: fileName, color: .red)
        }

        constants.floorLists.forEach { fileName in
            makePolygon(fileName: fileName, color: .blue, zOffset: 0.02)
        }

        constants.fixtureLists.forEach { fileName in
            makePolygon(fileName: fileName, color: .yellow, zOffset: 0.03)
        }
    }

    private func getFloorNumber(_ geoJsonName: String) -> Int {
        let components = geoJsonName.split(separator: "_")
        guard components.count > 2 else { return 0 }
        let floorStr = String(components[1]).replacingOccurrences(of: "out", with: "")
        let sign = floorStr.hasPrefix("B") ? -1 : 1
        guard let floorNum = Int(floorStr.replacingOccurrences(of: "B", with: "")) else { return 0 }
        return floorNum * sign
    }

    private func makePolygon(fileName: String, color: UIColor, zOffset: Float = 0.0) {
        guard let fileUrl = Bundle.main.url(forResource: fileName, withExtension: "geojson") else { return }

        do {
            let jsonData = try Data(contentsOf: fileUrl)
            let geoJSON = try decoder.decode(GeoJSONFeatureCollection.self, from: jsonData)

            let floorHeightValue = getFloorNumber(geoJSON.name)
            var zOffsetInner: Float = 0.0

            geoJSON.features.forEach { feature in
                zOffsetInner -= 0.0001
                let coordinates = feature.geometry.coordinates

                coordinates.forEach { coordinate in
                    guard coordinate.count <= UInt8.max else { return }

                    var vertices: [SIMD3<Float>] = []
                    for point in coordinate {
                        guard point.count >= 2 else { continue }
                        let x = (Float(point[0]) - constants.center.x) / 200 + 2.0
                        let y = (Float(point[1]) - constants.center.y) / 200
                        let z = Float(floorHeightValue) / 5 * -1.0 + zOffset + zOffsetInner - 1.0
                        vertices.append(SIMD3<Float>(x, y, z))
                    }

                    let counts: [UInt8] = [UInt8(vertices.count)]
                    var indices: [UInt32] = []
                    for i in 0..<(vertices.count) {
                        indices.append(UInt32(i))
                    }

                    var meshDescriptor = MeshDescriptor()
                    meshDescriptor.positions = .init(vertices)
                    meshDescriptor.primitives = .polygons(counts, indices)

                    let polygon = try! MeshResource.generate(from: [meshDescriptor])
                    var material = UnlitMaterial(color: color.withAlphaComponent(0.5))
                    material.blending = .transparent(opacity: PhysicallyBasedMaterial.Opacity(floatLiteral: 1.0))

                    let modelEntity = ModelEntity(mesh: polygon, materials: [material])

                    let quatf = simd_quatf(angle: .pi / -2, axis: SIMD3(x: 1, y: 0, z: 0)) * simd_quatf(angle: .pi, axis: SIMD3(x: 0, y: 1, z: 0))
                    modelEntity.transform.rotation = quatf

                    contentEntity.addChild(modelEntity)
                }
            }
        } catch {
            print("Error loading GeoJSON: \(error)")
        }
    }
}

private struct Constants {

    let center: SIMD2<Float> = [-12035.29, -34261.85]

    let fgLists = [
        "fg",
    ]

    let spaceLists = [
        "ShinjukuTerminal_B3_Space",
        "ShinjukuTerminal_B2_Space",
        "ShinjukuTerminal_B1_Space",
        "ShinjukuTerminal_0_Space",
        "ShinjukuTerminal_1_Space",
        "ShinjukuTerminal_2_Space",
        "ShinjukuTerminal_2out_Space",
        "ShinjukuTerminal_3_Space",
        "ShinjukuTerminal_3out_Space",
        "ShinjukuTerminal_4_Space",
        "ShinjukuTerminal_4out_Space"
    ]

    let floorLists = [
        "ShinjukuTerminal_B3_Floor",
        "ShinjukuTerminal_B2_Floor",
        "ShinjukuTerminal_B1_Floor",
        "ShinjukuTerminal_0_Floor",
        "ShinjukuTerminal_1_Floor",
        "ShinjukuTerminal_2_Floor",
        "ShinjukuTerminal_2out_Floor",
        "ShinjukuTerminal_3_Floor",
        "ShinjukuTerminal_3out_Floor",
        "ShinjukuTerminal_4_Floor",
        "ShinjukuTerminal_4out_Floor"
    ]

    let fixtureLists = [
        "ShinjukuTerminal_B3_Fixture",
        "ShinjukuTerminal_B2_Fixture",
        "ShinjukuTerminal_B1_Fixture",
        "ShinjukuTerminal_0_Fixture",
        "ShinjukuTerminal_2_Fixture",
        "ShinjukuTerminal_2out_Fixture",
        "ShinjukuTerminal_3_Fixture",
        "ShinjukuTerminal_3out_Fixture",
        "ShinjukuTerminal_4_Fixture",
        "ShinjukuTerminal_4out_Fixture"
    ]
}

struct GeoJSONFeatureCollection: Codable {
    var type: String
    var name: String
    var features: [GeoJSONFeature]
}

struct GeoJSONFeature: Codable {
    var type: String
    var properties: GeoJSONProperties
    var geometry: GeoJSONCoordinate
}

struct GeoJSONProperties: Codable {
    var id: String
    var category: String
//    var source: String
}

struct GeoJSONCoordinate: Codable {
    var type: String
    var coordinates: [[[Double]]]
}
