#include "Common.hlsl"
#include "CheckersPattern.hlsli"

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
    float reflectivity;
};

// #DXR Extra - Simple Lighting
struct InstanceProperties
{
    float4x4 objectToWorld;
    float4x4 objectToWorldNormal;
};

struct Light
{
    float3 color;
    float3 position;
    float intensity;
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

static const int LIGHT_COUNT = 6;
static Light lights[LIGHT_COUNT] =
{
    { float3(1.0f, 1.0f, 1.0f), float3(+00.0f, +10.0f, +00.0f), 0.2f },
    { float3(1.0f, 1.0f, 1.0f), float3(+10.0f, +10.0f, +00.0f), 0.2f },
    { float3(1.0f, 1.0f, 1.0f), float3(-10.0f, +10.0f, +00.0f), 0.2f },
    { float3(1.0f, 1.0f, 1.0f), float3(+00.0f, +10.0f, +10.0f), 0.2f },
    { float3(1.0f, 1.0f, 1.0f), float3(+00.0f, +10.0f, -10.0f), 0.2f },
    { float3(1.0f, 1.0f, 1.0f), float3(+00.0f, -10.0f, +00.0f), 0.2f },
};

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

float3 CalculateDirectLighting(float3 hitPoint, float3 normal, float3 surfaceColor)
{
    float3 color = float3(0.0f, 0.0f, 0.0f);
    for (int i = 0; i < LIGHT_COUNT; i++)
    {
        Light light = lights[i];
        float3 directionTowardsLight = -normalize(light.position - hitPoint);
        float lightFactor = dot(normal, directionTowardsLight);
        float totalIntensity = max(0.0f, lightFactor * light.intensity);
        color += surfaceColor * light.color * totalIntensity;
    }
    return color;
}

void ReflectRay(float3 hitPoint, float3 normal, inout HitInfo payload)
{
    float3 viewDir = normalize(WorldRayDirection());
    float3 reflectionDirection = normalize(reflect(viewDir, normal));
    CastReflectionRay(SceneBVH, hitPoint, reflectionDirection, payload);
}

float3 FresnelSchlick(float cosTheta, float3 F0)
{
    return F0 + (1.0 - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}

float NormalDistributionGGX(float3 N, float3 H, float roughness)
{
    float a      = roughness*roughness;
    float a2     = a*a;
    float NdotH  = max(dot(N, H), 0.0);
    float NdotH2 = NdotH*NdotH;
    float num   = a2;
    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;
    return num / denom;
}

float GeometrySchlickGGX(float NdotV, float roughness)
{
    float r = (roughness + 1.0);
    float k = (r*r) / 8.0;
    float num   = NdotV;
    float denom = NdotV * (1.0 - k) + k;
    return num / denom;
}

float GeometrySmith(float3 N, float3 V, float3 L, float roughness)
{
    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, L), 0.0);
    float ggx2  = GeometrySchlickGGX(NdotV, roughness);
    float ggx1  = GeometrySchlickGGX(NdotL, roughness);
    return ggx1 * ggx2;
}

