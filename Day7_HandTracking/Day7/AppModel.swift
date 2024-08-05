import SwiftUI

@MainActor
@Observable
class AppModel {
    let immersiveSpaceID = "ImmersiveSpace"
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    var immersiveSpaceState = ImmersiveSpaceState.closed

    var upperLimbVisibility: Visibility = .visible

    enum Mode: String, CaseIterable, Identifiable {
        var id: String{ self.rawValue }

        case axis
        case bottle
    }
    var mode: Mode = .axis
}
