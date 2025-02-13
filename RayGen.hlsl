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

float3 RandomHemisphereDirection(float3 normal, float3 viewDir, float roughness, uint seed)
{
    // Compute perfect reflection direction
    float3 perfectReflection = reflect(-viewDir, normal);

    // Generate random numbers using a simple hash function
    seed = (seed * 1664525u + 1013904223u);
    float u1 = float(seed & 0xFFFFFF) / 16777216.0; // Random value in [0,1]
    
    seed = (seed * 1664525u + 1013904223u);
    float u2 = float(seed & 0xFFFFFF) / 16777216.0; // Another random value in [0,1]

    // Convert random values to spherical coordinates
    float theta = acos(pow(1.0 - u1, 1.0 / (1.0 + roughness * roughness))); // Roughness controls spread
    float phi = 2.0 * 3.1415926535 * u2;

    // Convert spherical to Cartesian coordinates
    float3 localDir = float3(sin(theta) * cos(phi), sin(theta) * sin(phi), cos(theta));

    // Build an orthonormal basis from the normal
    float3 tangent = normalize(cross(normal, float3(0.0, 1.0, 0.0)));
    if (abs(normal.y) > 0.99) tangent = normalize(cross(normal, float3(1.0, 0.0, 0.0)));
    float3 bitangent = cross(normal, tangent);

    // Transform localDir from tangent space to world space
    float3 randomDir = normalize(localDir.x * tangent + localDir.y * bitangent + localDir.z * normal);

    // Blend between perfect reflection and random hemisphere sample
    return normalize(lerp(perfectReflection, randomDir, roughness));
}

[shader("raygeneration")]
void RayGen()
{
    const int numSamples = 16; // Number of indirect rays per bounce

    HitInfo payload;
    payload.color = float3(1.0f, 1.0f, 1.0f);
    float rayContributionToColor = 1.0f;
    uint2 launchIndex = DispatchRaysIndex().xy;
    float2 dims = float2(DispatchRaysDimensions().xy);
    float2 d = ((launchIndex.xy + 0.5f) / dims.xy) * 2.0f - 1.0f;

    float3 accumulatedColor = float3(0.0f, 0.0f, 0.0f);
    float3 finalHitPoint = float3(0.0f, 0.0f, 0.0f);
    bool missed = false;
    
    for (int i = 0; i < numSamples; i++)
    {
        HitInfo samplePayload;
        samplePayload.color = float3(1.0f, 1.0f, 1.0f);
        float sampleContribution = 1.0f;

        for (int i = 0; i < 3; i++) // Bounces
        {
            RayDesc ray;
            ray.Origin = mul(viewInv, float4(0, 0, 0, 1));
            float4 target;
            if (i == 0) // Primary ray
            {
                target = mul(projectionInv, float4(d.x, -d.y, 1, 1));
            }
            else
            {
                uint seed = (launchIndex.x * 73856093u) ^ (launchIndex.y * 19349663u);
                float3 viewDir = normalize(samplePayload.rayWorldDirection);
                float3 reflectionDirection = RandomHemisphereDirection(samplePayload.hitWorldNormal, viewDir, 0.5f, seed);
                target.xyz = reflectionDirection.xyz;
                target = mul(projectionInv, float4(target.xyz, 1.0f));
            }

            samplePayload.didHit = true;
            ray.Direction = mul(viewInv, float4(target.xyz, 0));
            ray.TMin = 0;
            ray.TMax = 100000;
            TraceRay(SceneBVH, RAY_FLAG_NONE, 0xFF, 0, 0, 0, ray, samplePayload);
            finalHitPoint = samplePayload.hitWorldPoint;

            if (!samplePayload.didHit)
            {
                samplePayload.color *= sampleContribution;
                sampleContribution *= 0.8f;
                missed = true;
                break;
            }
        }
        accumulatedColor += samplePayload.color;
        if (missed) break;
    }
    float3 currentColor = missed ? accumulatedColor : accumulatedColor / numSamples;
    
    gOutput[launchIndex] = float4(currentColor, 1.0f);
}

