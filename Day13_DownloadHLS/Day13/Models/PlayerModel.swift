import AVKit

@MainActor
@Observable
class PlayerModel {

    private(set) var isPlaying = false
    private(set) var isPlaybackComplete = false
    
    private(set) var currentItem: Video? = nil
    private var player: AVPlayer
    
    private var playerUI: AnyObject? = nil
    private var playerUIDelegate: AnyObject? = nil
    
    private var timeObserver: Any? = nil    
    private var playerObservationToken: NSKeyValueObservation?
    
    init() {
        let player = AVPlayer()
        self.player = player
        observePlayback()
        configureAudioSession()
    }
    
    func makePlayerUI() -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        playerUI = controller
        
        @MainActor
        class PlayerViewObserver: NSObject, AVPlayerViewControllerDelegate {
            private var continuation: CheckedContinuation<Void, Never>?
            
            func willEndFullScreenPresentation() async {
                await withCheckedContinuation {
                    continuation = $0
                }
            }
            
            nonisolated func playerViewController(
                _ playerViewController: AVPlayerViewController,
                willEndFullScreenPresentationWithAnimationCoordinator coordinator: any UIViewControllerTransitionCoordinator
            ) {
                Task { @MainActor in
                    continuation?.resume()
                }
            }
        }
        
        let observer = PlayerViewObserver()
        controller.delegate = observer
        playerUIDelegate = observer
        
        Task {
            await observer.willEndFullScreenPresentation()
            reset()
        }

        return controller
    }

    private func observePlayback() {
        guard playerObservationToken == nil else { return }
        
        playerObservationToken = player.observe(\.timeControlStatus) { observed, _ in
            Task { @MainActor [weak self] in
                self?.isPlaying = observed.timeControlStatus == .playing
                if let startTime = self?.currentItem?.startTime {
                    if startTime > 0 {
                        self?.player.seek(to: CMTime(value: startTime, timescale: 1))
                    }
                }
            }
        }
        
        Task {
            for await _ in NotificationCenter.default.notifications(named: .AVPlayerItemDidPlayToEndTime) {
                isPlaybackComplete = true
            }
        }
    }
    
    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .moviePlayback)
        } catch {
            print(error)
        }
    }

    func loadVideo(_ video: Video) {
        currentItem = video
        isPlaybackComplete = false
        player.replaceCurrentItem(with: video.playerItem)
   }
    
    func reset() {
        currentItem = nil
        player.replaceCurrentItem(with: nil)
        playerUI = nil
        playerUIDelegate = nil
    }

    // MARK: - Transport Control
    
    func play() {
        player.play()
    }

    func seek() {
        player.play()
    }

    func pause() {
        player.pause()
    }
    
    func togglePlayback() {
        player.timeControlStatus == .paused ? play() : pause()
    }
}
