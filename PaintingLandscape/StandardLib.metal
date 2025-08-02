//
//  StandardLib.metal
//  PaintingLandscape
//
//  Created by Brayton Lordianto on 8/2/25.
//

#include "StandardLib.h"

// MARK: STANDARD METHODS
template<typename F>
F bilinear_interpolation(F a, F b, F c, F d, float2 ij) {
    F i0 = mix(a, b, ij.x), i1 = mix(c, d, ij.x); // lerp in i
    return mix(i0, i1, ij.y); // lerp in j
}
template<typename F> F s_curve_1_continous(F t) {
    return t * t * (3.0 - 2.0 * t); // 3t^2 - 2t^3
}
template<typename F> F s_curve_2_continous(F t) { 
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0); // 6t^5 - 15t^4 + 10t^3
}
float3 gammaCorrection(float3 color, float gammaFactor) {
    return pow(color, gammaFactor);
}
float hash(float2 p) {
    // random number generator that is seeded by the input coordinates
    p = 50.0 * fract(p * 0.3183099);
    return fract(p.x * p.y * (p.x + p.y));
}

Camera::Camera(float3 position, float3 target, float focalLength, float cameraRoll) : position(position), target(target), cameraRoll(cameraRoll), focalLength(focalLength) {
        lookAtMatrix = cam2world_matrix(position, target, cameraRoll);
}

float3 Camera::cam2world(float3 viewDirection) {
    return lookAtMatrix * viewDirection;
}

// camera matrices
// references: https://cs184.eecs.berkeley.edu/sp25/assets/lectures/04-transforms.pdf#page=68 , https://www.youtube.com/watch?v=G6skrOtJtbM&pp=ygUQbG9vayBhdCAgbWF0cml4INIHCQnHCQGHKiGM7w%3D%3D
matrix_float3x3 Camera::cam2world_matrix(float3 camPos, float3 target, float3 provisionalUp) {
    float3 view2cam = normalize(camPos - target);
    float3 right = cross(-view2cam, provisionalUp);
    float3 up = cross(right, -view2cam);
    return matrix_float3x3(right, up, -view2cam);
}
matrix_float3x3 Camera::cam2world_matrix(float3 camPos, float3 target, float cameraRoll) {
    float3 provisionalUp = float3(sin(cameraRoll), cos(cameraRoll), 0);
    return cam2world_matrix(camPos, target, provisionalUp);
}
