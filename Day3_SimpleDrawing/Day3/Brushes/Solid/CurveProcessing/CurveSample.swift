import simd

struct CurveSample {

    var point: SolidBrushCurvePoint
    var parameter: Float
    var rotationFrame: simd_float3x3
    var curveDistance: Float

    var position: SIMD3<Float> {
        get { return point.position }
        set { point.position = newValue }
    }

    var tangent: SIMD3<Float> { rotationFrame.columns.2 }

    var radius: Float {
        get { return point.radius }
        set { point.radius = newValue }
    }

    init(point: SolidBrushCurvePoint, parameter: Float = 0, rotationFrame: simd_float3x3 = .init(diagonal: .one), curveDistance: Float = 0) {
        self.point = point
        self.parameter = parameter
        self.rotationFrame = rotationFrame
        self.curveDistance = curveDistance
    }
}
