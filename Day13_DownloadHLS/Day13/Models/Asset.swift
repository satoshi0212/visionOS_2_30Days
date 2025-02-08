import AVFoundation

@Observable
class Asset: Identifiable {
    var id = UUID()
    var urlAsset: AVURLAsset
    var stream: Stream
    var localFileUrlAsset: AVURLAsset?

    init(id: UUID = UUID(), urlAsset: AVURLAsset, stream: Stream, localFileUrlAsset: AVURLAsset? = nil) {
        self.id = id
        self.urlAsset = urlAsset
        self.stream = stream
        self.localFileUrlAsset = localFileUrlAsset
    }
}

extension Asset: Equatable {
    static func ==(lhs: Asset, rhs: Asset) -> Bool {
        return (lhs.stream == rhs.stream) && (lhs.urlAsset == rhs.urlAsset)
    }
}

extension Asset {
    enum DownloadState: String {
        case notDownloaded
        case downloading
        case downloaded
    }
}

extension Asset {
    struct Keys {
        static let name = "AssetNameKey"
        static let percentDownloaded = "AssetPercentDownloadedKey"
        static let downloadState = "AssetDownloadStateKey"
        static let downloadSelectionDisplayName = "AssetDownloadSelectionDisplayNameKey"
        static let downloadDestinationUrl = "AssetDownloadDestinationUrlKey"
    }
}
