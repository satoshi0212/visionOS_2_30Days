import AVFoundation
import Accelerate

@Observable
class PitchDetector {
    var detectedNote: String = "Listening..."

    private var audioEngine: AVAudioEngine!
    private let sampleRate: Double = 44100.0
    private let bufferSize: AVAudioFrameCount = 1024

    private let notes = [
        "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"
    ]

    private let noteFrequencies: [Double] = {
        (0..<88).map { i in
            return 440.0 * pow(2.0, (Double(i) - 49.0) / 12.0)
        }
    }()

    init() {
        audioEngine = AVAudioEngine()
        configureAudioSession()
        startListening()
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, options: .defaultToSpeaker)
            try session.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }

    private func startListening() {
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: inputFormat) { buffer, _ in
            self.detectPitch(buffer: buffer)
        }

        do {
            try audioEngine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }

    private func detectPitch(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)

        var rms: Float = 0.0
        vDSP_rmsqv(channelData, 1, &rms, vDSP_Length(frameLength))

        let volumeThreshold: Float = 0.01

        if rms < volumeThreshold {
            Task { @MainActor in
                self.detectedNote = "-"
            }
            return
        }

        var windowedSamples = [Float](repeating: 0.0, count: frameLength)
        let hannWindow = vDSP.window(ofType: Float.self, usingSequence: .hanningDenormalized, count: frameLength, isHalfWindow: false)

        hannWindow.withUnsafeBufferPointer { hannWindowPtr in
            vDSP_vmul(channelData, 1, hannWindowPtr.baseAddress!, 1, &windowedSamples, 1, vDSP_Length(frameLength))
        }

        var realp = [Float](repeating: 0.0, count: frameLength / 2)
        var imagp = [Float](repeating: 0.0, count: frameLength / 2)
        realp.withUnsafeMutableBufferPointer { realPtr in
            imagp.withUnsafeMutableBufferPointer { imagPtr in
                var dspSplitComplex = DSPSplitComplex(realp: realPtr.baseAddress!, imagp: imagPtr.baseAddress!)

                windowedSamples.withUnsafeBufferPointer { samplesPtr in
                    let log2n = vDSP_Length(log2(Double(frameLength)))
                    let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(FFT_RADIX2))

                    samplesPtr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: frameLength / 2) { complexPtr in
                        vDSP_ctoz(complexPtr, 2, &dspSplitComplex, 1, vDSP_Length(frameLength / 2))
                    }

                    vDSP_fft_zrip(fftSetup!, &dspSplitComplex, 1, log2n, FFTDirection(FFT_FORWARD))

                    vDSP_destroy_fftsetup(fftSetup)
                }
            }
        }

        let magnitudes = zip(realp, imagp).map { sqrt($0 * $0 + $1 * $1) }
        if let maxMagnitudeIndex = magnitudes.enumerated().max(by: { $0.element < $1.element })?.offset {
            let maxMagnitude = magnitudes[maxMagnitudeIndex]

            let prevMagnitude = maxMagnitudeIndex > 0 ? magnitudes[maxMagnitudeIndex - 1] : 0
            let nextMagnitude = maxMagnitudeIndex < magnitudes.count - 1 ? magnitudes[maxMagnitudeIndex + 1] : 0

            let delta = 0.5 * (prevMagnitude - nextMagnitude) / (prevMagnitude - 2 * maxMagnitude + nextMagnitude)
            let interpolatedBin = Double(maxMagnitudeIndex) + Double(delta)

            let frequency = interpolatedBin * (sampleRate / Double(frameLength))
            let noteIndex = self.getNoteIndex(frequency: frequency)

            Task { @MainActor in
                self.detectedNote = self.notes[noteIndex]
            }
        }
    }

    private func getNoteIndex(frequency: Double) -> Int {
        var index = 0
        for (i, noteFrequency) in noteFrequencies.enumerated() {
            if frequency < noteFrequency {
                index = i
                break
            }
        }
        return index % notes.count
    }
}
