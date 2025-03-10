#pragma once

#include "imgui.h"
#include <array>
#include <DirectXMath.h>

using namespace DirectX;

class UIConstructor
{
public:
    UIConstructor();
    void Construct();
    void SetDemoUIEnable(bool enabled);
    bool IsDemoUIShown();
    std::array<float, 3> GetLightColor();
    void SetRenderingMode(bool usingRaytracing);
    float GetLightIntensity();
    void SetFrameTime(float frameTime);
    XMFLOAT3 GetAlbedo();
    float GetRoughness();
    float GetMetallic();
private:
    bool demoUIShown;
    float lightColor[3];
    float lightIntensity = 0.5f;
    bool isUsingRaytracing;
    float frameTime;
    float albedo[3];
    float roughness;
    float metallic;
};
