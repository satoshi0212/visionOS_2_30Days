import RealityKit
import Foundation
import simd

struct CurveExtruder {
    private var lowLevelMesh: LowLevelMesh?

    /// The shape to extrude.
    ///
    /// Assumed to be centered about the origin.
    let shape: [SIMD2<Float>]

    /// Topology of each triangle strip in the extruded solid.
    ///
    /// The topology is static and determined by the number of
    /// points on the shape.
    /// This topology is meant to be used with `MTLPrimitiveType.triangleStrip`.
    let topology: [UInt32]

    private(set) var samples: [CurveSample] = []

    /// The number of samples in `samples` that have been meshed in `lowLevelMesh`.
    private var cachedSampleCount: Int = 0

    /// The number of samples for which `lowLevelMesh` has capacity.
    private var sampleCapacity: Int {
        let vertexCapacity = lowLevelMesh?.vertexCapacity ?? 0
        let indexCapacity = lowLevelMesh?.indexCapacity ?? 0

        // Each sample adds `shape.count` vertices.
        let sampleVertexCapacity = vertexCapacity / shape.count

        // Each segment between two samples adds `topology.count` indices.
        let sampleIndexCapacity = indexCapacity / topology.count + 1

        return min(sampleVertexCapacity, sampleIndexCapacity)
    }

    /// If necessary, reallocates `self.lowLevelMesh` so that the buffer size is suitable to be filled with
    /// all of the curve samples in `self.samples`.
    ///
    /// - Returns: True if a `LowLevelMesh` was reallocated. In this case, callers must reapply the `LowLevelMesh`
    ///      to their RealityKit `MeshResource`.
    private mutating func reallocateMeshIfNeeded() throws -> Bool {
        guard samples.count > sampleCapacity else {
            // No need to reallocate if `sampleCapacity` is small enough.
            return false
        }

        // Double the sample capacity each time a reallocation is needed.
        var newSampleCapacity = max(sampleCapacity, 1024)
        while newSampleCapacity < samples.count {
            newSampleCapacity *= 2
        }

        // `shape` is instantiated at each sample.
        let newVertexCapacity = newSampleCapacity * shape.count

        // Each segment between two samples adds a triangle fan, which has `topology.count` indices.
        let triangleFanCapacity = newSampleCapacity - 1
        let newIndexCapacity = triangleFanCapacity * topology.count

        let newMesh = try Self.makeLowLevelMesh(vertexCapacity: newVertexCapacity, indexCapacity: newIndexCapacity)

        // The topology is fixed, so you only need to write to the index buffer once.
        newMesh.withUnsafeMutableIndices { buffer in
            // Fill the index buffer with `triangleFanCapacity` copies of the array `topology` offset for each sample.
            let typedBuffer = buffer.bindMemory(to: UInt32.self)
            for fanIndex in 0..<triangleFanCapacity {
                for vertexIndex in 0..<topology.count {
                    let bufferIndex = vertexIndex + topology.count * fanIndex
                    if topology[vertexIndex] == UInt32.max {
                        typedBuffer[bufferIndex] = UInt32.max
                    } else {
                        typedBuffer[bufferIndex] = topology[vertexIndex] + UInt32(shape.count * fanIndex)
                    }
                }
            }
        }

        if let lowLevelMesh {
            // Copy the vertex buffer from the old mesh to the new one.
            lowLevelMesh.withUnsafeBytes(bufferIndex: 0) { oldBuffer in
                newMesh.withUnsafeMutableBytes(bufferIndex: 0) { newBuffer in
                    newBuffer.copyMemory(from: oldBuffer)
                }
            }

            // Copy the parts array from the old mesh to the new one.
            newMesh.parts = lowLevelMesh.parts
        }

        lowLevelMesh = newMesh

        return true
    }

    /// Generates a `LowLevelMesh` suitable to be populated by `CurveExtruder` with the specified vertex and index capacity.
    private static func makeLowLevelMesh(vertexCapacity: Int, indexCapacity: Int) throws -> LowLevelMesh {
        var descriptor = LowLevelMesh.Descriptor()

        descriptor.vertexCapacity = vertexCapacity
        descriptor.indexCapacity = indexCapacity
        descriptor.vertexAttributes = SolidBrushVertex.vertexAttributes

        let stride = MemoryLayout<SolidBrushVertex>.stride
        descriptor.vertexLayouts = [.init(bufferIndex: 0, bufferStride: stride)]

        return try LowLevelMesh(descriptor: descriptor)
    }

    /// Initializes the `CurveExtruder` with the shape to sweep along the curve.
    ///
    /// - Parameters:
    ///   - shape: The 2D shape to sweep along the curve.
    init(shape: [SIMD2<Float>]) {
        self.shape = shape

        // Compute topology //
        // Triangle fan lists each vertex in `shape` once for each ring, except for vertex `0` of `shape` which
        // is listed twice. Plus one extra index for the end-index (0xFFFFFFFF).
        let indexCountPerFan = 2 * (shape.count + 1) + 1

        var topology: [UInt32] = []
        topology.reserveCapacity(indexCountPerFan)

        // Build triangle fan.
        for vertexIndex in shape.indices.reversed() {
            topology.append(UInt32(vertexIndex))
            topology.append(UInt32(shape.count + vertexIndex))
        }

        // Wrap around to the first vertex.
        topology.append(UInt32(shape.count - 1))
        topology.append(UInt32(2 * shape.count - 1))

        // Add end-index.
        topology.append(UInt32.max)
        assert(topology.count == indexCountPerFan)

        self.topology = topology
    }

