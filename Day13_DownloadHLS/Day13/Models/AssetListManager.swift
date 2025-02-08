import Foundation
import AVFoundation

@Observable
class AssetListManager: NSObject {
    
    static let shared = AssetListManager()
    var assets = [Asset]()
    
    override private init() {
        super.init()
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(handleAssetPersistenceManagerDidRestoreState(_:)),
                                       name: .AssetPersistenceManagerDidRestoreState, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .AssetPersistenceManagerDidRestoreState, object: nil)
    }
    
    func asset(at index: Int) -> Asset {
        return assets[index]
    }
    
    @objc
    func handleAssetPersistenceManagerDidRestoreState(_ notification: Notification) {
        DispatchQueue.main.async {
            for stream in StreamListManager.shared.streams {
                if let asset = AssetPersistenceManager.shared.assetForStream(withName: stream.name) {
                    self.assets.append(asset)
                } else {
                    if let asset = AssetPersistenceManager.shared.localAssetForStream(withName: stream.name) {
                        self.assets.append(asset)
                    } else {
                        let urlAsset = AVURLAsset(url: URL(string: stream.playlistURL)!)
                        let asset = Asset(urlAsset: urlAsset, stream: stream)
                        self.assets.append(asset)
                    }
                }
            }
            
            NotificationCenter.default.post(name: .AssetListManagerDidLoad, object: self)
        }
    }
}

extension Notification.Name {
    static let AssetListManagerDidLoad = Notification.Name(rawValue: "AssetListManagerDidLoadNotification")
}
