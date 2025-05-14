import RealityKit
import SwiftUI
import ARKit

@Observable
class ThumbsUpHoldDetector {

    var isConfirmed: Bool = false
    var progress: CGFloat = 0.0

    private var startTime: Date?
    private var timer: Timer?
    private let requiredDuration: TimeInterval = 1.8

    func detectGesture(handAnchor: HandAnchor?) -> Bool {
        guard let handAnchor = handAnchor, handAnchor.isTracked else { return false }

        guard
            let handWrist = handAnchor.handSkeleton?.joint(.wrist),
            let handThumbTip = handAnchor.handSkeleton?.joint(.thumbTip),
            let handIndexFingerIntermediateBase = handAnchor.handSkeleton?.joint(.indexFingerIntermediateBase),
            let handIndexTip = handAnchor.handSkeleton?.joint(.indexFingerTip),
            let handMiddleTip = handAnchor.handSkeleton?.joint(.middleFingerTip),
            let handRingTip = handAnchor.handSkeleton?.joint(.ringFingerTip),
            let handLittleTip = handAnchor.handSkeleton?.joint(.littleFingerTip),

            handWrist.isTracked,
            handThumbTip.isTracked,
            handIndexFingerIntermediateBase.isTracked,
            handIndexTip.isTracked,
            handMiddleTip.isTracked,
            handRingTip.isTracked,
            handLittleTip.isTracked
        else {
            return false
        }

        let wristPos = handAnchor.worldPosition(handWrist)
        let thumbTipPos = handAnchor.worldPosition(handThumbTip)
        let indexIntermediateBasePos = handAnchor.worldPosition(handIndexFingerIntermediateBase)
        let indexTipPos = handAnchor.worldPosition(handIndexTip)
        let middleTipPos = handAnchor.worldPosition(handMiddleTip)
        let ringTipPos = handAnchor.worldPosition(handRingTip)
        let littleTipPos = handAnchor.worldPosition(handLittleTip)

        let isThumbUp = distance(thumbTipPos, indexIntermediateBasePos) > 0.05
        let isIndexBent = distance(wristPos, indexTipPos) < 0.08
        let isMiddleBent = distance(wristPos, middleTipPos) < 0.08
        let isRingBent = distance(wristPos, ringTipPos) < 0.08
        let isLittleBent = distance(wristPos, littleTipPos) < 0.08

        return isThumbUp && isIndexBent && isMiddleBent && isRingBent && isLittleBent
    }

    func updateDetection(isThumbsUp: Bool) {
        if !isThumbsUp {
            reset()
            return
        }

        if startTime == nil {
            startTime = Date()
            startTimer()
        }
    }

    func reset() {
        startTime = nil
        timer?.invalidate()
        timer = nil
        progress = 0.0
        isConfirmed = false
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            guard let self, let start = self.startTime else { return }
            let elapsed = Date().timeIntervalSince(start)
            self.progress = min(CGFloat(elapsed / self.requiredDuration), 1.0)
            if elapsed - 0.032 > self.requiredDuration {
                self.isConfirmed = true
                self.timer?.invalidate()
            }
        }
    }
}
