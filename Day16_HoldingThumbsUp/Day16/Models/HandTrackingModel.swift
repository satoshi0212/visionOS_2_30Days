import ARKit

enum HandGestureType: String {
    case scissors
    case thumbsUp
    case none
}

@Observable
@MainActor
class HandTrackingModel {

    struct HandsUpdates {
        var left: HandAnchor?
        var right: HandAnchor?
    }

    var handGesture: HandGestureType = .none
    var scissorsDetector: ScissorsDetector = .init()
    var thumbsUpHoldDetector: ThumbsUpHoldDetector = .init()

    private let session = ARKitSession()
    private let handTracking = HandTrackingProvider()
    private var latestHandTracking: HandsUpdates? = .init(left: nil, right: nil)
    
    func setup() { }

    var handTrackingProviderSupported: Bool {
        HandTrackingProvider.isSupported
    }
    
    var isReadyToRun: Bool {
        handTracking.state == .initialized || handTracking.state == .paused
    }
    
    func startHandTracking() async {
        do {
            if handTrackingProviderSupported && isReadyToRun {
                try await session.run([handTracking])
            } else {
                fatalError("Hand tracking not supported or not ready to run.")
            }
        } catch {
            fatalError("session run failed: \(error)")
        }
    }

    func processHandUpdated() async {
        for await update in handTracking.anchorUpdates {
            switch update.event {
            case .updated:
                let anchor = update.anchor
                if anchor.chirality == .left {
                    latestHandTracking?.left = anchor
                } else {
                    latestHandTracking?.right = anchor
                }
                // note: Only the right hand is used this time.
                detectionHandGesture(rightHandAnchor: latestHandTracking?.right)
            default:
                break
            }
        }
    }

    private func detectionHandGesture(rightHandAnchor: HandAnchor?) {
        if scissorsDetector.detectGesture(handAnchor: rightHandAnchor) {
            handGesture = .scissors
        } else if thumbsUpHoldDetector.detectGesture(handAnchor: rightHandAnchor) {
            handGesture = .thumbsUp
        } else {
            handGesture = .none
        }

        thumbsUpHoldDetector.updateDetection(isThumbsUp: handGesture == .thumbsUp)
    }
}
