#ifndef STRUCTS_H
#define STRUCTS_H

#include <cstring>
#include <cmath>

//  struct FName
//     {
//         std::int32_t comparison_index;
//         std::int32_t number;
//     };


//  struct fstring : tarray<wchar_t>
//     {};

struct FMatrix {
    float M[4][4];
    
    FMatrix() {
        memset(M, 0, sizeof(M));
        M[0][0] = M[1][1] = M[2][2] = M[3][3] = 1.0f;
    }
};

struct Vector2 {
    float X, Y;
    
    Vector2() : X(0), Y(0) {}
    Vector2(float x, float y) : X(x), Y(y) {}
};

struct Vector3 {
    float X, Y, Z;
    
    Vector3() : X(0), Y(0), Z(0) {}
    Vector3(float x, float y, float z) : X(x), Y(y), Z(z) {}
    
    float Length() const {
        return sqrt(X*X + Y*Y + Z*Z);
    }
    
    Vector3 operator-(const Vector3& Other) const {
        return Vector3{X - Other.X, Y - Other.Y, Z - Other.Z};
    }

    Vector3 operator *(const Vector3 Factor) {
        return {X * Factor.X, Y * Factor.Y, Z * Factor.Z};
    }

    Vector3 operator /(const Vector3 Divider) {
        return {X / Divider.X, Y / Divider.Y, Z / Divider.Z};
    }

    Vector3 operator +(const Vector3 Additor) {
       return {X + Additor.X, Y + Additor.Y, Z + Additor.Z};
    }

    Vector3 operator -() const {
        return {-X, -Y, -Z};
    }

    Vector3 operator *(const float Factor) {
        return {X * Factor, Y * Factor, Z * Factor};
    }

    Vector3 operator /(const float Divider) {
        return {X / Divider, Y / Divider, Z / Divider};
    }

    float Dot(const Vector3 VectorB) {
        return X * VectorB.X + Y * VectorB.Y + Z * VectorB.Z;
    }

    float Distance(const Vector3 VectorB) {
        Vector3 VectorDelta = *this - VectorB;
        return sqrtf(VectorDelta.Dot(VectorDelta));
    }
};

struct ViewMatrix {
    float Matrix[4][4];
};

#endif /* STRUCTS_H */