import RealityKit
import Foundation
import CoreImage

extension EnvironmentResource {

    convenience init(fromImage url: URL) async throws {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            fatalError("Failed to load image from \(url)")
        }

        guard let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            fatalError("Failed to load image from \(url)")
        }

        try await self.init(equirectangular: image)
    }
}
