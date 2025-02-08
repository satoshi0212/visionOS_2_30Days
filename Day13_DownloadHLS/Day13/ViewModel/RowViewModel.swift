import SwiftUI
import Observation
import AVFoundation

@Observable
class RowViewModel {

    var asset: Asset
    var downloadState: Asset.DownloadState = .notDownloaded
    var downloadProgress: Double = 0.0

    init(asset: Asset) {
        self.asset = asset
        self.downloadState = AssetPersistenceManager.shared.downloadState(for: asset)

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(handleAssetDownloadStateChanged(_:)),
                                       name: .AssetDownloadStateChanged, object: nil)
        notificationCenter.addObserver(self, selector: #selector(handleAssetDownloadProgress(_:)),
                                       name: .AssetDownloadProgress, object: nil)
    }

    @objc
    func handleAssetDownloadStateChanged(_ notification: Notification) {
        guard let assetStreamName = notification.userInfo![Asset.Keys.name] as? String,
              let downloadStateRawValue = notification.userInfo![Asset.Keys.downloadState] as? String,
              let downloadState = Asset.DownloadState(rawValue: downloadStateRawValue),
              asset.stream.name == assetStreamName else { return }

        print("handleAssetDownloadStateChanged: " + assetStreamName + " / " + downloadState.rawValue)

        self.downloadState = downloadState

        if downloadState == .notDownloaded {
            asset.localFileUrlAsset = nil
        } else if downloadState == .downloaded {
            if let local = notification.userInfo![Asset.Keys.downloadDestinationUrl] as? URL {
                asset.localFileUrlAsset = AVURLAsset(url: local)
            }
        }
    }

    @objc
    func handleAssetDownloadProgress(_ notification: Notification) {
        guard let assetStreamName = notification.userInfo![Asset.Keys.name] as? String,
              asset.stream.name == assetStreamName,
              let progress = notification.userInfo![Asset.Keys.percentDownloaded] as? Double else { return }

        downloadProgress = progress
    }
}
