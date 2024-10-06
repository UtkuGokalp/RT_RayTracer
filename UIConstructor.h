#pragma once

#include "imgui.h"
#include <array>

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
private:
    bool demoUIShown;
    float lightColor[3];
    float lightIntensity = 0.5f;
    bool isUsingRaytracing;
};
