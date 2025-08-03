//
//  StandardLib.metal
//  PaintingLandscape
//
//  Created by Brayton Lordianto on 8/2/25.
//

#include "StandardLib.h"

// MARK: STANDARD METHODS
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
