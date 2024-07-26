import AVKit
import RealityKit

public enum SoundEffect: String {
    case connected
}

public final class SoundEffectPlayer {

    public static var shared: SoundEffectPlayer = try! SoundEffectPlayer()

    private static let mutedGain: Audio.Decibel = -.infinity
    private static let unmutedGain: Audio.Decibel = .zero

    private var isMuted = false

    private var playbackControllers: [AudioPlaybackController] = []
    private var soundEffects: [SoundEffect: AudioResource] = [:]

    private init() throws {
        Task {
            soundEffects[.connected] = try await AudioFileResource(named: "connected")
        }
    }

    @discardableResult
    public func play(_ soundEffect: SoundEffect, from entity: Entity) -> AudioPlaybackController? {
        guard let audio = soundEffects[soundEffect] else { return nil }

        if let inFlightController = playbackControllers(for: soundEffect, from: entity).first {
            return inFlightController
        }

        let controller = entity.playAudio(audio)
        controller.gain = isMuted ? Self.mutedGain : Self.unmutedGain

        controller.completionHandler = { [weak self, weak controller] in
            guard let self, let controller else { return }
            self.playbackControllers.removeAll { $0 === controller }
        }

        playbackControllers.append(controller)

        return controller
    }

    public func pause(_ soundEffect: SoundEffect, from entity: Entity? = nil) {
        for controller in playbackControllers(for: soundEffect, from: entity) {
            controller.pause()
        }
    }

    public func pauseAll() {
        for controller in playbackControllers {
            controller.pause()
        }
    }

    public func resumeAll() {
        for controller in playbackControllers {
            controller.play()
        }
    }

    public func resume(_ soundEffect: SoundEffect, from entity: Entity? = nil) {
        for controller in playbackControllers(for: soundEffect, from: entity) {
            controller.play()
        }
    }

    public func stopAll() {
        for playbackController in playbackControllers {
            playbackController.stop()
        }
        playbackControllers.removeAll()
    }

    public func mute() {
        isMuted = true
        for playbackController in playbackControllers {
            playbackController.fade(to: -.infinity, duration: 0.5)
        }
    }

    public func unmute() {
        isMuted = false
        for playbackController in playbackControllers {
            playbackController.fade(to: .zero, duration: 0.5)
        }
    }

    private func playbackControllers(for soundEffect: SoundEffect, from entity: Entity? = nil) -> [AudioPlaybackController] {
        guard let audio = soundEffects[soundEffect] else { return [] }
        return playbackControllers
            .filter { $0.resource === audio }
            .filter {
                guard let entity = entity else { return true }
                return $0.entity == entity
            }
    }
}
