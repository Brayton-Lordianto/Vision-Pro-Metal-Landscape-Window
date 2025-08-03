//
//  StandardLib.h
//  PaintingLandscape
//
//  Created by Brayton Lordianto on 8/2/25.
//

#ifndef StandardLib_h
#define StandardLib_h

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

// MARK: STANDARD METHODS
// Template Implementations must be here!
template<typename F>
F bilinear_interpolation(F a, F b, F c, F d, float2 ij) {
    F i0 = mix(a, b, ij.x), i1 = mix(c, d, ij.x); // lerp in i
    return mix(i0, i1, ij.y); // lerp in j
}

// 3t^2 - 2t^3
template<typename F>
F s_curve_1_continous(F t) {
    return t * t * (3.0 - 2.0 * t); // cubic continous
}

// 6t^5 - 15t^4 + 10t^3
template<typename F>
F s_curve_2_continous(F t) {
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0); // quintic continous
}

float3 gammaCorrection(float3 color, float gammaFactor = 0.4545);

float hash(float2 p);

struct Camera {
    float3 position;
    float3 target;
    float cameraRoll;
    float focalLength;
    matrix_float3x3 lookAtMatrix;
    Camera(float3 position, float3 target, float focalLength, float cameraRoll = 0);
    
    float3 cam2world(float3 viewDirection);
    
private:
    static matrix_float3x3 cam2world_matrix(float3 camPos, float3 target, float3 provisionalUp);
    static matrix_float3x3 cam2world_matrix(float3 camPos, float3 target, float cameraRoll = 0);
};

#endif /* StandardLib_h */
