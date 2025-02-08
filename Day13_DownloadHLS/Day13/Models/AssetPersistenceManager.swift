import Foundation
import AVFoundation
import os

private let logger = Logger(subsystem: "tokyo.shmdevelopment.HLSDownloader", category: "AssetPersistenceManager")

class AssetPersistenceManager: NSObject {

    static let shared = AssetPersistenceManager()
    
    private var didRestorePersistenceManager = false
    fileprivate var assetDownloadURLSession: AVAssetDownloadURLSession!
    fileprivate var activeDownloadsMap = [AVAssetDownloadTask: Asset]()
    fileprivate var willDownloadToUrlMap = [AVAssetDownloadTask: URL]()
    fileprivate var progressObservers: [NSKeyValueObservation] = []

    override private init() {
        super.init()

        let backgroundConfiguration = URLSessionConfiguration.background(withIdentifier: "HLSDownloader-Identifier")

        assetDownloadURLSession = AVAssetDownloadURLSession(configuration: backgroundConfiguration,
                                                            assetDownloadDelegate: self,
                                                            delegateQueue: OperationQueue.main)
    }
    
    func restorePersistenceManager() {
        guard !didRestorePersistenceManager else { return }
        
        didRestorePersistenceManager = true
        
        assetDownloadURLSession.getAllTasks { tasksArray in
            for task in tasksArray {
                guard let assetDownloadTask = task as? AVAssetDownloadTask, let assetName = task.taskDescription else { break }
                let stream = StreamListManager.shared.stream(withName: assetName)
                let urlAsset = assetDownloadTask.urlAsset
                let asset = Asset(urlAsset: urlAsset, stream: stream)
                self.activeDownloadsMap[assetDownloadTask] = asset
            }
            
            NotificationCenter.default.post(name: .AssetPersistenceManagerDidRestoreState, object: nil)
        }
    }

    func downloadStream(for asset: Asset) async throws {
        let preferredMediaSelection = try await asset.urlAsset.load(.preferredMediaSelection)
        let config = AVAssetDownloadConfiguration(asset: asset.urlAsset, title: asset.stream.name)
        let primaryQualifier = AVAssetVariantQualifier(predicate: NSPredicate(format: "peakBitRate > 265000"))
        config.primaryContentConfiguration.variantQualifiers = [primaryQualifier]
        
        let task = assetDownloadURLSession.makeAssetDownloadTask(downloadConfiguration: config)
        task.taskDescription = asset.stream.name

        activeDownloadsMap[task] = asset
        
        let progressObservation: NSKeyValueObservation = task.progress.observe(\.fractionCompleted) { progress, _ in
            Task { @MainActor in
                var userInfo = [String: Any]()
                userInfo[Asset.Keys.name] = asset.stream.name
                userInfo[Asset.Keys.percentDownloaded] = progress.fractionCompleted
                NotificationCenter.default.post(name: .AssetDownloadProgress, object: nil, userInfo: userInfo)
            }
        }
        self.progressObservers.append(progressObservation)

        task.resume()

        var userInfo = [String: Any]()
        userInfo[Asset.Keys.name] = asset.stream.name
        userInfo[Asset.Keys.downloadState] = Asset.DownloadState.downloading.rawValue
        userInfo[Asset.Keys.downloadSelectionDisplayName] = await displayNamesForSelectedMediaOptions(preferredMediaSelection)

        NotificationCenter.default.post(name: .AssetDownloadStateChanged, object: nil, userInfo: userInfo)
    }

    func assetForStream(withName name: String) -> Asset? {
        var asset: Asset?

        for (_, assetValue) in activeDownloadsMap where name == assetValue.stream.name {
            asset = assetValue
            break
        }

        return asset
    }

    struct MyError: Error { }


    func localAssetForStream(withName name: String) -> Asset? {
        guard let localFileLocation = UserDefaults.standard.value(forKey: name) as? Data else { return nil }

        do {
            var bookmarkDataIsStale = false
            let url = try URL(resolvingBookmarkData: localFileLocation, bookmarkDataIsStale: &bookmarkDataIsStale)
            if bookmarkDataIsStale {
                print("Bookmark data is stale!")
                throw MyError()
            }

            let localUrlAsset = AVURLAsset(url: url)
            let stream = StreamListManager.shared.stream(withName: name)
            let urlAsset = AVURLAsset(url: URL(string: stream.playlistURL)!)

            return Asset(urlAsset: urlAsset, stream: stream, localFileUrlAsset: localUrlAsset)
        } catch {
            UserDefaults.standard.removeObject(forKey: name)
            print("Failed to create URL from bookmark with error: \(error)")
            return nil
        }
    }

    func downloadState(for asset: Asset) -> Asset.DownloadState {
        if let localFileLocation = localAssetForStream(withName: asset.stream.name)?.localFileUrlAsset?.url {
            if FileManager.default.fileExists(atPath: localFileLocation.path) {
                return .downloaded
            }
        }

        for (_, assetValue) in activeDownloadsMap where asset.stream.name == assetValue.stream.name {
            return .downloading
        }

        return .notDownloaded
    }

