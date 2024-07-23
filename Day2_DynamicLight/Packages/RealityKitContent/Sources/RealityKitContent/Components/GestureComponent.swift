/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component that handles standard drag, rotate, and scale gestures for an entity.
*/

import RealityKit
import SwiftUI

public class EntityGestureState {
    
    /// The entity currently being dragged if a gesture is in progress.
    var targetedEntity: Entity?
    
    // MARK: - Drag
    
    /// The starting position.
    var dragStartPosition: SIMD3<Float> = .zero
    
    /// Marks whether the app is currently handling a drag gesture.
    var isDragging = false
    
    /// When `rotateOnDrag` is`true`, this entity acts as the pivot point for the drag.
    var pivotEntity: Entity?
    
    var initialOrientation: simd_quatf?
    
    // MARK: - Magnify
    
    /// The starting scale value.
    var startScale: SIMD3<Float> = .one
    
    /// Marks whether the app is currently handling a scale gesture.
    var isScaling = false
    
    // MARK: - Rotation
    
    /// The starting rotation value.
    var startOrientation = Rotation3D.identity
    
    /// Marks whether the app is currently handling a rotation gesture.
    var isRotating = false
    
    // MARK: - Singleton Accessor
    
    /// Retrieves the shared instance.
    static let shared = EntityGestureState()
}

// MARK: -

/// A component that handles gesture logic for an entity.
public struct GestureComponent: Component, Codable {
    
    public static func make(canDrag: Bool = false, pivotOnDrag: Bool = false, preserveOrientationOnPivotDrag: Bool = false, canScale: Bool = false, canRotate: Bool = false) -> GestureComponent {
        return GestureComponent(
            canDrag: canDrag,
            pivotOnDrag: pivotOnDrag,
            preserveOrientationOnPivotDrag: preserveOrientationOnPivotDrag,
            canScale: canScale,
            canRotate: canRotate)
    }

    init(canDrag: Bool, pivotOnDrag: Bool, preserveOrientationOnPivotDrag: Bool, canScale: Bool, canRotate: Bool) {
        self.canDrag = canDrag
        self.pivotOnDrag = pivotOnDrag
        self.preserveOrientationOnPivotDrag = preserveOrientationOnPivotDrag
        self.canScale = canScale
        self.canRotate = canRotate
    }

    /// A Boolean value that indicates whether a gesture can drag the entity.
    public var canDrag: Bool = true
    
    /// A Boolean value that indicates whether a dragging can move the object in an arc, similar to dragging windows or moving the keyboard.
    public var pivotOnDrag: Bool = true
    
    /// A Boolean value that indicates whether a pivot drag keeps the orientation toward the
    /// viewer throughout the drag gesture.
    ///
    /// The property only applies when `pivotOnDrag` is `true`.
    public var preserveOrientationOnPivotDrag: Bool = true
    
    /// A Boolean value that indicates whether a gesture can scale the entity.
    public var canScale: Bool = true
    
    /// A Boolean value that indicates whether a gesture can rotate the entity.
    public var canRotate: Bool = true
    
    // MARK: - Drag Logic
    
    /// Handle `.onChanged` actions for drag gestures.
    mutating func onChanged(value: EntityTargetValue<DragGesture.Value>) {
        guard canDrag else { return }
        
        let state = EntityGestureState.shared
        
        // Only allow a single Entity to be targeted at any given time.
        if state.targetedEntity == nil {
            state.targetedEntity = value.entity
            state.initialOrientation = value.entity.orientation(relativeTo: nil)
        }
        
        if pivotOnDrag {
            handlePivotDrag(value: value)
        } else {
            handleFixedDrag(value: value)
        }
    }
    
