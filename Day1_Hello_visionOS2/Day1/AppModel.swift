import SwiftUI
import RealityKit
import Observation

enum AppPhase: CaseIterable, Codable, Identifiable, Sendable {
    case waitingToStart
    case playing

    public var id: Self { self }
}

@MainActor
@Observable
class AppModel {

    // size(meter)
    static let portalWidth: Float = 4
    static let portalHeight: Float = 3

    var phase = AppPhase.waitingToStart

    var isPresentingImmersiveSpace = false
    var wantsToPresentImmersiveSpace = false
}
