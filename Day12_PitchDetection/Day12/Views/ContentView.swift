import SwiftUI
import RealityKit

struct ContentView: View {

    private var pitchDetector = PitchDetector()

    var body: some View {
        VStack {
            Text("Detected Note:")
                .font(.headline)

            Text(pitchDetector.detectedNote)
                .font(.extraLargeTitle)
                .padding()
        }
    }
}
