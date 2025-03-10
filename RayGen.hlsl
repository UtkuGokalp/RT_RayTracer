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
/*
float3 RandomHemisphereDirection(inout uint seed, float3 normal, float3 origin)
{
    //Get a random point in a sphere first. This will ensured to be in a hemisphere later.
    //The code below generated a uniform distribution on a sphere. A normal distribution might be better, although probably not strictly necessary.
    const float HEMI_RADIUS = 1.0f;
    float phi = RandomFloatInRange(seed, 0.0f, 2.0f * PI);
    float costheta = RandomFloatInRange(seed, -1.0f, 1.0f);
    float u = RandomFloatInRange(seed, 0.0f, 1.0f);
    float theta = acos(costheta);
    float r = HEMI_RADIUS * pow(u, 1.0f / 3.0f); //cuberoot of u
    float x = r * sin(theta) * cos(phi);
    float y = r * sin(theta) * sin(phi);
    float z = r * cos(theta);
    float3 pointInSphere = float3(x, y, z);
    float3 direction = normalize(pointInSphere - origin);
    //Ensure that the point is in the hemisphere
    if (dot(normalize(normal), direction) < 0.0f)
    {
        direction = -direction;
    }
    return normalize(direction);
}

float3 TraceRayPath(float3 origin, float3 direction, uint maxBounceCount, float3 initialColor, inout uint seed)
{
    //TODO: This function should take the origin and direction of the primary ray and trace it's path including its bounces and other necessary stuff.
    //It should return the color of the ray at the end of the tracing proces

    float3 incomingLight = float3(0.0f, 0.0f, 0.0f);
    float3 rayColor = initialColor;
    for (int i = 0; i < maxBounceCount + 1; i++)
    {
        HitInfo hitInfo;
        hitInfo.didHit = true;
        CastDefaultRay(SceneBVH, origin, direction, hitInfo);
        if (hitInfo.didHit)
        {
            origin = hitInfo.hitWorldPoint;
            direction = RandomHemisphereDirection(seed, hitInfo.hitWorldNormal, hitInfo.hitWorldPoint);
            rayColor *= hitInfo.color;
            incomingLight += rayColor;
            
            //TODO: This piece of code calculates the random reflection direction based on the roughness of the surface. Integrate it when the time comes.
            float3 randomDirection = RandomHemisphereDirection(seed, samplePayload.hitWorldNormal, rayOrigin);
            float3 perfectReflectionDirection = reflect(samplePayload.rayWorldDirection, samplePayload.hitWorldNormal);
            rayDirection = lerp(perfectReflectionDirection, randomDirection, samplePayload.surfaceRoughness);
            
        }
        else
        {
            incomingLight = hitInfo.color;
            break;
        }
    }
    return incomingLight;
}
*/
[shader("raygeneration")]
void RayGen()
{
    bool useRayBounces = false; //debug flag

    if (useRayBounces)
    {
        /*uint2 pixelCoordinates = DispatchRaysIndex().xy; //DispatchRaysIndex(): Gets the current location within the width, height, and depth obtained with the DispatchRaysDimensions() system value intrinsic.
        float2 windowDimensions = float2(DispatchRaysDimensions().xy); //DispatchRayDimensions(): The width, height and depth values from the D3D12_DISPATCH_RAYS_DESC structure specified in the originating DispatchRays() call on the CPU side.
        float2 d = ((pixelCoordinates.xy + 0.5f) / windowDimensions.xy) * 2.0f - 1.0f; //d is the floating point pixel coordinates, normalized on [0, 1] X [0, 1]
        uint seed = GetPixelSeedForRandomValue();

        //Calculate ray origin and direction for the primary ray
        float3 rayOrigin, rayDirection;
        float3 rayOriginRelativeToCamera = float3(0.0f, 0.0f, 0.0f); //Put the ray origin at the camera's position
        rayOrigin = mul(viewInv, float4(rayOriginRelativeToCamera, 1.0f)).xyz; //Convert the origin from camera space to world space
        rayDirection = mul(projectionInv, float4(d.x, -d.y, 1.0f, 1.0f)).xyz; //y component is inverted in order to match the image indexing convention of DirectX.
        rayDirection = mul(viewInv, float4(rayDirection, 0.0f)).xyz;
        uint raysPerPixel = 1; //TODO: Keep this at one for now and make the ray bounces work properly. Then increase this if necessary
        uint rayBounceCount = 0;

        for (uint i = 0; i < raysPerPixel; i++)
        {
            //TODO: Implement the color contribution of each bounce
            for (uint j = 0; j < rayBounceCount + 1; j++) //+ 1 so that rayBounceCount = 0 means no bounces, which is more intuitive
            {
                HitInfo samplePayload;
                samplePayload.color = float3(1.0f, 1.0f, 1.0f);
                samplePayload.didHit = true; //We assume the ray did hit and handle not hitting in the miss shader later
                //CastDefaultRay(SceneBVH, rayOrigin, rayDirection, payload);
                totalLight += samplePayload.color;

                if (!samplePayload.didHit)
                {
                    //If the ray didn't hit anything, it won't bounce anymore so simply break out of the loop
                    break;
                }

                //Payload variables here will already be in the world space, so we don't need to apply transformation to them
                rayOrigin = samplePayload.hitWorldPoint;
                
            }
        }

        float3 lightColor = float3(1.0f, 1.0f, 1.0f);
        float3 totalIncomingLight = float3(0.0f, 0.0f, 0.0f);
        for (int i = 0; i < raysPerPixel; i++)
        {
            totalIncomingLight += TraceRayPath(rayOrigin, rayDirection, rayBounceCount, lightColor, seed);
        }
        float3 pixelColor = totalIncomingLight / raysPerPixel;
        gOutput[pixelCoordinates] = float4(pixelColor, 1.0f);*/
    }
    else
    {
        //This is a debugging code that doesn't implement any ray bouncing and the output is usable for visualizing the scene. It is not intended to be used except for debugging.
        uint2 pixelCoordinates = DispatchRaysIndex().xy; //DispatchRaysIndex(): Gets the current location within the width, height, and depth obtained with the DispatchRaysDimensions() system value intrinsic.
        float2 windowDimensions = float2(DispatchRaysDimensions().xy); //DispatchRayDimensions(): The width, height and depth values from the D3D12_DISPATCH_RAYS_DESC structure specified in the originating DispatchRays() call on the CPU side.
        float2 d = ((pixelCoordinates.xy + 0.5f) / windowDimensions.xy) * 2.0f - 1.0f; //d is the floating point pixel coordinates, normalized on [0, 1] X [0, 1]

        float3 rayOriginRelativeToCamera = float3(0.0f, 0.0f, 0.0f); //Put the ray origin at the camera's position
        float3 rayOrigin = mul(viewInv, float4(rayOriginRelativeToCamera, 1.0f)).xyz; //Convert the origin from camera space to world space
        float3 rayDirection = mul(projectionInv, float4(d.x, -d.y, 1.0f, 1.0f)).xyz; //y component is inverted in order to match the image indexing convention of DirectX.
        rayDirection = mul(viewInv, float4(rayDirection, 0.0f)).xyz;
        HitInfo payload;
        payload.color = float3(1.0f, 1.0f, 1.0f); //Initial color of the light is white, implement getting this value from the UI
        CastDefaultRay(SceneBVH, rayOrigin, rayDirection, payload);
        gOutput[pixelCoordinates] = float4(payload.color, 1.0f);
    }

    /*const int numSamples = 1; // Number of indirect rays per bounce

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
        
        for (int j = 0; j < 3; j++) // Bounces
        {
            float3 origin = mul(viewInv, float4(finalHitPoint, 1)).xyz;
            float4 target;
            if (j == 0) // Primary ray
            {
                //TODO: Calculate a random direction for the first ray per pixel (each sample needs to have a direction)
                //the random direction should be different for each iteration of the OUTER loop!
                target = mul(projectionInv, float4(d.x, -d.y, 1, 1));
                float4 offset = float4(GetRandomOffset(launchIndex, 1.0f, i), 0.0f);
                target += offset;
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
            float3 direction = mul(viewInv, float4(target.xyz, 0)).xyz;
            CastRay(origin, direction, samplePayload);
            finalHitPoint = samplePayload.hitWorldPoint;

            if (samplePayload.didHit)
            {
                samplePayload.color *= sampleContribution;
                sampleContribution *= 0.8f;
            }
            else
            {
                missed = true;
                break;
            }
        }
        accumulatedColor += samplePayload.color;
        if (missed)
        {
            break;
        }
    }
    float3 currentColor = missed ? accumulatedColor : accumulatedColor / numSamples;
    
    gOutput[launchIndex] = float4(currentColor, 1.0f);*/
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