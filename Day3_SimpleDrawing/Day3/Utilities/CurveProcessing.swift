/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A collection of algorithms to generate smooth curves.
  Techniques include cubic Hermite curves as well as Catmull-Rom curves.
*/

// MARK: HermiteInterpolant

/// A type must support these operations for use as an interpolant in a Hermite curve.
protocol HermiteInterpolant {
    static func distance(_: Self, _: Self) -> Float
    static func length(_: Self) -> Float
    static func dot(_: Self, _: Self) -> Float
    static func + (left: Self, right: Self) -> Self
    static func - (left: Self, right: Self) -> Self
    static func * (left: Float, right: Self) -> Self
    static func * (left: Self, right: Float) -> Self
    static func / (left: Self, right: Float) -> Self
}

extension Float: HermiteInterpolant {
    static func distance(_ point0: Float, _ point1: Float) -> Float {
        return abs(point0 - point1)
    }
    
    static func length(_ point: Float) -> Float {
        return abs(point)
    }
    
    static func dot(_ point0: Self, _ point1: Self) -> Float {
        return point0 * point1
    }
}

extension SIMD2: HermiteInterpolant where Scalar == Float {
    static func distance(_ point0: SIMD2<Float>, _ point1: SIMD2<Float>) -> Float {
        return simd.distance(point0, point1)
    }
    
    static func length(_ point0: Self) -> Float {
        return simd.length(point0)
    }
    
    static func dot(_ point0: Self, _ point1: Self) -> Float {
        return simd.dot(point0, point1)
    }
}

extension SIMD3: HermiteInterpolant where Scalar == Float {
    static func distance(_ point0: SIMD3<Float>, _ point1: SIMD3<Float>) -> Float {
        return simd.distance(point0, point1)
    }
    
    static func length(_ point0: Self) -> Float {
        return simd.length(point0)
    }
    
    static func dot(_ point0: Self, _ point1: Self) -> Float {
        return simd.dot(point0, point1)
    }
}

extension SIMD4: HermiteInterpolant where Scalar == Float {
    static func distance(_ point0: SIMD4<Float>, _ point1: SIMD4<Float>) -> Float {
        return simd.distance(point0, point1)
    }
    
    static func length(_ point0: Self) -> Float {
        return simd.length(point0)
    }
    
    static func dot(_ point0: Self, _ point1: Self) -> Float {
        return simd.dot(point0, point1)
    }
}

// MARK: Hermite Curves

/// A control point on a Hermite curve is defined by its position and tangent vector (derivative).
///
/// The type of a control point can be anything that conforms to `HermiteInterpolant`.
struct HermiteControlPoint<T: HermiteInterpolant> {
    var position: T
    var tangent: T
}

/// Evaluates a cubic Hermite curve at the specified parameter with the provided control points.
///
/// - Parameters:
///   - point0: The starting control point of the curve, corresponding with `parameter == 0`.
///   - point1: The ending control point of the curve, corresponding with `parameter == 1`.
///   - parameter: The parameter value with which to interpolate the control points `point0`
///         (which corresponds to `parameter == 0`) and `point1` (which corresponds to `parameter == 1`).
///
func evaluateHermiteCurve<T: HermiteInterpolant>(_ point0: HermiteControlPoint<T>, _ point1: HermiteControlPoint<T>, parameter: Float) -> T {
    let parameter2 = parameter * parameter
    let parameter3 = parameter2 * parameter
    
    // The basis vectors of a classical Hermite curve.
    let p0Basis: Float = 2 * parameter3 - 3 * parameter2 + 1
    let m0Basis: Float = parameter3 - 2 * parameter2 + parameter
    let p1Basis: Float = -2 * parameter3 + 3 * parameter2
    let m1Basis: Float = parameter3 - parameter2
    
    let p0Term: T = p0Basis * point0.position
    let m0Term: T = m0Basis * point0.tangent
    let p1Term: T = p1Basis * point1.position
    let m1Term: T = m1Basis * point1.tangent
    
    return p0Term + m0Term + p1Term + m1Term
}

/// Evaluates the derivative of a cubic Hermite curve at the specified parameter with the provided control points.
///
/// - Parameters:
///   - point0: The starting control point of the curve, corresponding with `parameter == 0`.
///   - point1: The ending control point of the curve, corresponding with `parameter == 1`.
///   - parameter: The parameter value with which to interpolate the control points `point0`
///         (which corresponds to `parameter == 0`) and `point1` (which corresponds to `parameter == 1`).
func evaluateHermiteCurveDerivative<T: HermiteInterpolant>(_ point0: HermiteControlPoint<T>,
                                                           _ point1: HermiteControlPoint<T>,
                                                           parameter: Float) -> T {
    let parameter2 = parameter * parameter
    
    // These are the derivatives of the basis functions in `evaluateHermiteCurve()`, above.
    let p0Basis: Float = 6 * parameter2 - 6 * parameter
    let m0Basis: Float = 3 * parameter2 - 4 * parameter + 1
    let p1Basis: Float = -6 * parameter2 + 6 * parameter
    let m1Basis: Float = 3 * parameter2 - 2 * parameter
    
    let p0Term: T = p0Basis * point0.position
    let m0Term: T = m0Basis * point0.tangent
    let p1Term: T = p1Basis * point1.position
    let m1Term: T = m1Basis * point1.tangent
    
    return p0Term + m0Term + p1Term + m1Term
}

// MARK: Catmull-Rom Curves

