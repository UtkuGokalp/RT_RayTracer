#include "UIConstructor.h"

UIConstructor::UIConstructor()
{
    demoUIShown = false;
    lightColor[0] = 1.0f;
    lightColor[1] = 1.0f;
    lightColor[2] = 1.0f;
    //This initialization is written bc currently the default rendering mode is raytracing.
    //This should be updated from the D3D12HelloTriangle.cpp, OnInit() method.
    isUsingRaytracing = true;
}

void UIConstructor::Construct()
{
    //Demo UI
    if (demoUIShown)
    {
        ImGui::ShowDemoWindow();
    }

    char fpsString[65] = { 0 };
    _snprintf_s(fpsString, 64, "%.3f ms, %.2f FPS", frameTime, 1.0f / (frameTime * 1e-3)); //Frame time is in ms so multiply it with 10^-3 in the denominator
    ImGui::Begin("Performance");
    ImGui::Text(fpsString);
    ImGui::End();

    //Rendering mode display
    ImGui::Begin("Rendering Mode");
    ImGui::Text("%s", isUsingRaytracing ? "Raytracing" : "Rasterization");
    ImGui::End();

    //File Selection
    ImGui::Begin("File Selection");
    char temp[121] = { 0 };
    ImGui::InputText("File Path", temp, 120); //TODO: Change temp to an actual buffer for the file path (120 characters + 1 for the null character should be enough)

    if (ImGui::Button("Load Model File", ImVec2(120, 20)))
    {
    }
    ImGui::Text("File Loaded/File Not Found Placeholder text");
    ImGui::End();

    //Lighting controls
    ImGui::Begin("Lighting");
    ImGui::SliderFloat("Light Intensity", &lightIntensity, 0.0f, 1.0f, "%.2f");
    ImGui::ColorPicker3("Light Color", lightColor);
    ImGui::End();
}

float UIConstructor::GetLightIntensity()
{
    return lightIntensity;
}

void UIConstructor::SetDemoUIEnable(bool enabled)
{
    demoUIShown = enabled;
}

bool UIConstructor::IsDemoUIShown()
{
    return demoUIShown;
}

std::array<float, 3> UIConstructor::GetLightColor()
{
    return { lightColor[0], lightColor[1], lightColor[2] };
}

void UIConstructor::SetRenderingMode(bool usingRaytracing)
{
    isUsingRaytracing = usingRaytracing;
}

void UIConstructor::SetFrameTime(float frameTime)
{
    this->frameTime = frameTime;
}