    /// Appends `samples` to the list of 3D curve samples used to generate the mesh.
    mutating func append<S: Sequence>(samples: S) where S.Element == CurveSample {
        self.samples.append(contentsOf: samples)
    }

    /// Removes samples from the end of the 3D curve which were previously added with `append`.
    mutating func removeLast(sampleCount: Int) {
        samples.removeLast(sampleCount)
        cachedSampleCount = min(cachedSampleCount, max(samples.count - 1, 0))
    }

    /// Updates the `LowLevelMesh` which is maintained by this CurveExtruder.
    ///
    /// This applies pending calls to `append` or `removeLast`
    /// to the `LowLevelMesh`.
    ///
    /// - Returns: A `LowLevelMesh` if a new mesh had to be allocated
    ///     (that is, the number of samples exceeded the capacity of the previous mesh).
    ///     Returns `nil` if no new `LowLevelMesh` was allocated.
    @MainActor
    mutating func update() throws -> LowLevelMesh? {
        let didReallocate = try reallocateMeshIfNeeded()

        if cachedSampleCount != samples.count, let lowLevelMesh {
            if cachedSampleCount < samples.count {
                lowLevelMesh.withUnsafeMutableBytes(bufferIndex: 0) { rawBuffer in
                    let vertexBuffer = rawBuffer.bindMemory(to: SolidBrushVertex.self)
                    updateVertexBuffer(vertexBuffer)
                }
            }

            lowLevelMesh.parts.removeAll()
            if samples.count > 1 {
                let triangleFanCount = samples.count - 1

                // Use the bounding box to occlude parts of your mesh when it isn't visible.
                // The drawing app should display all brush strokes, so use an arbitrarily large bounds.
                let bounds = BoundingBox(min: [-100, -100, -100], max: [100, 100, 100])
                let part = LowLevelMesh.Part(indexOffset: 0,
                                             indexCount: triangleFanCount * topology.count,
                                             topology: .triangleStrip,
                                             materialIndex: 0,
                                             bounds: bounds)
                lowLevelMesh.parts.append(part)
            }
        }

        return didReallocate ? lowLevelMesh : nil
    }

    /// Internal routine to update the vertex buffer of the underlying `LowLevelMesh` to include new changes to `samples`.
    private mutating func updateVertexBuffer(_ vertexBuffer: UnsafeMutableBufferPointer<SolidBrushVertex>) {
        guard cachedSampleCount < samples.count else { return }

        for sampleIndex in cachedSampleCount..<samples.count {
            let sample = samples[sampleIndex]
            let frame = sample.rotationFrame

            let previousPoint = (sampleIndex == 0) ? sample : samples[sampleIndex - 1]
            let nextPoint = (sampleIndex == samples.count - 1) ? sample : samples[sampleIndex + 1]

            let deltaRadius = nextPoint.radius - previousPoint.radius
            let deltaPosition = distance(nextPoint.position, previousPoint.position)
            let angle = atan2f(deltaRadius, deltaPosition)

            for shapeVertexIndex in 0..<shape.count {
                var vertex = SolidBrushVertex()

                // Use the rotation frame of `sample` to compute the 3D position of this vertex.
                let position2d = shape[shapeVertexIndex] * sample.point.radius
                let position3d = frame * SIMD3<Float>(position2d, 0) + sample.point.position

                // To compute the 3D bitangent, take the tangent of the shape in 2D
                // and orient with respect to the rotation frame of `sample`.
                let nextShapeIndex = (shapeVertexIndex + 1) % shape.count
                let prevShapeIndex = (shapeVertexIndex + shape.count - 1) % shape.count
                let bitangent2d = simd_normalize(shape[nextShapeIndex] - shape[prevShapeIndex])
                let bitangent3d = frame * SIMD3<Float>(bitangent2d, 0)

                // The normal is bent depending on the change in radius between adjacent samples:
                // - If the change in radius is zero, then the normal is perpendicular
                //   to `sample.tangent` and also perpendicular to `bitangent3d`.
                //   `frameNormal` is this value.
                // - As the change in radius approaches infinity, the normal approaches `sample.tangent`.
                //
                // These two extremes are blended based on the angle between the two radii (`angle`).
                // The first case above is when the angle is 0, the second case is when the angle is pi/2.
                let frameNormal = frame * SIMD3<Float>(bitangent2d.y, -bitangent2d.x, 0)
                let frameNormalToTangent = simd_quatf(from: frameNormal, to: sample.tangent)
                let frameNormalToNormal3d = simd_slerp(simd_quatf(ix: 0, iy: 0, iz: 0, r: 1),
                                                       frameNormalToTangent,
                                                       -angle / (Float.pi / 2))
                let normal3d = frameNormalToNormal3d.act(frameNormal)

                // Assign vertex attributes based on the values computed above.
                vertex.position = position3d.packed3
                vertex.bitangent = bitangent3d.packed3
                vertex.normal = normal3d.packed3
                vertex.color = SIMD3<Float16>(sample.point.color).packed3
                vertex.materialProperties = SIMD2<Float>(sample.point.roughness, sample.point.metallic)
                vertex.curveDistance = sample.curveDistance

                // Verify: This mesh generator should never output NaN.
                assert(any(isnan(vertex.position.simd3) .== 0))
                assert(any(isnan(vertex.bitangent.simd3) .== 0))
                assert(any(isnan(vertex.normal.simd3) .== 0))

                vertexBuffer[sampleIndex * shape.count + shapeVertexIndex] = vertex
            }
        }
        cachedSampleCount = samples.count
    }
}
