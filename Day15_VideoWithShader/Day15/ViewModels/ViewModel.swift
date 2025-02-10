import RealityKit
import Observation
import RealityKitContent
import AVFoundation
import MetalKit

let context = CIContext()

@Observable
class ViewModel {

    var keyColor: CGColor = .init(red: 67/255, green: 133/255, blue: 74/255, alpha: 1.0)
    var hueRange: Float = 0.06
    var saturateRange: Float = 0.5
    var valueRange: Float = 0.48

    private var rootEntity: Entity!
    private var videoRootEntity: Entity!

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
    func setup(rootEntity: Entity) async {
        self.rootEntity = rootEntity

        videoRootEntity = Entity()
        videoRootEntity.name = "video"
        videoRootEntity.position = [-0.5, 1.3, -1.0]
        rootEntity.addChild(videoRootEntity)

        textureResource = try! await TextureResource(named: "placeholder")

        dynamicMaterial = try! await ShaderGraphMaterial(named: "/Root/DynamicMaterial", from: "Immersive.usda", in: realityKitContentBundle)
        try! dynamicMaterial!.setParameter(name: "ImageInput", value: .textureResource(textureResource!))
        try! dynamicMaterial!.setParameter(name: "KeyColor", value: .color(keyColor))
        try! dynamicMaterial!.setParameter(name: "HueRange", value: .float(hueRange))
        try! dynamicMaterial!.setParameter(name: "SaturateRange", value: .float(saturateRange))
        try! dynamicMaterial!.setParameter(name: "ValueRange", value: .float(valueRange))

        videoRootEntity.components.set(ModelComponent(mesh: .generatePlane(width: 0.8, height: 1.06), materials: [dynamicMaterial!]))
        videoRootEntity.components.set(InputTargetComponent())
        videoRootEntity.components.set(CollisionComponent(shapes: [.generateBox(width: 0.8, height: 1.06, depth: 0.01)]))

        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, mtlDevice, nil, &textureCache)

        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkUpdated(link:)))
        displayLink!.preferredFramesPerSecond = 60
        displayLink!.add(to: .main, forMode: .default)

        let urlPath = Bundle.main.path(forResource: "video001", ofType: "mov")!
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

    func onChange(hue: Float?, saturate: Float?, value: Float?) {
        guard var modelComponent = videoRootEntity.components[ModelComponent.self],
              var dynamicMaterial = dynamicMaterial
        else { return }

        if let hue {
            try! dynamicMaterial.setParameter(name: "HueRange", value: .float(hue))
        }
        if let saturate {
            try! dynamicMaterial.setParameter(name: "SaturateRange", value: .float(saturate))
        }
        if let value {
            try! dynamicMaterial.setParameter(name: "ValueRange", value: .float(value))
        }

        modelComponent.materials = [dynamicMaterial]
        videoRootEntity.components.set(modelComponent)
    }

    func replay() {
        guard let player else { return }
        player.seek(to: .zero)
        player.play()
    }

    private func getCurrentFrameTexture() -> MTLTexture? {
        guard let videoPlayerOutput = videoPlayerOutput, let videoPlayerItem = videoPlayerItem else { return nil }
        guard let textureCache else { return nil }

        let currentTime = videoPlayerItem.currentTime()
        var itemTimeForDisplay = CMTime.zero
        guard let buffer = videoPlayerOutput.copyPixelBuffer(forItemTime: currentTime, itemTimeForDisplay: &itemTimeForDisplay) else { return nil }

        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        let planeCount = CVPixelBufferGetPlaneCount(buffer)
        var textureRef: CVMetalTexture?

        let result = CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            textureCache,
            buffer,
            nil,
            .bgra8Unorm_srgb,
            width,
            height,
            planeCount,
            &textureRef
        )

        guard result == kCVReturnSuccess,
              let unwrappedTextureRef = textureRef
        else { return nil }

        return CVMetalTextureGetTexture(unwrappedTextureRef)
    }

    @objc
    private func displayLinkUpdated(link: CADisplayLink) {
        guard let textureResource else { return }
        guard let cgImage = getCurrentFrameTexture()?.cgImage else { return }
        try? textureResource.replace(withImage: cgImage, options: TextureResource.CreateOptions(semantic: nil))
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
