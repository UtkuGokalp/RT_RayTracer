#pragma once

#include "DirectXMath.h"
#include "OBJ_Loader.h"

class OBJFileManager
{
public:
    /// <summary>
    /// Reads the OBJ file in the given path and adds it to the passed in vectors.
    /// </summary>
    /// <param name="path">Path of the obj file.</param>
    /// <param name="vertices">The vector to hold the loaded vertices.</param>
    /// <param name="indices">The vector to hold the loaded indices.</param>
    /// <returns>Returns whether the file was read successfully.</returns>
    bool LoadObjFile(std::string path, std::vector<objl::Vertex>& vertices, std::vector<unsigned int>& indices);
};