#define PI 3.14159265359

#define DEFAULT_HIT_GROUP_INDEX 0
#define DEFAULT_MISS_SHADER_INDEX 0
#define SHADOW_HIT_GROUP_INDEX 1
#define SHADOW_MISS_SHADER_INDEX 1

#define DONT_MASK_GEOMETRY 0xFF

// Hit information, aka ray payload
// Note that the payload should be kept as small as possible,
// and that its size must be declared in the corresponding
// D3D12_RAYTRACING_SHADER_CONFIG pipeline subobjet.
struct HitInfo
{
    float3 color;
};

struct ShadowHitInfo
{
    bool isHit;
};

float3 GetWorldHitPoint()
{
    return WorldRayOrigin() + RayTCurrent() * WorldRayDirection();
}

uint GetPixelSeedForRandomValue()
{
    uint2 pixelCoordinates = DispatchRaysIndex().xy; //DispatchRaysIndex(): Gets the current location within the width, height, and depth obtained with the DispatchRaysDimensions() system value intrinsic.
    uint seed = (pixelCoordinates.x * 73856093) ^ (pixelCoordinates.y * 19349663); //Seed for random operation that will be done on this pixel. All the random operation modify the seeds themselves, so only the initial value is needed. The rest will be figured out as the shader is executed.
    return seed;
}

//Returns a random value between 0.0f and 1.0f
float RandomFloat(inout uint seed)
{
    seed = seed * 747796405 + 2891336453;
    uint result = ((seed >> ((int)(seed >> 28) + 4)) ^ seed) * 277803737;
    result = (result >> 22) ^ result;
    return result / 4294967295.0f;
}

//Returns a random value between 0.0f and 1.0f
float RandomFloatNormalDistribution(inout uint seed)
{
    float theta = 2 * PI * RandomFloat(seed);
    float rho = sqrt(-2 * log(RandomFloat(seed)));
    return rho * cos(theta);
}

float RandomFloatInRange(inout uint seed, float minInclusive, float maxInclusive)
{
    return lerp(minInclusive, maxInclusive, RandomFloatNormalDistribution(seed));
}

//TRACE RAY WRAPPERS
/*
    //This is a TraceRay() call from the benchmark project. It is here as a documentation because it demonstrates how the parameters can be used in an easy-to-read way.
    TraceRay(
        g_scene,
        RAY_FLAG_CULL_BACK_FACING_TRIANGLES,
        TraceRayParameters::InstanceMask,
        TraceRayParameters::HitGroup::Offset[RayType::Radiance],
        TraceRayParameters::HitGroup::GeometryStride,
        TraceRayParameters::MissShader::Offset[RayType::Radiance],
        rayDesc,
        rayPayload
    );
*/

void CastDefaultRay(RaytracingAccelerationStructure TLAS, float3 origin, float3 direction, inout HitInfo payload)
{
    direction = normalize(direction);
    RayDesc ray;
    ray.Origin = origin;
    ray.Direction = direction;
    ray.TMin = 0;
    ray.TMax = 100000;
    //RAY_FLAG_CULL_BACK_FACING_TRIANGLES is more performant than RAY_FLAG_NONE, but the models in the project can look weird if RAY_FLAG_CULL_BACK_FACING_TRIANGLES is used.
    //RAY_FLAG_NONE version is therefore used as the default but RAY_FLAG_CULL_BACK_FACING_TRIANGLES is included as a comment so that it is easy to enable if needed.
    TraceRay(TLAS, RAY_FLAG_NONE, DONT_MASK_GEOMETRY, DEFAULT_HIT_GROUP_INDEX, DEFAULT_MISS_SHADER_INDEX, 0, ray, payload);
    //TraceRay(TLAS, RAY_FLAG_CULL_BACK_FACING_TRIANGLES, DONT_MASK_GEOMETRY, DEFAULT_HIT_GROUP_INDEX, DEFAULT_MISS_SHADER_INDEX, 0, ray, payload);
}

void CastReflectionRay(RaytracingAccelerationStructure TLAS, float3 origin, float3 direction, inout HitInfo payload)
{
    direction = normalize(direction);
    RayDesc ray;
    ray.Origin = origin + direction * 0.001f; //Small offset to avoid self intersection
    ray.Direction = direction;
    ray.TMin = 0.001f;
    ray.TMax = 1000.0f;
    //RAY_FLAG_NONE here causes self-reflection of rays, meaning they hit the back of the face that they already hit, then backface ray hits the front face and so on.
    //This causes an infinite loop which eventually passes the recursion limit in the pipeline and the application crashes.
    TraceRay(TLAS, RAY_FLAG_CULL_BACK_FACING_TRIANGLES, DONT_MASK_GEOMETRY, DEFAULT_HIT_GROUP_INDEX, DEFAULT_MISS_SHADER_INDEX, 0, ray, payload);
}

void CastShadowRay(RaytracingAccelerationStructure TLAS, float3 origin, float3 direction, inout ShadowHitInfo payload)
{
    direction = normalize(direction);
    RayDesc ray;
    ray.Origin = origin;
    ray.Direction = direction;
    ray.TMin = 0.01;
    ray.TMax = 100000;
    //I honestly don't know if there is a difference between the two that might crash the app so I am keeping RAY_FLAG_CULL_BACK_FACING_TRIANGLES version as a backup here.
    //TraceRay(TLAS, RAY_FLAG_CULL_BACK_FACING_TRIANGLES, DONT_MASK_GEOMETRY, SHADOW_HIT_GROUP_INDEX, SHADOW_MISS_SHADER_INDEX, 0, ray, payload);
    TraceRay(TLAS, RAY_FLAG_NONE, DONT_MASK_GEOMETRY, SHADOW_HIT_GROUP_INDEX, SHADOW_MISS_SHADER_INDEX, 0, ray, payload);
}