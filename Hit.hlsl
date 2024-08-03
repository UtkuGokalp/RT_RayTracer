#include "Common.hlsl"

//This structure has the same bit mapping as the "Vertex" structure on the CPU side.
struct STriVertex
{
    float3 vertex;
    float4 color;
};

StructuredBuffer<STriVertex> BTriVertex : register(t0);

// #DXR Extra: Per-Instance Data
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
    float3 hitColor = BTriVertex[vertId + 0].color * barycentrics.x +
                      BTriVertex[vertId + 1].color * barycentrics.y +
                      BTriVertex[vertId + 2].color * barycentrics.z;
    
    // #DXR Extra: Per-Instance Data
    hitColor = float3(0.6, 0.7, 0.6);
    // Shade only the first 3 instances (triangles)
    if (InstanceID() < 3)
    {
        //hitColor = A[InstanceID()] * barycentrics.x + B[InstanceID()] * barycentrics.y + C[InstanceID()] * barycentrics.z;
    }
    
    
    switch (InstanceID()) //This method returns the ID that is passed to the AddInstance function used in CreateTopLevelAS function.
    {
        case 0:
            hitColor = float3(0.4f, 0.9f, 0.2f);
            break;
        case 1:
            hitColor = float3(0.37f, 0.1f, 0.95f);
            break;
        case 2:
            hitColor = float3(0.1f, 0.95f, 0.9f);
            break;
    }
    
    
    payload.colorAndDistance = float4(hitColor, RayTCurrent());
}
