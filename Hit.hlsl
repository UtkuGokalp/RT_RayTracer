#include "Common.hlsl"
#include "CheckersPattern.hlsli"

#define PI 3.14159265359

/*
    //This is a TraceRay() call from the benchmark project. It is here as a documentation because it provides some insight to how the parameters need to be used.
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

// #DXR Extra - Another ray type
struct ShadowHitInfo
{
    bool isHit;
};

//This structure has the same bit mapping as the "Vertex" structure on the CPU side.
struct STriVertex
{
    float3 position;
    float3 normal;
};

struct Material
{
	float3 albedo;
	float roughness;
	float metallic;
};

// #DXR Extra - Simple Lighting
struct InstanceProperties
{
    float4x4 objectToWorld;
    float4x4 objectToWorldNormal;
};

StructuredBuffer<STriVertex> BTriVertex : register(t0);
StructuredBuffer<int> indices : register(t1);
// #DXR Extra - Another ray type
// Raytracing TLAS, accessed as a SRV
RaytracingAccelerationStructure SceneBVH : register(t2);
// #DXR Extra - Simple Lighting
StructuredBuffer<InstanceProperties> instanceProperties : register(t3);
StructuredBuffer<Material> materials : register(t4);

cbuffer Colors : register(b0)
{
    float3 A;
    float3 B;
    float3 C;
}

static float3 lightPosition = float3(0, 10, 0);

float3 ComputeFaceNormal(float3 vertex0, float3 vertex1, float3 vertex2)
{
    float3 edge1 = vertex1 - vertex0;
    float3 edge2 = vertex2 - vertex0;
    float3 normal = normalize(cross(edge2, edge1));
    return normal;
}

float3 CalculateInterpolatedWorldNormal(float3 barycentrics)
{
    //Interpolate vertex normals with barycentric coordinates
    uint vertId = 3 * PrimitiveIndex();
    //Index offsets are given in the order 1 2 0 and not 0 1 2 because the file used for debugging has the indices
    //cycled by one. Using 0 1 2 causes the normals to get incorrectly calculated
    float3 n0 = BTriVertex[indices[vertId + 1]].normal;
    float3 n1 = BTriVertex[indices[vertId + 2]].normal;
    float3 n2 = BTriVertex[indices[vertId + 0]].normal;
    float3 normal = normalize(n0 * barycentrics.x + n1 * barycentrics.y + n2 * barycentrics.z);
    normal = mul(instanceProperties[InstanceID()].objectToWorldNormal, float4(normal, 0.0f)).xyz;
    return normalize(normal);
}

float CalculateDirectLighting(float3 hitPoint, float3 normal)
{
    float3 centerLightDir = -normalize(lightPosition - hitPoint);
    float factor = dot(normal, centerLightDir);
    float lightIntensity = max(0.0f, factor);
    return lightIntensity;
}

void ReflectRay(float3 hitPoint, float3 normal, inout HitInfo payload)
{
    float3 viewDir = normalize(WorldRayDirection());
    float3 reflectionDirection = normalize(reflect(viewDir, normal)); // RandomHemisphereDirection(normal, seed);
    RayDesc ray;
    ray.Origin = hitPoint + reflectionDirection * 0.001f; // Offset to avoid self-intersection
    ray.Direction = reflectionDirection;
    ray.TMin = 0.001f;
    ray.TMax = 1000.0f;
    TraceRay(SceneBVH, RAY_FLAG_NONE, 0xFF, 0, 0, 0, ray, payload);
}

[shader("closesthit")]
void ClosestHit(inout HitInfo payload, BuiltInTriangleIntersectionAttributes attrib)
{
    Material material = materials[0];
    float3 surfaceColor = material.albedo * payload.color;
    float3 hitWorldPosition = WorldRayOrigin() + RayTCurrent() * WorldRayDirection();
    float3 barycentrics = float3(attrib.barycentrics.x, attrib.barycentrics.y, 1.0f - attrib.barycentrics.x - attrib.barycentrics.y);
    float3 normal = CalculateInterpolatedWorldNormal(barycentrics);
    float lightIntensity = CalculateDirectLighting(hitWorldPosition, normal);
    
    payload.rayWorldDirection = WorldRayDirection();
    payload.hitWorldNormal = normal;
    payload.hitWorldPoint = hitWorldPosition;
    payload.color = surfaceColor * lightIntensity;
}

// #DXR Extra: Per-Instance Data
[shader("closesthit")]
void PlaneClosestHit(inout HitInfo payload, BuiltInTriangleIntersectionAttributes attrib)
{
    // #DXR Extra - Another ray type
    //Find the hit position in world space
    float3 hitWorldPosition = WorldRayOrigin() + RayTCurrent() * WorldRayDirection();
    //Calculate the direction towards the light from the position of the ray that hit the plane
    float3 lightDir = normalize(lightPosition - hitWorldPosition);
    // Fire a shadow ray. The direction is hard-coded here, but can be fetched from a constant-buffer.
    
    // #DXR Extra - Simple Lighting
    uint vertId = 3 * PrimitiveIndex();
    float3 e1 = BTriVertex[vertId + 1].position - BTriVertex[vertId + 0].position;
    float3 e2 = BTriVertex[vertId + 2].position - BTriVertex[vertId + 0].position;
    float3 normal = normalize(cross(e2, e1));
    normal = mul(instanceProperties[InstanceID()].objectToWorldNormal, float4(normal, 0.f)).xyz;
    
    float3 centerLightDir = normalize(lightPosition - hitWorldPosition);
    bool isShadowed = dot(normal, centerLightDir) < 0.f;
    
    //Ray for shadows
    RayDesc ray;
    ray.Origin = hitWorldPosition;
    ray.Direction = lightDir;
    ray.TMin = 0.01;
    ray.TMax = 100000;
    
    // Initialize the ray payload
    ShadowHitInfo shadowPayload;
    shadowPayload.isHit = false;
    TraceRay(
    // Acceleration structure
    SceneBVH,
    // Flags can be used to specify the behavior upon hitting a surface
    RAY_FLAG_NONE,
    // Instance inclusion mask, which can be used to mask out some geometry to
    // this ray by bitwise-anding the mask with a geometry mask. The 0xFF flag then
    // indicates no geometry will be masked
    0xFF,
    // Depending on the type of ray, a given object can have several hit
    // groups attached (ie. what to do when hitting to compute regular
    // shading, and what to do when hitting to compute shadows). Those hit
    // groups are specified sequentially in the shader binding table, so the value below
    // indicates which offset (on 4 bits) to apply to the hit groups for this
    // ray. The shadow hit group is the 2nd hit group in the SBT, so an index of 1.
    1,
    // The offsets in the SBT can be computed from the object ID, its instance
    // ID, but also simply by the order the objects have been pushed in the
    // acceleration structure. This allows the application to group shaders in
    // the SBT in the same order as they are added in the AS, in which case
    // the value below represents the stride (4 bits representing the number
    // of hit groups) between two consecutive objects.
    0,
    // Index of the miss shader to use in case several consecutive miss
    // shaders are present in the SBT. This allows to change the behavior of
    // the program when no geometry have been hit, for example one to return a
    // sky color for regular rendering, and another returning a full
    // visibility value for shadow rays. Shadow miss program is the 2nd miss program,
    // so an index of 1.
    1,
    // Ray information to trace
    ray,
    // Payload associated to the ray, which will be used to communicate
    // between the hit/miss shaders and the raygen
    shadowPayload
    );
    
    if (!isShadowed)
    {
        isShadowed = shadowPayload.isHit;
    }
    float shadowFactor = isShadowed ? 0.3f : 1.0f;
    float multiplier = dot(normal, lightDir);
    float lightIntensity = max(0.0f, multiplier);
    //TODO: Uncomment the shadowFactor multiplication for shadows (its issue is probably because of the scaling of the platform, try changing the vertices instead of scaling the model)
    float3 platformColor = float3(1.0f, 1.0f, 1.0f) * lightIntensity; //* shadowFactor;
    payload.color = platformColor;
    payload.hitWorldPoint = hitWorldPosition;
    payload.hitWorldNormal = normal;
    payload.rayWorldDirection = WorldRayDirection();
}