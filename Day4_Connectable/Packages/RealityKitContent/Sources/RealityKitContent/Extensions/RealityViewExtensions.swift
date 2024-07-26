/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
App-specific extension on RealityView.
*/

import Foundation
import RealityKit
import SwiftUI

// MARK: - RealityView Extensions

public extension RealityView {
    
    /// Apply this to a `RealityView` to pass gestures on to the component code.
    func installGestures() -> some View {
        simultaneousGesture(dragGesture)
            .simultaneousGesture(magnifyGesture)
            .simultaneousGesture(rotateGesture)
    }

    func installGestures(dragCompletion: @escaping (EntityTargetValue<DragGesture.Value>) -> Void) -> some View {
        simultaneousGesture(makeDragGesture(completion: dragCompletion))
            .simultaneousGesture(magnifyGesture)
            .simultaneousGesture(rotateGesture)
    }

    /// Builds a drag gesture.
    var dragGesture: some Gesture {
        DragGesture()
            .targetedToAnyEntity()
            .useGestureComponent()
    }

    func makeDragGesture(completion: @escaping (EntityTargetValue<DragGesture.Value>) -> Void) -> some Gesture {
        DragGesture()
            .targetedToAnyEntity()
            .useGestureComponent(completion: completion)
    }

    /// Builds a magnify gesture.
    var magnifyGesture: some Gesture {
        MagnifyGesture()
            .targetedToAnyEntity()
            .useGestureComponent()
    }
    
    /// Buildsa rotate gesture.
    var rotateGesture: some Gesture {
        RotateGesture3D()
            .targetedToAnyEntity()
            .useGestureComponent()
    }
}
