import RealityKit

extension SolidBrushVertex {
    static var vertexAttributes: [LowLevelMesh.Attribute] {
        typealias Attribute = LowLevelMesh.Attribute

        return [
            Attribute(semantic: .position, format: .float3, layoutIndex: 0,
                      offset: MemoryLayout.offset(of: \Self.position)!),

            Attribute(semantic: .normal, format: .float3, layoutIndex: 0,
                      offset: MemoryLayout.offset(of: \Self.normal)!),

            Attribute(semantic: .bitangent, format: .float3, layoutIndex: 0,
                      offset: MemoryLayout.offset(of: \Self.bitangent)!),

            Attribute(semantic: .color, format: .half3, layoutIndex: 0,
                      offset: MemoryLayout.offset(of: \Self.color)!),

            Attribute(semantic: .uv1, format: .float, layoutIndex: 0,
                      offset: MemoryLayout.offset(of: \Self.curveDistance)!),

            Attribute(semantic: .uv3, format: .float2, layoutIndex: 0,
                      offset: MemoryLayout.offset(of: \Self.materialProperties)!)
        ]
    }
}