float3 CalculatePBRShading(Material material, float3 normal, float3 cameraPosition, float3 worldHitPoint)
{
    float3 N = -normalize(normal);
    float3 V = normalize(cameraPosition - worldHitPoint);
    float3 L0 = float3(0.0f, 0.0f, 0.0f);
    for (int i = 0; i < LIGHT_COUNT; i++)
    {
        Light light = lights[i];
        float3 lightPosition = light.position;
        float3 lightColor = light.color;
        float3 L = normalize(light.position - worldHitPoint);
        float3 H = normalize(V + L);
        float distance = length(light.position - worldHitPoint);
        float attenuation = 1.0f / max(distance * distance, 1.0f); //Clamp denominator to avoid too big values
        float3 radiance = lightColor * attenuation;

        float3 F0 = float3(0.04f, 0.04f, 0.04f); //This value looks correct for most dielectric surfaces. F0 value for the metallic surfaces are the same as the albedo of the surface.
        F0 = lerp(F0, material.albedo, material.metallic);
        float3 F = FresnelSchlick(max(dot(H, V), 0.0f), F0);
        float NDF = NormalDistributionGGX(N, H, material.roughness);
        float G = GeometrySmith(N, V, L, material.roughness);
        float3 numerator = NDF * G * F;
        float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0)  + 0.0001; //Offset to avoid division by zero
        float3 specularLight = numerator / denominator;

        float3 kS = F;
        float3 kD = float3(1.0f, 1.0f, 1.0f) - kS;
        kD *= 1.0f - material.metallic;
        
        float NdotL = max(dot(N, L), 0.0);
        L0 += (kD * material.albedo / PI + specularLight) * radiance * NdotL;
    }

    float3 ambientLight = float3(0.2f, 0.2f, 0.2f); //Constant ambient light for now. This can be set from UI later
    float3 color = L0 * ambientLight;

    //At this point color is the color of our pixel but we assumed all calculations to be in linear space.
    //Therefore we need to apply gamma correction before returning.
    color = color / (color + float3(1.0f, 1.0f, 1.0f));
    color = pow(color, float3(1.0f / 2.2f, 1.0f / 2.2f, 1.0f / 2.2f));
    
    return color;
}

[shader("closesthit")]
void ClosestHit(inout HitInfo payload, BuiltInTriangleIntersectionAttributes attrib)
{
    float3 hitWorldPosition = GetWorldHitPoint();
    float3 barycentrics = float3(attrib.barycentrics.x, attrib.barycentrics.y, 1.0f - attrib.barycentrics.x - attrib.barycentrics.y);
    float3 normal = CalculateInterpolatedWorldNormal(barycentrics);
    Material material = materials[0];
    float3 surfaceColor = material.albedo;
    float3 lightColor = CalculateDirectLighting(hitWorldPosition, normal, surfaceColor);
    float3 finalSurfaceColor = lightColor + CalculatePBRShading(material, normal, WorldRayOrigin(), hitWorldPosition);
    HitInfo reflectionPayload;
    ReflectRay(hitWorldPosition, normal, reflectionPayload);
    float reflectivity = InstanceID() == 0 || InstanceID() == 1 ? material.reflectivity : 0.0f;
    payload.color = lerp(finalSurfaceColor, reflectionPayload.color, reflectivity);
}

// #DXR Extra: Per-Instance Data
[shader("closesthit")]
void PlaneClosestHit(inout HitInfo payload, BuiltInTriangleIntersectionAttributes attrib)
{
    // #DXR Extra - Another ray type
    //Find the hit position in world space
    float3 hitWorldPosition = GetWorldHitPoint();
    //Calculate the direction towards the light from the position of the ray that hit the plane
    float3 lightDir = normalize(lights[0].position - hitWorldPosition);
    // Fire a shadow ray. The direction is hard-coded here, but can be fetched from a constant-buffer.
    
    // #DXR Extra - Simple Lighting
    uint vertId = 3 * PrimitiveIndex();
    float3 e1 = BTriVertex[vertId + 1].position - BTriVertex[vertId + 0].position;
    float3 e2 = BTriVertex[vertId + 2].position - BTriVertex[vertId + 0].position;
    float3 normal = normalize(cross(e1, e2));
    normal = mul(instanceProperties[InstanceID()].objectToWorldNormal, float4(normal, 0.f)).xyz;
    
    float3 centerLightDir = normalize(lights[0].position - hitWorldPosition);
    bool isShadowed = dot(normal, centerLightDir) < 0.f;
    
    ShadowHitInfo shadowPayload;
    float3 shadowRayOrigin = hitWorldPosition;
    float3 shadowRayDirection = lightDir;
    CastShadowRay(SceneBVH, shadowRayOrigin, shadowRayDirection, shadowPayload);
    
    if (!isShadowed)
    {
        isShadowed = shadowPayload.isHit;
    }
    float shadowFactor = isShadowed ? 0.3f : 1.0f;
    float multiplier = dot(normal, lightDir);
    float lightIntensity = max(0.0f, multiplier);
    float3 platformColor = float3(1.0f, 1.0f, 1.0f) * lightIntensity * shadowFactor;
    payload.color = platformColor;
}