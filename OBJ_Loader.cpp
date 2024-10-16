#include "OBJ_Loader.h"

using namespace objl;


//----------------------------------------------------------
//Vector2 Implementations
Vector2::Vector2()
{
    X = 0.0f;
    Y = 0.0f;
}

Vector2::Vector2(float X_, float Y_)
{
    X = X_;
    Y = Y_;
}

bool Vector2::operator==(const Vector2& other) const
{
    return (this->X == other.X && this->Y == other.Y);
}

// Bool Not Equals Operator Overload
bool Vector2::operator!=(const Vector2& other) const
{
    return !(this->X == other.X && this->Y == other.Y);
}
// Addition Operator Overload
Vector2 Vector2::operator+(const Vector2& right) const
{
    return Vector2(this->X + right.X, this->Y + right.Y);
}
// Subtraction Operator Overload
Vector2 Vector2::operator-(const Vector2& right) const
{
    return Vector2(this->X - right.X, this->Y - right.Y);
}
// Float Multiplication Operator Overload
Vector2 Vector2::operator*(const float& other) const
{
    return Vector2(this->X * other, this->Y * other);
}
//----------------------------------------------------------


//----------------------------------------------------------
//Vector3 implementations
Vector3::Vector3()
{
    X = 0.0f;
    Y = 0.0f;
    Z = 0.0f;
}

Vector3::Vector3(float X_, float Y_, float Z_)
{
    X = X_;
    Y = Y_;
    Z = Z_;
}

bool Vector3::operator==(const Vector3& other) const
{
    return (this->X == other.X && this->Y == other.Y && this->Z == other.Z);
}

bool Vector3::operator!=(const Vector3& other) const
{
    return !(this->X == other.X && this->Y == other.Y && this->Z == other.Z);
}

Vector3 Vector3::operator+(const Vector3& right) const
{
    return Vector3(this->X + right.X, this->Y + right.Y, this->Z + right.Z);
}

Vector3 Vector3::operator-(const Vector3& right) const
{
    return Vector3(this->X - right.X, this->Y - right.Y, this->Z - right.Z);
}

Vector3 Vector3::operator*(const float& other) const
{
    return Vector3(this->X * other, this->Y * other, this->Z * other);
}

Vector3 Vector3::operator/(const float& other) const
{
    return Vector3(this->X / other, this->Y / other, this->Z / other);
}
//----------------------------------------------------------


//----------------------------------------------------------
//Material implementations
Material::Material()
{
    name;
    Ns = 0.0f;
    Ni = 0.0f;
    d = 0.0f;
    illum = 0;
}
//----------------------------------------------------------


//----------------------------------------------------------
//Mesh implementations
Mesh::Mesh()
{

}

Mesh::Mesh(std::vector<Vertex>& _Vertices, std::vector<unsigned int>& _Indices)
{
    Vertices = _Vertices;
    Indices = _Indices;
}
//----------------------------------------------------------


//----------------------------------------------------------
//

//----------------------------------------------------------