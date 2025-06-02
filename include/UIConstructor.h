#pragma once

#include "imgui.h"
#include <array>
#include <DirectXMath.h>
#include <functional>
#include <string>
#include "OBJ_FileManager.h"

typedef unsigned int UINT;

using namespace DirectX;

extern class D3D12HelloTriangle;

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
    float GetReflectivity();
    void SetModelUpdateFunction(std::function<void(std::vector<XMFLOAT3>& vertices, std::vector<UINT>& indices)> function);
private:
    bool demoUIShown;
    float lightColor[3];
    float lightIntensity = 0.5f;
    bool isUsingRaytracing;
    float frameTime;
    float albedo[3];
    float roughness;
    float metallic;
    float reflectivity;
    std::function<void(std::vector<XMFLOAT3>& vertices, std::vector<UINT>& indices)> modelUpdateFunction;
    std::string modelFileLoadFeedbackMessage;
    char newModelFilePath[121] = { 0 };
};
