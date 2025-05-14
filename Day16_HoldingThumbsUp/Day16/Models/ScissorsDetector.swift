import RealityKit
import SwiftUI
import ARKit

@Observable
class ScissorsDetector {

    private func isFingerFolded(a: SIMD3<Float>, b: SIMD3<Float>) -> Bool {
        return distance(a, b) < 0.08
    }

    private func isFingerExtended(a: SIMD3<Float>, b: SIMD3<Float>) -> Bool {
        return distance(a, b) > 0.08
    }

    func detectGesture(handAnchor: HandAnchor?) -> Bool {
        guard let handAnchor = handAnchor, handAnchor.isTracked else { return false }

        guard
            let thumbTip = handAnchor.handSkeleton?.joint(.thumbTip),
            let indexTip = handAnchor.handSkeleton?.joint(.indexFingerTip),
            let indexBase = handAnchor.handSkeleton?.joint(.indexFingerMetacarpal),
            let middleTip = handAnchor.handSkeleton?.joint(.middleFingerTip),
            let middleBase = handAnchor.handSkeleton?.joint(.middleFingerMetacarpal),
            let middleIntermediateBase = handAnchor.handSkeleton?.joint(.middleFingerIntermediateBase),
            let ringTip = handAnchor.handSkeleton?.joint(.ringFingerTip),
            let ringBase = handAnchor.handSkeleton?.joint(.ringFingerMetacarpal),
            let littleTip = handAnchor.handSkeleton?.joint(.littleFingerTip),
            let littleBase = handAnchor.handSkeleton?.joint(.littleFingerMetacarpal),

            thumbTip.isTracked,
            indexTip.isTracked,
            indexBase.isTracked,
            middleTip.isTracked,
            middleBase.isTracked,
            middleIntermediateBase.isTracked,
            ringTip.isTracked,
            ringBase.isTracked,
            littleTip.isTracked,
            littleBase.isTracked
        else {
            return false
        }

        let thumbPos = handAnchor.worldPosition(thumbTip)
        let indexPos = handAnchor.worldPosition(indexTip)
        let indexBasePos = handAnchor.worldPosition(indexBase)
        let middlePos = handAnchor.worldPosition(middleTip)
        let middleBasePos = handAnchor.worldPosition(middleBase)
        let middleIntermediateBasePos = handAnchor.worldPosition(middleIntermediateBase)
        let ringPos = handAnchor.worldPosition(ringTip)
        let ringBasePos = handAnchor.worldPosition(ringBase)
        let littlePos = handAnchor.worldPosition(littleTip)
        let littleBasePos = handAnchor.worldPosition(littleBase)

        let isIndexExtended = isFingerExtended(a: indexPos, b: indexBasePos)
        let isMiddleExtended = isFingerExtended(a: middlePos, b: middleBasePos)
        let isThumbFolded = isFingerFolded(a: thumbPos, b: middleIntermediateBasePos)
        let isRingFolded = isFingerFolded(a: ringPos, b: ringBasePos)
        let isLittleFolded = isFingerFolded(a: littlePos, b: littleBasePos)

        return isIndexExtended && isMiddleExtended && isThumbFolded && isRingFolded && isLittleFolded
    }
}
