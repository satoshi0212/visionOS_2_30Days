import RealityKit
import Observation
import RealityKitContent
import AVFoundation
import MetalKit

private let context = CIContext()

@Observable
class ViewModel {

    var rootEntity = Entity()

    private let mtlDevice: MTLDevice = MTLCreateSystemDefaultDevice()!

    private var displayLink: CADisplayLink?
    private var player: AVPlayer?
    private var textureResource: TextureResource?

    private var videoPlayerItem: AVPlayerItem?
    private var videoPlayerOutput: AVPlayerItemVideoOutput?
    private var textureCache: CVMetalTextureCache?

    private var dynamicMaterial: ShaderGraphMaterial?

    @ObservationIgnored
    private lazy var textureLoader = MTKTextureLoader(device: mtlDevice)

    @MainActor
    func setup() async {
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, mtlDevice, nil, &textureCache)

        let entity = Entity()
        entity.name = "video"
        entity.position = [0.0, 1.3, -1.0]
        rootEntity.addChild(entity)

        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkUpdated(link:)))
        displayLink!.preferredFramesPerSecond = 60
        displayLink!.add(to: .main, forMode: .default)

        let resource = try! await TextureResource(named: "placeholder")
        self.textureResource = resource

        dynamicMaterial = try! await ShaderGraphMaterial(named: "/Root/DynamicMaterial", from: "ImageParameter.usda", in: realityKitContentBundle)
        try! dynamicMaterial!.setParameter(name: "ImageInput", value: .textureResource(self.textureResource!))
        entity.components.set(ModelComponent(mesh: .generatePlane(width: 0.8, height: 0.45), materials: [dynamicMaterial!]))

        let urlPath = Bundle.main.path(forResource: "video001", ofType: "mp4")!
        let url = URL(fileURLWithPath: urlPath)
        let videoAsset = AVURLAsset(url: url, options: [:])
        videoPlayerItem = AVPlayerItem(asset: videoAsset)

        let settings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferMetalCompatibilityKey as String: true
        ]
        videoPlayerOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: settings)
        videoPlayerItem?.add(videoPlayerOutput!)

        player = AVPlayer(playerItem: videoPlayerItem)
        player!.play()
    }

    func exit() {
        displayLink?.invalidate()
        player?.pause()
    }

    private func getCurrentFrameTexture() -> MTLTexture? {
        guard let videoPlayerOutput = videoPlayerOutput, let videoPlayerItem = videoPlayerItem else { return nil }
        let currentTime = videoPlayerItem.currentTime()
        
        //print(currentTime)

        var itemTimeForDisplay = CMTime.zero
        guard let buffer = videoPlayerOutput.copyPixelBuffer(forItemTime: currentTime, itemTimeForDisplay: &itemTimeForDisplay) else { return nil }

        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        let planeCount = CVPixelBufferGetPlaneCount(buffer)
        var textureRef: CVMetalTexture?

        let result = CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            textureCache!,
            buffer,
            nil,
            .bgra8Unorm_srgb,
            width,
            height,
            planeCount,
            &textureRef
        )

        guard result == kCVReturnSuccess, let unwrappedTextureRef = textureRef else {
            return nil
        }

        let texture = CVMetalTextureGetTexture(unwrappedTextureRef)
        return texture
    }

    @objc private func displayLinkUpdated(link: CADisplayLink) {
        guard let textureResource else { return }
        if let cgImage = getCurrentFrameTexture()?.cgImage {
            try? textureResource.replace(withImage: cgImage, options: TextureResource.CreateOptions(semantic: nil))
        }
    }
}

extension MTLTexture {
    var cgImage: CGImage? {
        guard let image = CIImage(mtlTexture: self, options: nil) else { return nil }
        let flipped = image.transformed(by: CGAffineTransform(scaleX: 1, y: -1))
        return context.createCGImage(flipped,
                                     from: flipped.extent,
                                     format: CIFormat.BGRA8,
                                     colorSpace: CGColorSpace(name: CGColorSpace.linearDisplayP3)!)
    }
}
