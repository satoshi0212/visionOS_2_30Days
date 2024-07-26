/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
App-specific extension on Entity.
*/

import Foundation
import RealityKit

public extension SIMD3 where Scalar == Float {

    /// Returns a vector that represents an up vector. Used for rotating around the `Y` axis (yaw)
    static let up = SIMD3<Float>(x: 0, y: 1, z: 0)

    /// The magnitude of this vector.
    var magnitude: Float {
        return simd_length(self)
    }
}

public extension Entity {

    var gestureComponent: GestureComponent? {
        get { components[GestureComponent.self] }
        set { components[GestureComponent.self] = newValue }
    }
    
    /// Returns the position of the entity specified in the app's coordinate system. On
    /// iOS and macOS, which don't have a device native coordinate system, scene
    /// space is often referred to as "world space".
    var scenePosition: SIMD3<Float> {
        get { position(relativeTo: nil) }
        set { setPosition(newValue, relativeTo: nil) }
    }
    
    /// Returns the orientation of the entity specified in the app's coordinate system. On
    /// iOS and macOS, which don't have a device native coordinate system, scene
    /// space is often referred to as "world space".
    var sceneOrientation: simd_quatf {
        get { orientation(relativeTo: nil) }
        set { setOrientation(newValue, relativeTo: nil) }
    }
}

public extension Entity {

    var connectableComponent: ConnectableComponent? {
        get { components[ConnectableComponent.self] }
        set { components[ConnectableComponent.self] = newValue }
    }

    var connectableStateComponent: ConnectableStateComponent? {
        get { components[ConnectableStateComponent.self] }
        set { components[ConnectableStateComponent.self] = newValue }
    }

    /// An entity that marks where this piece connects to the previous piece.
    var inConnection: Entity? {
        findEntity(named: "connect_in")
    }

    /// An entity that marks where this piece connects to the next piece.
    var outConnection: Entity? {
        findEntity(named: "connect_out")
    }

    /// A vector that indicates the direction of the piece's in connection.
    var inConnectionVector: Entity? {
        findEntity(named: "in_connection_vector")
    }

    /// A vector that indicates the direction of the piece's out connection.
    var outConnectionVector: Entity? {
        findEntity(named: "out_connection_vector")
    }

    /// Finds the entity containing the connectable component in this entity or one of its ancestors.
    var connectableAncestor: Entity? {
        if connectableComponent != nil { return self }
        var nextParent: Entity? = parent
        while nextParent != nil {
            if nextParent?.connectableComponent != nil {
                return nextParent
            }
            nextParent = nextParent?.parent
        }
        return nil
    }

    /// Returns an array containing all descendants with a name that includes a specified substring.
    func descendants(containingSubstring substring: String) -> [Entity] {
        var childTransforms = children.filter { child in
            return child.name.contains(substring)
        }
        var myTransforms = [Entity]()
        for child in children {
            childTransforms.append(contentsOf: child.descendants(containingSubstring: substring))
        }
        myTransforms.append(contentsOf: childTransforms)
        return myTransforms
    }
}
