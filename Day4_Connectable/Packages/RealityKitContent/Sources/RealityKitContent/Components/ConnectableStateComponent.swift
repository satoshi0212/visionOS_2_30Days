/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component that holds state values for connectable slide pieces.
*/

import Foundation
import RealityKit
import Combine
import AVFoundation
import struct SwiftUI.Angle

/// A component to hold internal state values. The project separates these values into a
/// separate component from `ConnectableComponent` so that Reality Composer Pro doesn't display these values.
/// Swift Splash automatically adds one of these to any entity with a `ConnectableComponent`.
@MainActor
public struct ConnectableStateComponent: Component, CustomStringConvertible {
    public var dragStart: SIMD3<Float>? = nil
    public var dragOffset = SIMD3<Float>.zero
    public var lastMoved: TimeInterval = 0
    
    public var rotationAngle = simd_quatf(angle: 0.0, axis: SIMD3<Float>.up)
    
    /// The entity this component is currently attached to.
    public var entity: Entity?
    
    /// Whether the piece is selected.
    public var isSelected = false
    
    /// If another connectible piece is connected to this piece's out connection, this holds that connected piece.
    public var nextPiece: Entity?
    
    /// If another connectible piece is connected to this piece's in connection, this holds that connected piece.
    public var previousPiece: Entity?
    
    /// Stores the point where this piece can connect to a previous piece. This is a `Transform`
    /// that's stored as a child entity.
    public var inConnection: Entity? = nil
    
    /// Stores the point where this piece can connect to the next piece. This is a `Transform`
    /// that's stored as a child entity.
    public var outConnection: Entity? = nil
    
    /// Stores the entity's rotation on the Y axis in radians at the time the current gesture started.
    public var startRotation: Double = 0
    
    nonisolated
    public var description: String {
        return "dragStart: \(String(describing: dragStart)), dragOffset: \(dragOffset), " +
                "lastMoved: \(lastMoved), rotationAngle: \(rotationAngle)."
    }
    
    public init() {}
    
    /// Calculates the world position for a piece being dragged based on `dragStart` and `dragOffset`.
    /// Returns `nil` if the pieces is not being dragged.
    public var worldPosition: SIMD3<Float>? {
        if let dragStart = dragStart {
            return dragStart + dragOffset
        }
        return nil
    }
}