    mutating private func handlePivotDrag(value: EntityTargetValue<DragGesture.Value>) {
        
        let state = EntityGestureState.shared
        guard let entity = state.targetedEntity else { fatalError("Gesture contained no entity") }
        
        // The transform that the pivot will be moved to.
        var targetPivotTransform = Transform()
        
        // Set the target pivot transform depending on the input source.
        if let inputDevicePose = value.inputDevicePose3D {
            
            // If there is an input device pose, use it for positioning and rotating the pivot.
            targetPivotTransform.scale = .one
            targetPivotTransform.translation = value.convert(inputDevicePose.position, from: .local, to: .scene)
            targetPivotTransform.rotation = value.convert(AffineTransform3D(rotation: inputDevicePose.rotation), from: .local, to: .scene).rotation
        } else {
            // If there is not an input device pose, use the location of the drag for positioning the pivot.
            targetPivotTransform.translation = value.convert(value.location3D, from: .local, to: .scene)
        }
        
        if !state.isDragging {
            // If this drag just started, create the pivot entity.
            let pivotEntity = Entity()
            
            guard let parent = entity.parent else { fatalError("Non-root entity is missing a parent.") }
            
            // Add the pivot entity into the scene.
            parent.addChild(pivotEntity)
            
            // Move the pivot entity to the target transform.
            pivotEntity.move(to: targetPivotTransform, relativeTo: nil)
            
            // Add the targeted entity as a child of the pivot without changing the targeted entity's world transform.
            pivotEntity.addChild(entity, preservingWorldTransform: true)
            
            // Store the pivot entity.
            state.pivotEntity = pivotEntity
            
            // Indicate that a drag has started.
            state.isDragging = true

        } else {
            // If this drag is ongoing, move the pivot entity to the target transform.
            // The animation duration smooths the noise in the target transform across frames.
            state.pivotEntity?.move(to: targetPivotTransform, relativeTo: nil, duration: 0.2)
        }
        
        if preserveOrientationOnPivotDrag, let initialOrientation = state.initialOrientation {
            state.targetedEntity?.setOrientation(initialOrientation, relativeTo: nil)
        }
    }
    
    mutating private func handleFixedDrag(value: EntityTargetValue<DragGesture.Value>) {
        let state = EntityGestureState.shared
        guard let entity = state.targetedEntity else { fatalError("Gesture contained no entity") }
        
        if !state.isDragging {
            state.isDragging = true
            state.dragStartPosition = entity.scenePosition
        }
   
        let translation3D = value.convert(value.gestureValue.translation3D, from: .local, to: .scene)
        
        let offset = SIMD3<Float>(x: Float(translation3D.x),
                                  y: Float(translation3D.y),
                                  z: Float(translation3D.z))
        
        entity.scenePosition = state.dragStartPosition + offset
        if let initialOrientation = state.initialOrientation {
            state.targetedEntity?.setOrientation(initialOrientation, relativeTo: nil)
        }
        
    }
    
    /// Handle `.onEnded` actions for drag gestures.
    mutating func onEnded(value: EntityTargetValue<DragGesture.Value>) {
        let state = EntityGestureState.shared
        state.isDragging = false
        
        if let pivotEntity = state.pivotEntity,
           pivotOnDrag {
            pivotEntity.parent!.addChild(state.targetedEntity!, preservingWorldTransform: true)
            pivotEntity.removeFromParent()
        }
        
        state.pivotEntity = nil
        state.targetedEntity = nil
    }

    // MARK: - Magnify (Scale) Logic
    
    /// Handle `.onChanged` actions for magnify (scale)  gestures.
    mutating func onChanged(value: EntityTargetValue<MagnifyGesture.Value>) {
        let state = EntityGestureState.shared
        guard canScale, !state.isDragging else { return }
        
        let entity = value.entity
        
        if !state.isScaling {
            state.isScaling = true
            state.startScale = entity.scale
        }
        
        let magnification = Float(value.magnification)
        entity.scale = state.startScale * magnification
    }
    
    /// Handle `.onEnded` actions for magnify (scale)  gestures
    mutating func onEnded(value: EntityTargetValue<MagnifyGesture.Value>) {
        EntityGestureState.shared.isScaling = false
    }
    
    // MARK: - Rotate Logic
    
    /// Handle `.onChanged` actions for rotate  gestures.
    mutating func onChanged(value: EntityTargetValue<RotateGesture3D.Value>) {
        let state = EntityGestureState.shared
        guard canRotate, !state.isDragging else { return }

        let entity = value.entity
        
        if !state.isRotating {
            state.isRotating = true
            state.startOrientation = .init(entity.orientation(relativeTo: nil))
        }
        
        let rotation = value.rotation
        let flippedRotation = Rotation3D(angle: rotation.angle,
                                         axis: RotationAxis3D(x: -rotation.axis.x,
                                                              y: rotation.axis.y,
                                                              z: -rotation.axis.z))
        let newOrientation = state.startOrientation.rotated(by: flippedRotation)
        entity.setOrientation(.init(newOrientation), relativeTo: nil)
    }
    
    /// Handle `.onChanged` actions for rotate  gestures.
    mutating func onEnded(value: EntityTargetValue<RotateGesture3D.Value>) {
        EntityGestureState.shared.isRotating = false
    }
}
