import simd

extension float4x4 {

    var translation: SIMD3<Float> {
        columns.3.xyz
    }

    var forward: SIMD3<Float> {
        normalize([-columns.2.x, -columns.2.y, -columns.2.z])
    }

    var upward: SIMD3<Float> {
        normalize([columns.1.x, columns.1.y, columns.1.z])
    }

    var right: SIMD3<Float> {
        normalize([columns.0.x, columns.0.y, columns.0.z])
    }

    static var identity: float4x4 {
        matrix_identity_float4x4
    }

    init(translation: SIMD3<Float>) {
        self.init()
        columns = (SIMD4<Float>(1, 0, 0, 0),
                   SIMD4<Float>(0, 1, 0, 0),
                   SIMD4<Float>(0, 0, 1, 0),
                   SIMD4<Float>(translation, 1))
    }

}

extension SIMD3<Float> {

    static func distance(_ first: SIMD3<Float>, _ second: SIMD3<Float>) -> Float {
        (first - second).length()
    }

    static func dot(_ first: SIMD3<Float>, _ second: SIMD3<Float>) -> Float {
        first.x * second.x + first.y * second.y + first.z * second.z
    }

    static var upward: SIMD3<Float> {
        SIMD3<Float>(0, 1, 0)
    }

    static var down: SIMD3<Float> {
        SIMD3<Float>(0, -1, 0)
    }

    static var left: SIMD3<Float> {
        SIMD3<Float>(1, 0, 0)
    }

    static var right: SIMD3<Float> {
        SIMD3<Float>(-1, 0, 0)
    }

    static var forward: SIMD3<Float> {
        SIMD3<Float>(0, 0, 1)
    }

    static var back: SIMD3<Float> {
        SIMD3<Float>(0, 0, -1)
    }

    init(_ float4: SIMD4<Float>) {
        self.init()

        x = float4.x
        y = float4.y
        z = float4.z
    }

    func length() -> Float {
        sqrt(x * x + y * y + z * z)
    }

    func normalized() -> SIMD3<Float> {
        self * 1 / length()
    }

    func setX(_ value: Float) -> SIMD3<Float> {
        SIMD3<Float>(value, y, z)
    }

    func setY(_ value: Float) -> SIMD3<Float> {
        SIMD3<Float>(x, value, z)
    }

    func setZ(_ value: Float) -> SIMD3<Float> {
        SIMD3<Float>(x, y, value)
    }
}

extension SIMD4<Float> {
    var xyz: SIMD3<Float> {
        [x, y, z]
    }
}
