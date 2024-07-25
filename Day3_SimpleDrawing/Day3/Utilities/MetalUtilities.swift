/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Utilities for interfacing with Metal.
*/

import Metal

/// A metal device to use throughout the app.
let metalDevice: MTLDevice? = MTLCreateSystemDefaultDevice()

/// Create a `MTLComputePipelineState` for a Metal compute kernel named `name`, using a default Metal device.
func makeComputePipeline(named name: String) -> MTLComputePipelineState? {
    if let metalDevice, let function = metalDevice.makeDefaultLibrary()?.makeFunction(name: name) {
        return try? metalDevice.makeComputePipelineState(function: function)
    } else {
        return nil
    }
}

extension MTLPackedFloat3 {
    /// Convert a `MTLPackedFloat3` to a `SIMD3<Float>`.
    var simd3: SIMD3<Float> { return .init(x, y, z) }
}

extension SIMD3 where Scalar == Float {
    /// Convert a `SIMD3<Float>` to a `MTLPackedFloat3`.
    var packed3: MTLPackedFloat3 { return .init(.init(elements: (x, y, z))) }
}

extension SIMD3 where Scalar == Float16 {
    /// Convert a `SIMD3<Float16>` to a `packed_half3`.
    var packed3: packed_half3 { return .init(x: x, y: y, z: z) }
}
