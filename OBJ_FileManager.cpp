#define _CRT_SECURE_NO_WARNINGS

#include "OBJ_FileManager.h"

#include <cstdio>
#include <sstream>

using namespace objl;

bool OBJFileManager::LoadObjFile(std::string path, std::vector<objl::Vertex>& vertices, std::vector<unsigned int>& indices)
{
    std::ifstream file(path);
    if (!file.good())
    {
        return false;
    }
    std::string str;
    unsigned int max_index = 0;
    while (std::getline(file, str))
    {   
        std::string data = std::string(str.c_str() + 1);
        std::stringstream ss = std::stringstream(data);
        if (str[0] == 'v') //vertex
        {
            float x, y, z;
            ss >> x >> y >> z;
            objl::Vertex v;
            v.Position = objl::Vector3(x, y, z);
            vertices.push_back(v);
        }
        else if (str[0] == 'f') //face
        {
            unsigned int i0, i1, i2;
            ss >> i0 >> i1 >> i2;
            i0--;
            i1--;
            i2--;
            unsigned int currentMax = 0;
            if (i0 > i1 && i0 > i2)
            {
                currentMax = i0;
            }
            if (i1 > i0 && i1 > i2)
            {
                currentMax = i1;
            }
            if (i2 > i1 && i2 > i0)
            {
                currentMax = i2;
            }

            if (currentMax > max_index)
            {
                max_index = currentMax;
            }
            
            indices.push_back(i0);
            indices.push_back(i1);
            indices.push_back(i2);
        }
        else
        {
            continue;
        }
    }
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
    return true;
}