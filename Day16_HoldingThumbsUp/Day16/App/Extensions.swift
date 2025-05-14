import SwiftUI
import RealityKit
import ARKit

extension SIMD4 {
    var xyz: SIMD3<Scalar> {
        self[SIMD3(0, 1, 2)]
    }
}

extension HandAnchor {
    func worldPosition(_ joint: HandSkeleton.Joint) -> SIMD3<Float> {
        matrix_multiply(self.originFromAnchorTransform, joint.anchorFromJointTransform).columns.3.xyz
    }
}
