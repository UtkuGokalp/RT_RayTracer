#define _CRT_SECURE_NO_WARNINGS

#include "OBJ_FileManager.h"

#include <cstdio>

using namespace objl;

bool OBJFileManager::LoadObjFile(std::string path, std::vector<objl::Vertex>& vertices, std::vector<unsigned int>& indices)
{
    std::ifstream file(path);
    if (!file.is_open())
        return false;

    std::string currentLine;
    while (std::getline(file, currentLine))
    {
        if (currentLine == "" || currentLine == "\n")
        {
            continue;
        }
        if (currentLine[0] == 'v') //Vertex
        {
            float v1, v2, v3;
            (void)sscanf(currentLine.c_str(), "v %f %f %f", &v1, &v2, &v3);

            objl::Vertex v;
            v.Position = Vector3(v1, v2, v3); //The important part
            v.Normal = Vector3(0, 0, 0);
            v.TextureCoordinate = Vector2(0, 0);

            vertices.push_back(v);
        }
        else if (currentLine[0] == 'f') //Face (3 indices)
        {
            unsigned int i1, i2, i3;
            (void)sscanf(currentLine.c_str(), "f %u %u %u", &i1, &i2, &i3);
            //subtract 1 bc .obj file indices start from 1
            indices.push_back(i1 - 1);
            indices.push_back(i2 - 1);
            indices.push_back(i3 - 1);
        }
    }
    return true;
    
    /*
    Loader objLoader;
    //Loaded is false when the file doesn't exist, doesn't have .obj extension or has no vertices, meshes, nor colors to load.
    bool loaded = objLoader.LoadFile(path);
    
    if (loaded)
    {
        std::vector<Mesh>& meshes = objLoader.LoadedMeshes;
        Mesh firstMesh = meshes[0];
        for (auto& vertex : firstMesh.Vertices)
        {
            vertices.push_back(vertex);
        }
        for (auto& index : firstMesh.Indices)
        {
            indices.push_back(index);
        }
    }
    return loaded;
    */
}