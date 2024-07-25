/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Various math functions to supplement built-in math.
*/

import Foundation
import simd
import SwiftUI

extension SIMD4 {
    /// Extract the X, Y, and Z components of a SIMD4 as a SIMD3.
    var xyz: SIMD3<Scalar> { .init(x, y, z) }
}

extension SIMD3<Float> {
    /// Reinterpret a vectors X, Y, and Z components as red, green, and blue components of SwiftUI Color, respectively.
    func toColor() -> Color {
        Color(red: Double(x), green: Double(y), blue: Double(z))
    }
}

extension Color {
    /// Converts a vector binding into a color binding.  The X, Y, and Z components of the vector correspond with the
    /// red, green and blue channels of the color, respectively.
    static func makeBinding(from simdBinding: Binding<SIMD3<Float>>) -> Binding<Color> {
        return Binding<Color>(get: { simdBinding.wrappedValue.toColor() },
                              set: { simdBinding.wrappedValue = $0.toSIMD() })
    }
    
    /// Converts a SwiftUI Color to a vector, such that red, green, and blue maps to X, Y, and Z, respectively.
    func toSIMD(in environment: EnvironmentValues = EnvironmentValues()) -> SIMD3<Float> {
        let resolved = resolve(in: environment)
        return .init(x: resolved.red, y: resolved.green, z: resolved.blue)
    }
}

/// Returns true if `value0` and `value1` are equal within the tolerance `epsilon`.
func approximatelyEqual(_ value0: Float, _ value1: Float, epsilon: Float = 0.000_001) -> Bool {
    return abs(value0 - value1) <= epsilon
}

/// Returns true if `point0` and `point1` are equal within the tolerance `epsilon`.
func approximatelyEqual(_ point0: SIMD3<Float>, _ point1: SIMD3<Float>, epsilon: Float = 0.000_001) -> Bool {
    return distance(point0, point1) <= epsilon
}

/// Returns a rotation matrix that maps the vector `[0, 0, 1]` to `forward`.
///
/// The matrix is guaranteed to be ortho-normal (so, all columns are unit length and orthogonal).
///
/// - Parameters:
///   - forward: The returned matrix will map `[0, 0, 1]` to this value.  Behavior is undefined if this is `[0, 0, 0]`.
///   - desiredUp: The returned matrix is chosen such that it maps `[0, 1, 0]` to `desiredUp` as closely as
///         possible. Note that if `forward` and `desiredUp` are not perpendicular, the actual mapping may differ.
func orthonormalFrame(forward: SIMD3<Float> = [0, 0, 1], up desiredUp: SIMD3<Float> = [0, 1, 0]) -> simd_float3x3 {
    assert(all(isnan(forward) .== 0), "forward vector contains NaN")
    assert(all(isnan(desiredUp) .== 0), "up vector contains NaN")
    
    // Detect if either of the input values contains zero, and fall back to cardinal directions if so.
    let desiredUp = approximatelyEqual(desiredUp, .zero) ? [0, 1, 0] : desiredUp
    let forward = approximatelyEqual(forward, .zero) ? [0, 0, 1] : forward
    
    // Normalize `forward`.
    let forwardLen = length(forward)
    let forwardNorm = forward / forwardLen
    
    // Attempt to find a vector perpendicular to both forwardNorm and `desiredUp`.
    var right = cross(forwardNorm, desiredUp)
    
    // Determine if `right` has zero length. This happens when `forward` and `desiredUp` are parallel/antiparallel.
    var rightLength = length(right)
    if rightLength < 0.01 {
        right = cross(forwardNorm, SIMD3<Float>(0, 0, 1))
        rightLength = length(right)
    }
    
    // If `right` still has zero length then `forward` is parallel to `desiredUp` and `[0, 0, 1]`.
    if rightLength < 0.01 {
        right = cross(forwardNorm, SIMD3<Float>(1, 0, 0))
        rightLength = length(right)
    }
    
    // It is guaranteed mathematically that `right` has nonzero length at this point.
    right /= rightLength
    
    // Compute the final up vector as perpendicular to `right` and `forward`.
    // Guaranteed to be normalized as `right` and `forwardNorm` are both normalized and orthogonal.
    let finalUp = cross(right, forwardNorm)
    return simd_float3x3(columns: (-right, finalUp, forwardNorm))
}

/// Creates a 2D circle polyline centered at the origin. Points are listed in counter-clockwise order.
///
/// - Parameters:
///   - radius: Radius of the circle.
///   - segmentCount: The number of segments to use for the circle.
func makeCircle(radius: Float, segmentCount: Int) -> [SIMD2<Float>] {
    var circle: [SIMD2<Float>] = []
    circle.reserveCapacity(segmentCount)
    
    for segmentIndex in 0..<segmentCount {
        let radians = 2 * Float.pi * (Float(segmentIndex) / Float(segmentCount))
        circle.append(SIMD2<Float>(cos(radians), sin(radians)) * radius)
    }
    
    return circle
}

/// Returns a uniformly random direction, in other words a random point on a sphere with radius 1.
func randomDirection() -> SIMD3<Float> {
    // Use rejection sampling to guarantee a uniform probability over all directions.
    while true {
        let randomVector = SIMD3<Float>(Float.random(in: -1...1), Float.random(in: -1...1), Float.random(in: -1...1))
        let randomVectorLength = length(randomVector)
        if randomVectorLength > 1e-8 && randomVectorLength < 1 {
            return randomVector / randomVectorLength
        }
    }
}

/// Linearly interpolates between `value0` and `value1` based on the parameter `parameter`.
///
/// `parameter = 0` corresponds with `value0` and `parameter = 1` corresponds with `value1`.
func mix(_ value0: Float, _ value1: Float, t parameter: Float) -> Float {
    return value0 + (value1 - value0) * parameter
}

/// Clamps `value` to be at least `min` and at most `max`.
func clamp(_ value: Float, min: Float, max: Float) -> Float {
    return Float.minimum(Float.maximum(value, min), max)
}

/// Applies a smoothing function to `value` such that `edge0` maps to 0, `edge1` maps to 1, and an easing curve
/// is applied to values in between.
func smoothstep (_ value: Float, minEdge edge0: Float, maxEdge edge1: Float) -> Float {
    // Scale, and clamp x to 0..1 range.
    let value = clamp((value - edge0) / (edge1 - edge0), min: 0.0, max: 1.0)
    return value * value * (3.0 - 2.0 * value)
}

