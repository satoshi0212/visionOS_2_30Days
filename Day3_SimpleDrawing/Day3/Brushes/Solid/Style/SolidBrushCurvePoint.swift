import CoreGraphics

struct SolidBrushCurvePoint {

    var position: SIMD3<Float>
    var radius: Float
    var color: SIMD3<Float>
    var roughness: Float
    var metallic: Float

    init(position: SIMD3<Float>, radius: Float, color: SIMD3<Float>, roughness: Float, metallic: Float) {
        self.position = position
        self.radius = radius
        self.color = color
        self.roughness = roughness
        self.metallic = metallic
    }
}
