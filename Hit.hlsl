#include "Common.hlsl"

//This structure has the same bit mapping as the "Vertex" structure on the CPU side.
struct STriVertex
{
    float3 vertex;
    float4 color;
};

StructuredBuffer<STriVertex> BTriVertex : register(t0);

[shader("closesthit")] 
void ClosestHit(inout HitInfo payload, Attributes attrib) 
{
    float3 barycentrics = float3(1.0f - attrib.bary.x - attrib.bary.y,
                                 attrib.bary.x,
                                 attrib.bary.y);
    
    uint vertId = 3 * PrimitiveIndex();
    float3 hitColor = float3(0.7f, 0.7f, 0.7f);
                      //BTriVertex[vertId + 0].color * barycentrics.x +
                      //BTriVertex[vertId + 1].color * barycentrics.y +
                      //BTriVertex[vertId + 2].color * barycentrics.z;
    
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
