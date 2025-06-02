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
    albedo[0] = 1.0f;
    albedo[1] = 1.0f;
    albedo[2] = 1.0f;
    roughness = 0.5f;
    metallic = 0.5f;
    modelUpdateFunction = nullptr;
    modelFileLoadFeedbackMessage = "";
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

    ImGui::Begin("Materials");
    ImGui::ColorPicker3("Albedo", albedo);
    ImGui::SliderFloat("Roughness", &roughness, 0.0f, 1.0f);
    ImGui::SliderFloat("Metallic", &metallic, 0.0f, 1.0f);
    ImGui::SliderFloat("Reflectivity", &reflectivity, 0.0f, 1.0f);
    ImGui::End();

    //Rendering mode display
    ImGui::Begin("Rendering Mode");
    ImGui::Text("%s", isUsingRaytracing ? "Raytracing" : "Rasterization");
    ImGui::End();

    //File Selection
    ImGui::Begin("File Selection");
    ImGui::InputText("File Path", newModelFilePath, 120);

    if (ImGui::Button("Load Model File", ImVec2(120, 20)))
    {
        if (modelUpdateFunction == nullptr)
        {
            modelFileLoadFeedbackMessage = "No function is set to update the model parameters";
        }
        else
        {
            OBJFileManager ofm = OBJFileManager();
            std::vector<objl::Vertex> vertices;
            std::vector<UINT> indices;
            bool loaded = ofm.LoadObjFile(std::string(newModelFilePath), vertices, indices);
            if (loaded)
            {
                std::vector<XMFLOAT3> vertexPoints;
                vertexPoints.reserve(vertices.size());
                for (objl::Vertex& vertex : vertices)
                {
                    objl::Vector3 position = vertex.Position;
                    vertexPoints.push_back(XMFLOAT3(position.X, position.Y, position.Z));
                }
                modelUpdateFunction(vertexPoints, indices);
                modelFileLoadFeedbackMessage = "Succesfully loaded the file.";
            }
            else
            {
                modelFileLoadFeedbackMessage = "Couldn't load file. Check if the file exists.";
            }
        }
    }
    ImGui::Text(modelFileLoadFeedbackMessage.data());
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

XMFLOAT3 UIConstructor::GetAlbedo()
{
    return XMFLOAT3(albedo[0], albedo[1], albedo[2]);
}

float UIConstructor::GetRoughness()
{
    return roughness;
}

float UIConstructor::GetMetallic()
{
    return metallic;
}

void UIConstructor::SetModelUpdateFunction(std::function<void(std::vector<XMFLOAT3>& vertices, std::vector<UINT>& indices)> function)
{
    modelUpdateFunction = function;
}

float UIConstructor::GetReflectivity()
{
    return reflectivity;
}