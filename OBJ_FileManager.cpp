#include "OBJ_FileManager.h"

using namespace objl;

bool OBJFileManager::LoadObjFile(std::string path, std::vector<objl::Vertex>& vertices, std::vector<unsigned int>& indices)
{
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
}