#include "Common.hlsl"

// #DXR Extra - Another ray type
struct ShadowHitInfo
{
    bool isHit;
};

//This structure has the same bit mapping as the "Vertex" structure on the CPU side.
struct STriVertex
{
    float3 vertex;
    float4 color;
};

StructuredBuffer<STriVertex> BTriVertex : register(t0);
StructuredBuffer<int> indices : register(t1);
// #DXR Extra - Another ray type
// Raytracing TLAS, accessed as a SRV
RaytracingAccelerationStructure SceneBVH : register(t2);

cbuffer Colors : register(b0)
{
    float3 A;
    float3 B;
    float3 C;
}

[shader("closesthit")]
void ClosestHit(inout HitInfo payload, Attributes attrib) 
{
    float3 barycentrics = float3(1.0f - attrib.bary.x - attrib.bary.y,
                                 attrib.bary.x,
                                 attrib.bary.y);
    
    uint vertId = 3 * PrimitiveIndex();
    
    // #DXR Extra: Per-Instance Data
    float3 hitColor = float3(0.6f, 0.7f, 0.6f);
    // Shade only the first 3 instances (triangles)
    //if (InstanceID() < 3)
    {
        hitColor = BTriVertex[indices[vertId + 0]].color * barycentrics.x +
                   BTriVertex[indices[vertId + 1]].color * barycentrics.y +
                   BTriVertex[indices[vertId + 2]].color * barycentrics.z;
    }
    
    payload.colorAndDistance = float4(hitColor, RayTCurrent());
}

// #DXR Extra: Per-Instance Data
[shader("closesthit")]
void PlaneClosestHit(inout HitInfo payload, Attributes attrib)
{
    
    // #DXR Extra - Another ray type
    float3 lightPos = float3(2, 2, -2);
    //Find the hit position in world space
    float3 worldOrigin = WorldRayOrigin() + RayTCurrent() * WorldRayDirection();
    //Calculate the direction towards the light from the position of the ray that hit the plane
    float3 lightDir = normalize(lightPos - worldOrigin);
    // Fire a shadow ray. The direction is hard-coded here, but can be fetched from a constant-buffer.
    
    RayDesc ray;
    ray.Origin = worldOrigin;
    ray.Direction = lightDir;
    ray.TMin = 0.01;
    ray.TMax = 100000;
    
    // Initialize the ray payload
    ShadowHitInfo shadowPayload;
    shadowPayload.isHit = false;
    
    TraceRay(
    // Acceleration structure
    SceneBVH, //The problem is caused by improper data passing for this construct!!!!
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
    //so an index of 1.
    1,
    // Ray information to trace
    ray,
    // Payload associated to the ray, which will be used to communicate
    // between the hit/miss shaders and the raygen
    shadowPayload
    );
    float shadowFactor = shadowPayload.isHit ? 0.3f : 1.0f;
    float3 hitColor = float3(0.7f, 0.7f, 0.3f) * shadowFactor;
    payload.colorAndDistance = float4(hitColor, RayTCurrent());
}