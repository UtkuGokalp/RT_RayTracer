#include "Common.hlsl"

//This structure has the same bit mapping as the "Vertex" structure on the CPU side.
struct STriVertex
{
    float3 vertex;
    float4 color;
};

StructuredBuffer<STriVertex> BTriVertex : register(t0);

cbuffer Colors : register(b0)
{
    float3 A[3];
    float3 B[3];
    float3 C[3];
}

[shader("closesthit")]
void ClosestHit(inout HitInfo payload, Attributes attrib) 
{
    float3 barycentrics = float3(1.0f - attrib.bary.x - attrib.bary.y,
                                 attrib.bary.x,
                                 attrib.bary.y);
    
    uint vertId = 3 * PrimitiveIndex();
    
    // #DXR Extra: Per-Instance Data
    float3 hitColor = float3(0.6, 0.7, 0.6);
    // Shade only the first 3 instances (triangles)
    if (InstanceID() < 3)
    {
        hitColor = A[InstanceID()] * barycentrics.x + B[InstanceID()] * barycentrics.y + C[InstanceID()] * barycentrics.z;
    }
    
    payload.colorAndDistance = float4(hitColor, RayTCurrent());
}

// #DXR Extra: Per-Instance Data
[shader("closesthit")]
void PlaneClosestHit(inout HitInfo payload, Attributes attrib)
{
    float3 barycentrics = float3(1.0f - attrib.bary.x - attrib.bary.y,
                                 attrib.bary.x,
                                 attrib.bary.y);
    
    float3 hitColor = float3(0.7f, 0.7f, 0.3f);
    payload.colorAndDistance = float4(hitColor, RayTCurrent());
}