import SwiftUI
import RealityKit

extension ImmersiveView {

    @MainActor
    func handleSnap(_ draggedEntity: Entity) {
        guard let state = draggedEntity.connectableStateComponent else { return }

        // Calculate the time since the last move because snapping only happens for a short period of time after the player stops dragging.
        let timeSinceLastMove = Date.timeIntervalSinceReferenceDate - state.lastMoved

        // If no time has elapsed, then the piece is still being dragged and the app won't snap it.
        if timeSinceLastMove <= snapEpsilon {
            return
        }
        isSnapping = true
        // Snapping is based on the connection points of the end pieces only.
        var firstPiece: Entity? = draggedEntity
        var lastPiece: Entity?  = draggedEntity

        // Move backward to find the first dragged piece.
        while firstPiece?.connectableStateComponent?.previousPiece != nil {
            guard let previous = firstPiece?.connectableStateComponent?.previousPiece,
                  let previousState = previous.connectableStateComponent else { break }
            if previousState.isSelected {
                firstPiece = firstPiece?.connectableStateComponent?.previousPiece
            } else {
                break
            }
        }

        // Move forward to find last dragged piece.
        while lastPiece?.connectableStateComponent?.nextPiece != nil {
            guard let next = firstPiece?.connectableStateComponent?.nextPiece,
                  let nextState = next.connectableStateComponent else { break }
            if nextState.isSelected {
                lastPiece = lastPiece?.connectableStateComponent?.nextPiece
            } else {
                break
            }
        }

        var firstDistance = Float.greatestFiniteMagnitude
        var lastDistance = Float.greatestFiniteMagnitude
        var firstConnection: Entity? = nil
        var lastConnection: Entity? = nil

        if let firstPiece = firstPiece {
            let inConnectionFirst = findNearestConnectionPoint(entity: firstPiece, connectionType: .inPoint)
            firstDistance = inConnectionFirst.distance
            firstConnection = inConnectionFirst.closestEntity
        }
        if let lastPiece = lastPiece {
            let outConnectionLast = findNearestConnectionPoint(entity: lastPiece, connectionType: .outPoint)
            lastDistance = outConnectionLast.distance
            lastConnection = outConnectionLast.closestEntity
        }
        let distance = min(firstDistance, lastDistance)
        let snapTo = (firstDistance <= lastDistance) ? firstConnection : lastConnection
        let connectionType: ConnectionPointType = (firstDistance <= lastDistance) ? .inPoint : .outPoint

        // Nothing in snap distance, return.
        guard distance < maximumSnapDistance,
              let entity = (connectionType == .inPoint) ? firstPiece : lastPiece,
              let snapTo = snapTo,
              let ourSnapPoint = (connectionType == .inPoint) ? entity.inConnection?.scenePosition : entity.outConnection?.scenePosition,
              let otherSnapPoint = (connectionType == .inPoint) ? snapTo.outConnection?.scenePosition : snapTo.inConnection?.scenePosition,
              let ourConnectionVectorEntity = (connectionType == .inPoint) ? entity.inConnectionVector : entity.outConnectionVector,
              let otherConnectionVectorEntity = (connectionType == .inPoint) ? snapTo.outConnectionVector : snapTo.inConnectionVector else {
            isSnapping = false
            return
        }

        let ourConnectionVector = ourConnectionVectorEntity.scenePosition - entity.scenePosition
        let otherConnectionVector = otherConnectionVectorEntity.scenePosition - snapTo.scenePosition

        // Check vectors to make sure the pieces are pointing in opposite directions.
        let dotProduct = simd_dot(simd_normalize(ourConnectionVector), simd_normalize(otherConnectionVector))

        if !((dotProduct > 0.95 && dotProduct < 1.05) ||
            (dotProduct < -0.95 && dotProduct > -1.05)) {
            isSnapping = false
            return
        }

        // If there's already something connected to it, the piece doesn't snap.
        if (connectionType == .inPoint && snapTo.connectableStateComponent?.nextPiece != nil
            && snapTo.connectableStateComponent?.nextPiece != entity)
            || (connectionType == .outPoint && snapTo.connectableStateComponent?.previousPiece != nil
                && snapTo.connectableStateComponent?.previousPiece != entity) {
            isSnapping = false
            return
        }

        // Snap the pieces together.
        Task(priority: .userInitiated) {
            let lastMoved = Date.timeIntervalSinceReferenceDate
            let startTime = Date.timeIntervalSinceReferenceDate
            let deltaVector = otherSnapPoint - ourSnapPoint
            let dragStartPosition = draggedEntity.scenePosition
            let dragEndPosition = dragStartPosition + deltaVector

            var now = Date.timeIntervalSinceReferenceDate
            while now <= lastMoved + secondsAfterDragToContinueSnap {
                now = Date.timeIntervalSinceReferenceDate
                let totalElapsedTime = now - startTime

                let alpha = totalElapsedTime / secondsAfterDragToContinueSnap

                let newPosition = quarticLerp(dragStartPosition, dragEndPosition, Float(alpha))
                Task { @MainActor in
                    draggedEntity.scenePosition = newPosition
                }

                SoundEffectPlayer.shared.play(.connected, from: draggedEntity)

                // Wait for one 90FPS frame.
                try? await Task.sleep(for: .milliseconds(11.111_11))
            }
            isSnapping = false
        }
    }

    func findNearestConnectionPoint(entity: Entity, connectionType: ConnectionPointType) -> (closestEntity: Entity?, distance: Float) {
        guard connectionType != .noPoint,
              let ourConnection = (connectionType == .inPoint) ? entity.inConnection : entity.outConnection,
              let ourVectorEntity = (connectionType == .inPoint) ? entity.inConnectionVector : entity.outConnectionVector  else {
            return (nil, Float.greatestFiniteMagnitude)
        }

        guard let otherEntities = entity.scene?.performQuery(ImmersiveView.connectableQuery) else { return (nil, Float.greatestFiniteMagnitude) }

        var closestDistance = Float.greatestFiniteMagnitude
        var closestEntity: Entity? = nil
        otherEntities.forEach() { oneEntity in
            guard oneEntity != entity,
                  let theirConnection = (connectionType == .inPoint) ? oneEntity.outConnection : oneEntity.inConnection,
                  let theirVectorEntity = (connectionType == .inPoint) ? oneEntity.outConnectionVector : oneEntity.inConnectionVector else {
                return
            }

            let ourConnectionVector = simd_normalize(ourVectorEntity.scenePosition)
            let theirConnectionVector = simd_normalize(theirVectorEntity.scenePosition)

            // Make sure the orientation of the pieces is right for connection or snapping.
            let dot = simd_dot(ourConnectionVector, theirConnectionVector)
            if dot >= 0.9 && dot <= 1.1 {
                let delta = theirConnection.scenePosition - ourConnection.scenePosition
                let distance = delta.magnitude
                if distance < closestDistance {
                    closestEntity = oneEntity
                    closestDistance = distance
                }
            }
        }

        return (closestEntity, closestDistance)
    }
}
