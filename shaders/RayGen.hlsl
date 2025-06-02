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

// In order to declare a constant buffer (CBV), the letter b is used

// #DXR Extra: Perspective Camera
cbuffer CameraParams : register(b0)
{
    float4x4 view;
    float4x4 projection;
    float4x4 viewInv;
    float4x4 projectionInv;
}

[shader("raygeneration")]
void RayGen()
{
    uint2 pixelCoordinates = DispatchRaysIndex().xy; //DispatchRaysIndex(): Gets the current location within the width, height, and depth obtained with the DispatchRaysDimensions() system value intrinsic.
    float2 windowDimensions = float2(DispatchRaysDimensions().xy); //DispatchRayDimensions(): The width, height and depth values from the D3D12_DISPATCH_RAYS_DESC structure specified in the originating DispatchRays() call on the CPU side.
    float2 d = ((pixelCoordinates.xy + 0.5f) / windowDimensions.xy) * 2.0f - 1.0f; //d is the floating point pixel coordinates, normalized on [0, 1] X [0, 1]

    float3 rayOriginRelativeToCamera = float3(0.0f, 0.0f, 0.0f); //Put the ray origin at the camera's position.
    float3 rayOrigin = mul(viewInv, float4(rayOriginRelativeToCamera, 1.0f)).xyz; //Convert the origin from camera space to world space
    float3 rayDirection = mul(projectionInv, float4(d.x, -d.y, 1.0f, 1.0f)).xyz; //y component is inverted in order to match the image indexing convention of DirectX.
    rayDirection = mul(viewInv, float4(rayDirection, 0.0f)).xyz;
    HitInfo payload;
    payload.color = float3(1.0f, 1.0f, 1.0f); //Initial color of the light is white
    CastDefaultRay(SceneBVH, rayOrigin, rayDirection, payload);
    gOutput[pixelCoordinates] = float4(payload.color, 1.0f);
}
