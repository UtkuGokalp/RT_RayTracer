#include "Common.hlsl"

// Raytracing output texture, accessed as a UAV
// Unordered Access Views are for being able to read and write data to a resource
// The read and write can be simultaneously done thanks to the underlying atomic operations
// It also enables concurrent reads/writes through different threads.
// This enables the updated texture to be re-used by the graphics pipeline for some other purpose.
// u in u0 declares a UAV
RWTexture2D<float4> gOutput : register(u0);

// Raytracing acceleration structure, accessed as a SRV
// Shader resource views are for readonly uses of a given resource.
// These are generally used for wrapping textures in a format to which the shader can access.
// t in t0 declares an SRV
RaytracingAccelerationStructure SceneBVH : register(t0);

// In order to declare a constant buffer (CBV), the letter c is used

[shader("raygeneration")]
void RayGen()
{
    // Initialize the ray payload
    HitInfo payload;
    payload.colorAndDistance = float4(0.9, 0.6, 0.2, 1);

    // Get the location within the dispatched 2D grid of work items
    // (often maps to pixels, so this could represent a pixel coordinate).
    uint2 launchIndex = DispatchRaysIndex();
    gOutput[launchIndex] = float4(payload.colorAndDistance.rgb, 1.f);
}
