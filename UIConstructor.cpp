#include "UIConstructor.h"

UIConstructor::UIConstructor()
{
    demoUIShown = false;
    lightColor[0] = 1.0f;
    lightColor[1] = 1.0f;
    lightColor[2] = 1.0f;
}

void UIConstructor::Construct()
{
    //Demo UI
    if (demoUIShown)
    {
        ImGui::ShowDemoWindow();
    }

    //File Selection
    ImGui::Begin("File Selection");
    char temp[2] = { 0 };
    ImGui::InputText("File Path", temp, 120); //TODO: Change temp to an actual buffer for the file path (120 characters + 1 for the null character should be enough)

    if (ImGui::Button("Load Model File", ImVec2(120, 20)))
    {
    }
    ImGui::Text("File Loaded/File Not Found Placeholder text");
    ImGui::End();

    //Lighting controls
    ImGui::Begin("Lighting");
    ImGui::ColorEdit3("Light Color", lightColor);
    ImGui::End();
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