/*
//2nd version
[shader("raygeneration")]
void RayGen()
{
    const int numSamples = 16; // Number of indirect rays per bounce (adjust as needed)

    HitInfo payload;
    payload.color = float3(1.0f, 1.0f, 1.0f);
    float rayContributionToColor = 1.0f;
    uint2 launchIndex = DispatchRaysIndex().xy;
    float2 dims = float2(DispatchRaysDimensions().xy);
    float2 d = ((launchIndex.xy + 0.5f) / dims.xy) * 2.0f - 1.0f;

    float aspectRatio = dims.x / dims.y;
    float3 accumulatedColor = float3(0.0f, 0.0f, 0.0f); // Stores the final averaged color
    bool missed = false;
    for (int sample = 0; sample < numSamples; sample++)
    {
        HitInfo samplePayload;
        samplePayload.color = float3(1.0f, 1.0f, 1.0f);
        float sampleContribution = 1.0f;

        for (int i = 0; i < 3; i++) // Bounces
        {
            RayDesc ray;
            ray.Origin = mul(viewInv, float4(0, 0, 0, 1));
            float4 target;
            if (i == 0) // Primary ray
            {
                target = mul(projectionInv, float4(d.x, -d.y, 1, 1)); // Invert Y to match DX image coordinates
            }
            else
            {
                // Unique seed per pixel, sample, and bounce
                //uint seed = (launchIndex.x * 73856093u) ^ (launchIndex.y * 19349663u) ^ (sample * 2654435761u) ^ (i * 83492791u);
                uint seed = (launchIndex.x * 73856093u) ^ (launchIndex.y * 19349663u); // Stable per-pixel seed

                float3 viewDir = normalize(samplePayload.worldDirection);
                float3 reflectionDirection = RandomHemisphereDirection(samplePayload.hitWorldNormal, viewDir, 0.5f, seed);
                target.xyz = reflectionDirection.xyz;
                target = mul(projectionInv, float4(target.xyz, 1.0f));
            }

            samplePayload.didHit = true; // Assume hit, gets reset in miss shader
            ray.Direction = mul(viewInv, float4(target.xyz, 0));
            ray.TMin = 0;
            ray.TMax = 100000;
            TraceRay(SceneBVH, RAY_FLAG_NONE, 0xFF, 0, 0, 0, ray, samplePayload);
            payload.color = min(payload.color, float3(2.0f, 2.0f, 2.0f)); // Cap max brightness
            if (!samplePayload.didHit)
            {
                samplePayload.color *= sampleContribution;
                sampleContribution *= 0.8f;
                missed = true;
                break;
            }
        }

        accumulatedColor += samplePayload.color; // Sum all samples
        if (missed)
        {
            break;
        }
    }
    
    // Average over all samples
    gOutput[launchIndex] = float4(missed ? accumulatedColor : accumulatedColor / numSamples, 1.0f);
    uint x = launchIndex.x;
    uint y = launchIndex.y;
    uint2 i0 = uint2(x-1, y);
    uint2 i1 = uint2(x+1, y);
    uint2 i2 = uint2(x, y-1);
    uint2 i3 = uint2(x, y+1);
    float3 blur = (gOutput[i0] + gOutput[i1] + gOutput[i2] + gOutput[i3]) / 4.0f;
    gOutput[launchIndex] = float4(lerp(gOutput[launchIndex], blur, 0.3f), 1.0f); // Smooth noisy areas
}
*/

