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
private:
    bool demoUIShown;
    float lightColor[3];
};
