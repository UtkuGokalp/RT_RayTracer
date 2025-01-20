float2 TexCoords(in float3 position)
{
    return position.xz;
}

inline RayDesc GenerateCameraRay(uint2 index, in float3 cameraPosition, in float4x4 projectionToWorld)
{
    float2 xy = index + 0.5f; // center in the middle of the pixel.
    float2 screenPos = xy / DispatchRaysDimensions().xy * 2.0 - 1.0;

    // Invert Y for DirectX-style coordinates.
    screenPos.y = -screenPos.y;

    // Unproject the pixel coordinate into a world positon.
    float4 world = mul(float4(screenPos, 0, 1), projectionToWorld);
    world.xyz /= world.w;

    RayDesc ray;
    ray.Origin = cameraPosition;
    ray.Direction = normalize(world.xyz - ray.Origin);
    ray.TMin = 0.01;
    ray.TMax = 100000;
    return ray;
}

void CalculateRayDifferentials(out float2 ddx_uv, out float2 ddy_uv, in float2 uv, in float3 hitPosition, in float3 surfaceNormal, in float3 cameraPosition, in float4x4 projectionToWorld)
{
    // Compute ray differentials by intersecting the tangent plane to the  surface.
    RayDesc ddx = GenerateCameraRay(DispatchRaysIndex().xy + uint2(1, 0), cameraPosition, projectionToWorld);
    RayDesc ddy = GenerateCameraRay(DispatchRaysIndex().xy + uint2(0, 1), cameraPosition, projectionToWorld);

    // Compute ray differentials.
    float3 ddx_pos = ddx.Origin - ddx.Direction * dot(ddx.Origin - hitPosition, surfaceNormal) / dot(ddx.Direction, surfaceNormal);
    float3 ddy_pos = ddy.Origin - ddy.Direction * dot(ddy.Origin - hitPosition, surfaceNormal) / dot(ddy.Direction, surfaceNormal);

    // Calculate texture sampling footprint.
    ddx_uv = TexCoords(ddx_pos) - uv;
    ddy_uv = TexCoords(ddy_pos) - uv;
}

float CheckersTextureBoxFilter(in float2 uv, in float2 dpdx, in float2 dpdy, in uint ratio)
{
    float2 w = max(abs(dpdx), abs(dpdy));   // Filter kernel
    float2 a = uv + 0.5*w;
    float2 b = uv - 0.5*w;

    // Analytical integral (box filter).
    float2 i = (floor(a) + min(frac(a)*ratio, 1.0) -
        floor(b) - min(frac(b)*ratio, 1.0)) / (ratio*w);
    return (1.0 - i.x)*(1.0 - i.y);
}

// Return analytically integrated checkerboard texture (box filter).
float AnalyticalCheckersTexture(in float3 hitPosition, in float3 surfaceNormal, in float3 cameraPosition, in float4x4 projectionToWorld)
{
    float2 ddx_uv;
    float2 ddy_uv;
    float2 uv = TexCoords(hitPosition);

    CalculateRayDifferentials(ddx_uv, ddy_uv, uv, hitPosition, surfaceNormal, cameraPosition, projectionToWorld);
    return CheckersTextureBoxFilter(uv, ddx_uv, ddy_uv, 50);
}