/*
//First version
[shader("raygeneration")]
void RayGen()
{
    // Initialize the ray payload
    HitInfo payload;
    payload.color = float3(1.0f, 1.0f, 1.0f);
    float rayContributionToColor = 1.0f;

    // Get the location within the dispatched 2D grid of work items
    // (often maps to pixels, so this could represent a pixel coordinate).
    uint2 launchIndex = DispatchRaysIndex().xy;
    float2 dims = float2(DispatchRaysDimensions().xy);
    //d is the floating point pixel coordinates, normalized on [0, 1] X [0, 1]
    float2 d = ((launchIndex.xy + 0.5f) / dims.xy) * 2.0f - 1.0f;
    
    // #DXR Extra: Perspective Camera
    float aspectRatio = dims.x / dims.y;
    //Define a ray
    for (int i = 0; i < 3; i++)
    {
        RayDesc ray;
        ray.Origin = mul(viewInv, float4(0, 0, 0, 1));
        float4 target;
        if (i == 0) //If the first ray
        {
            target = mul(projectionInv, float4(d.x, -d.y, 1, 1)); //y component is inverted in order to match the image indexing convention of DirectX.
        }
        else
        {
            uint seed = (launchIndex.x * 73856093u) ^ (launchIndex.y * 19349663u) ^ (i * 83492791u);
            float3 viewDir = normalize(payload.worldDirection);
            float3 reflectionDirection = RandomHemisphereDirection(payload.hitWorldNormal, viewDir, 0.5f, seed);//normalize(reflect(viewDir, payload.hitWorldNormal));
            //reflectionDirection.y = -reflectionDirection.y;
            target.xyz = reflectionDirection.xyz;
            target = mul(projectionInv, float4(target.xyz, 1.0f)); //y component is inverted in order to match the image indexing convention of DirectX.
        }
        payload.didHit = true; //Assume ray hits, this needs to be set to false in the miss shader(s).
        ray.Direction = mul(viewInv, float4(target.xyz, 0));
        ray.TMin = 0; //Equivalent of the camera near clipping plane used in rasterization, 0 is valid for ray tracing.
        ray.TMax = 100000; //Max length of the ray, equivalent to the far clipping plane used in rasterization.
        TraceRay(
        // Parameter name: AccelerationStructure
        // Acceleration structure
        SceneBVH,
    
        // Parameter name: RayFlags
        // Flags can be used to specify the behavior upon hitting a surface
        RAY_FLAG_NONE,
    
        // Parameter name: InstanceInclusionMask
        // Instance inclusion mask, which can be used to mask out some geometry to this ray by
        // and-ing the mask with a geometry mask. The 0xFF flag then indicates no geometry will be
        // masked
        0xFF,
    
        // Parameter name: RayContributionToHitGroupIndex
        // Depending on the type of ray, a given object can have several hit groups attached
        // (ie. what to do when hitting to compute regular shading, and what to do when hitting
        // to compute shadows). Those hit groups are specified sequentially in the SBT, so the value
        // below indicates which offset (on 4 bits) to apply to the hit groups for this ray. In this
        // sample we only have one hit group per object, hence an offset of 0.
        0,
    
        // Parameter name: MultiplierForGeometryContributionToHitGroupIndex
        // The offsets in the SBT can be computed from the object ID, its instance ID, but also simply
        // by the order the objects have been pushed in the acceleration structure. This allows the
        // application to group shaders in the SBT in the same order as they are added in the AS, in
        // which case the value below represents the stride (4 bits representing the number of hit
        // groups) between two consecutive objects.
        0,
    
        // Parameter name: MissShaderIndex
        // Index of the miss shader to use in case several consecutive miss shaders are present in the
        // SBT. This allows to change the behavior of the program when no geometry have been hit, for
        // example one to return a sky color for regular rendering, and another returning a full
        // visibility value for shadow rays. This sample has only one miss shader, hence an index 0
        0,
    
        // Parameter name: Ray
        // Ray information to trace
        ray,
    
        // Parameter name: Payload
        // Payload associated to the ray, which will be used to communicate between the hit/miss
        // shaders and the raygen
        payload);
        if (!payload.didHit)
        {
            payload.color *= rayContributionToColor;
            rayContributionToColor *= 0.8f;
            break;
        }
    }
    gOutput[launchIndex] = float4(payload.color, 1.0f);
}
*/