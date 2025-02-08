import SwiftUI

struct AssetRowView: View {

    @State private var viewModel: RowViewModel

    private var onDownload: () -> Void
    private var onClear: () -> Void

    init(asset: Asset, onDownload: @escaping () -> Void, onClear: @escaping () -> Void) {
        self.viewModel = RowViewModel(asset: asset)
        self.onDownload = onDownload
        self.onClear = onClear
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(viewModel.asset.stream.name)
                .font(.headline)

            HStack {
                Text(viewModel.downloadState.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                switch(viewModel.downloadState) {
                case .notDownloaded:
                    Button("Download") {
                        onDownload()
                    }
                    .buttonStyle(.borderless)
                case .downloading:
                    ProgressView(value: viewModel.downloadProgress)
                        .progressViewStyle(.linear)
                        .frame(width: 100)
                case .downloaded:
                    Button("Clear") {
                        onClear()
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .padding()
    }
}
