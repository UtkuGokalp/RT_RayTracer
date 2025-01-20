#include "Common.hlsl"
#include "CheckersPattern.hlsli"

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

cbuffer Colors : register(b0)
{
    float3 A;
    float3 B;
    float3 C;
}

static float3 lightPosition = float3(2, 2, -2);

// #DXR Extra - Simple Lighting
StructuredBuffer<InstanceProperties> instanceProperties : register(t3);

[shader("closesthit")]
void ClosestHit(inout HitInfo payload, Attributes attrib)
{
    //float3 barycentrics = float3(1.0f - attrib.bary.x - attrib.bary.y, attrib.bary.x, attrib.bary.y);
    
    uint vertId = 3 * PrimitiveIndex();
    
    // #DXR Extra: Per-Instance Data
    float3 hitColor = float3(1.0f, 1.0f, 1.0f);

    // #DXR Extra - Simple Lighting
    //Calculate normals based on the vertices
    float3 e1 = BTriVertex[indices[vertId + 1]].vertex - BTriVertex[indices[vertId + 0]].vertex;
    float3 e2 = BTriVertex[indices[vertId + 2]].vertex - BTriVertex[indices[vertId + 0]].vertex;
    float3 normal = normalize(cross(e2, e1));
    normal = mul(instanceProperties[InstanceID()].objectToWorldNormal, float4(normal, 0.0f)).xyz;
    
    
    float3 hitWorldPosition = WorldRayOrigin() + RayTCurrent() * WorldRayDirection();
    float3 centerLightDir = normalize(lightPosition - hitWorldPosition);
    float factor = dot(normal, centerLightDir);
    float lightIntensity = max(0.0f, factor);
    hitColor *= lightIntensity;
    payload.colorAndDistance = float4(hitColor, RayTCurrent());
}

// #DXR Extra: Per-Instance Data
[shader("closesthit")]
void PlaneClosestHit(inout HitInfo payload, Attributes attrib)
{
    // #DXR Extra - Another ray type
    //Find the hit position in world space
    float3 hitWorldPosition = WorldRayOrigin() + RayTCurrent() * WorldRayDirection();
    //Calculate the direction towards the light from the position of the ray that hit the plane
    float3 lightDir = normalize(lightPosition - hitWorldPosition);
    // Fire a shadow ray. The direction is hard-coded here, but can be fetched from a constant-buffer.
    
    // #DXR Extra - Simple Lighting
    uint vertId = 3 * PrimitiveIndex();
    float3 e1 = BTriVertex[vertId + 1].vertex - BTriVertex[vertId + 0].vertex;
    float3 e2 = BTriVertex[vertId + 2].vertex - BTriVertex[vertId + 0].vertex;
    float3 normal = normalize(cross(e2, e1));
    normal = mul(instanceProperties[InstanceID()].objectToWorldNormal, float4(normal, 0.f)).xyz;
    
    bool isBackFacing = dot(normal, WorldRayDirection()) > 0.f;
    if (isBackFacing)
    {
        normal = -normal;
    }
    
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
    //TODO: Uncomment the lightIntensity * shadowFactor multiplication for shadows
    float3 platformColor = float3(1.0f, 1.0f, 1.0f);// * lightIntensity * shadowFactor;

    //Ray for reflection
    ray.Origin = hitWorldPosition;
    ray.Direction = reflect(WorldRayDirection(), normal);
    ray.TMin = 0.01;
    ray.TMax = 100000;
    HitInfo reflectancePayload = { float4(0, 0, 0, 0) };
    TraceRay(
        SceneBVH, //Acceleration structure containing the scene
        RAY_FLAG_CULL_BACK_FACING_TRIANGLES, //Flag to cull backfacing triangles (this can also be used as a debug because currently there are some weird problems with normals)
        0xFF, //Don't mask any geometry
        0, //No specific offset for radiance rays, just use the first shader in the SBT for now
        0, //No stride in the SBT
        0, //Use the first miss shader in the SBT
        ray, //Which ray to trace
        reflectancePayload //Payload
    );

    //Make the surface have a checker pattern.
    float3 hitColor = platformColor * reflectancePayload.colorAndDistance.xyz;
    float3 cameraPosition = float3(0, 0, 0); //Doesn't seem to have any effect and I don't want to mess with the memory management right now. It can be implemented later on.
    float checkersPattern = AnalyticalCheckersTexture(hitWorldPosition, normal, cameraPosition, instanceProperties[InstanceID()].objectToWorldNormal);
    hitColor *= checkersPattern;

/*
    //This is a TraceRay() call from the benchmark project. It is left here as a documentation because it provides some insight
    //to how the parameters need to be used.
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
    payload.colorAndDistance = float4(hitColor, 1);
}