// Hit information, aka ray payload
// This sample only carries a shading color and hit distance.
// Note that the payload should be kept as small as possible,
// and that its size must be declared in the corresponding
// D3D12_RAYTRACING_SHADER_CONFIG pipeline subobjet.
struct HitInfo
{
    bool didHit;
    float3 color;
    float3 hitWorldPoint;
    float3 hitWorldNormal;
    float3 rayWorldDirection;
};