/// Evaluates the span `point1` → `point2` of a Catmull-Rom spline at the parameter `parameter`.
///
/// A Catmull-Rom curve sampling the span `point1`↔`point2` is defined with respect to neighbor key points of
/// that span. Provide the key point before `point1` (call this `point0`) and the key point after
/// `point2` (call this `point3`).
///
/// - Parameters:
///   - point0: The key point in the Catmull-Rom Spline before `point1`.
///   - point1: The key point in the Catmull-Rom Spline corresponding with `parameter == 0`.
///   - point2: The key point in the Catmull-Rom Spline corresponding with `parameter == 1`.
///   - point3: The key point in the Catmull-Rom Spline after `point2`.
func evaluateCatmullRomCurve<T: HermiteInterpolant>(_ point0: T, _ point1: T, _ point2: T, _ point3: T, parameter: Float) -> T {
    let tangent1 = (point2 - point0) / 2
    let tangent2 = (point3 - point1) / 2
    
    return evaluateHermiteCurve(HermiteControlPoint(position: point1, tangent: tangent1),
                                HermiteControlPoint(position: point2, tangent: tangent2),
                                parameter: parameter)
}

/// Evaluates the derivative of the span `point1` > `point2` of a Catmull-Rom spline at the parameter `parameter`.
///
/// A Catmull-Rom curve sampling the span `point1`↔`point2` is defined with respect to neighbor key points of
/// that span. Provide the key point before `point1` (call this `point0`) and the key point after
/// `point2` (call this `point3`).
///
/// - Parameters:
///   - point0: The key point in the Catmull-Rom Spline before `point1`.
///   - point1: The key point in the Catmull-Rom Spline corresponding with `parameter == 0`.
///   - point2: The key point in the Catmull-Rom Spline corresponding with `parameter == 1`.
///   - point3: The key point in the Catmull-Rom Spline after `point2`.
func evaluateCatmullRomCurveDerivative<T: HermiteInterpolant>(_ point0: T, _ point1: T, _ point2: T, _ point3: T, parameter: Float) -> T {
    let tangent1 = (point2 - point0) / 2
    let tangent2 = (point3 - point1) / 2
    
    return evaluateHermiteCurveDerivative(HermiteControlPoint(position: point1, tangent: tangent1),
                                          HermiteControlPoint(position: point2, tangent: tangent2),
                                          parameter: parameter)
}

// MARK: Catmull-Rom Subdivision

private struct SubdivisionSearchItem<T> where T: Comparable {
    var range: ClosedRange<T>
    var depth: Int
}

func evaluateCatmullRomSpline<T: HermiteInterpolant, S: RandomAccessCollection<T>>(spline: S,
                                                                                   parameter: Float,
                                                                                   derivative: Bool) -> T where S.Index == Int {
    precondition(!spline.isEmpty, "Tried to evaluate an empty spline")
    guard spline.count > 1 else { return spline[0] }
    
    let point1Index = max(min(Int(parameter), spline.count - 2), 0)
    let point2Index = point1Index + 1
    
    let point1 = spline[point1Index]
    let point2 = spline[point2Index]
    
    let point0 = (point1Index > 0) ? spline[point1Index - 1] : (point1 + (point1 - point2))
    let point3 = (point2Index < spline.count - 1) ? spline[point2Index + 1] : (point2 + (point2 - point1))
    
    let spanParameter = parameter - Float(point1Index)
    if derivative {
        return evaluateCatmullRomCurveDerivative(point0, point1, point2, point3, parameter: spanParameter)
    } else {
        return evaluateCatmullRomCurve(point0, point1, point2, point3, parameter: spanParameter)
    }
}

func subdivideCatmullRomSpline<T: HermiteInterpolant, S: RandomAccessCollection<T>>(
    spline: S, range entireRange: ClosedRange<Float>, flatness: Float, maximumSubdivisionDepth: Int = 8)
-> [Float] where S.Index == Int {
    guard spline.count > 1 else { return [] }
    
    let evaluateCurve: (Float) -> T = {
        evaluateCatmullRomSpline(spline: spline, parameter: $0, derivative: false)
    }
    
    let evaluateTangent: (Float) -> T = {
        let derivative: T = evaluateCatmullRomSpline(spline: spline, parameter: $0, derivative: true)
        let length: Float = T.length(derivative)
        return approximatelyEqual(length, .zero) ? derivative : (derivative / length)
    }
    
    var subdivision: [Float] = []
    
    typealias SearchItem = SubdivisionSearchItem<Float>
    var searchItems: [SearchItem] = [SearchItem(range: entireRange, depth: 0)]
    
    while let item = searchItems.popLast() {
        let range = item.range
        let depth = item.depth
        guard depth < maximumSubdivisionDepth else { continue }
        
        let lowerPoint = evaluateCurve(range.lowerBound)
        let upperPoint = evaluateCurve(range.upperBound)
        
        let lowerTangent = evaluateTangent(range.lowerBound)
        let upperTangent = evaluateTangent(range.upperBound)
        
        let center = (range.upperBound - range.lowerBound) / 2 + range.lowerBound
        let centerPoint = evaluateCurve(center)
        let centerTangent = evaluateTangent(center)
        
        if T.distance((lowerPoint + upperPoint) / 2, centerPoint) > flatness
            || T.dot(lowerTangent, upperTangent) < 0.99
            || T.dot(lowerTangent, centerTangent) < 0.99
            || T.dot(centerTangent, upperTangent) < 0.99 {
            subdivision.append(center)
            searchItems.append(SearchItem(range: range.lowerBound...center, depth: depth + 1))
            searchItems.append(SearchItem(range: center...range.upperBound, depth: depth + 1))
        }
    }
    
    return subdivision.sorted()
}
