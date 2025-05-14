import SwiftUI

struct ThumbsUpProgressView: View {

    @State var handTrackingModel: HandTrackingModel

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 12)

                Circle()
                    .trim(from: 0, to: handTrackingModel.thumbsUpHoldDetector.progress)
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: handTrackingModel.thumbsUpHoldDetector.progress)

                Image(systemName: handTrackingModel.thumbsUpHoldDetector.isConfirmed ? "hand.thumbsup.fill" : "hand.thumbsup")
                    .resizable()
                    .scaledToFit()
                    .frame(width: geometry.size.width * 0.5)
                    .foregroundColor(handTrackingModel.thumbsUpHoldDetector.isConfirmed ? .green : .gray)
            }
            .padding(12 / 2)
        }
        .frame(width: 120, height: 120)
    }
}
