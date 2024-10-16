#include "OBJ_Loader.h"

using namespace objl;

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
bool Vector2::operator!=(const Vector2 & other) const
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