    func deleteAsset(_ asset: Asset) {
        do {
            if let localFileLocation = localAssetForStream(withName: asset.stream.name)?.localFileUrlAsset?.url {
                try FileManager.default.removeItem(at: localFileLocation)

                UserDefaults.standard.removeObject(forKey: asset.stream.name)

                var userInfo = [String: Any]()
                userInfo[Asset.Keys.name] = asset.stream.name
                userInfo[Asset.Keys.downloadState] = Asset.DownloadState.notDownloaded.rawValue

                NotificationCenter.default.post(name: .AssetDownloadStateChanged, object: nil, userInfo: userInfo)
            }
        } catch {
            logger.error("An error occured deleting the file: \(error)")
        }
    }

    func cancelDownload(for asset: Asset) {
        var task: AVAssetDownloadTask?

        for (taskKey, assetVal) in activeDownloadsMap where asset == assetVal {
            task = taskKey
            break
        }

        task?.cancel()
    }
}

func displayNamesForSelectedMediaOptions(_ mediaSelection: AVMediaSelection) async -> String {

    var displayNames = ""

    guard let asset = mediaSelection.asset else {
        return displayNames
    }

    guard let characteristics = try? await asset.load(.availableMediaCharacteristicsWithMediaSelectionOptions) else {
        return displayNames
    }
    
    for mediaCharacteristic in characteristics {
        guard let mediaSelectionGroup = try? await asset.loadMediaSelectionGroup(for: mediaCharacteristic),
            let option = mediaSelection.selectedMediaOption(in: mediaSelectionGroup) else { continue }

        if displayNames.isEmpty {
            displayNames += " " + option.displayName
        } else {
            displayNames += ", " + option.displayName
        }
    }

    return displayNames
}

extension AssetPersistenceManager: AVAssetDownloadDelegate {

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let userDefaults = UserDefaults.standard

        guard let task = task as? AVAssetDownloadTask,
            let asset = activeDownloadsMap.removeValue(forKey: task) else { return }

        guard let downloadURL = willDownloadToUrlMap.removeValue(forKey: task) else { return }

        var userInfo = [String: Any]()
        userInfo[Asset.Keys.name] = asset.stream.name

        if let error = error as NSError? {
            switch (error.domain, error.code) {
            case (NSURLErrorDomain, NSURLErrorCancelled):
                guard let localFileLocation = localAssetForStream(withName: asset.stream.name)?.localFileUrlAsset?.url else { return }

                do {
                    try FileManager.default.removeItem(at: localFileLocation)
                    userDefaults.removeObject(forKey: asset.stream.name)
                } catch {
                    logger.error("An error occured trying to delete the contents on disk for \(asset.stream.name): \(error)")
                }

                userInfo[Asset.Keys.downloadState] = Asset.DownloadState.notDownloaded.rawValue

            default:
                fatalError("An unexpected error occured \(error.domain)")
            }
        } else {
            do {
                let bookmark = try downloadURL.bookmarkData()
                userDefaults.set(bookmark, forKey: asset.stream.name)
            } catch {
                logger.error("Failed to create bookmarkData for download URL.")
            }

            userInfo[Asset.Keys.downloadState] = Asset.DownloadState.downloaded.rawValue
            userInfo[Asset.Keys.downloadSelectionDisplayName] = ""
            userInfo[Asset.Keys.downloadDestinationUrl] = downloadURL
        }

        NotificationCenter.default.post(name: .AssetDownloadStateChanged, object: nil, userInfo: userInfo)
    }

    func urlSession(_ session: URLSession, assetDownloadTask avAssetDownloadTask: AVAssetDownloadTask, willDownloadTo location: URL) {
        willDownloadToUrlMap[avAssetDownloadTask] = location
    }
    
    func urlSession(_ session: URLSession, assetDownloadTask avAssetDownloadTask: AVAssetDownloadTask, willDownloadVariants variants: [AVAssetVariant]) {
        let variantsDescription = variants.map { variant -> String in
            guard let peakBitRate = variant.peakBitRate else { return "N/A" }
            guard let resolution = variant.videoAttributes?.presentationSize else { return "N/A" }
            return "peakBitRate=\(peakBitRate) & resolution=\(Int(resolution.width)) x \(Int(resolution.height))"
        }.joined(separator: ", ")
        
        logger.info("Will download the following variants: \(variantsDescription)")
    }
}

extension Notification.Name {
    static let AssetDownloadProgress = Notification.Name(rawValue: "AssetDownloadProgressNotification")
    static let AssetDownloadStateChanged = Notification.Name(rawValue: "AssetDownloadStateChangedNotification")
    static let AssetPersistenceManagerDidRestoreState = Notification.Name(rawValue: "AssetPersistenceManagerDidRestoreStateNotification")
}
