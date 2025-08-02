//
//  RayMarching.h
//  PaintingLandscape
//
//  Created by Brayton Lordianto on 8/2/25.
//

#ifndef RayMarching_h
#define RayMarching_h

#include <metal_stdlib>
#include <simd/simd.h>
#include "StandardLib.h"
#include "ShaderDefines.h"

using namespace metal;

// MARK: STANDARD RAY TRACING STRUCTURES
struct Ray {
    float3 origin, direction, inverseDirection;
    float minT, maxT;
    Ray(float3 origin, float3 direction, float minT = MIN_T, float maxT = MAX_T);
    
    static Ray toScreenUV(float2 uv, Camera cam);
};


// MARK: RayMarching
struct RayStep {
    float t;
    float3 position;
    float3 normal;
    float3 metadata;
    float distance;
    bool hit;
    // BSDF parameters not used
    static RayStep miss();
    RayStep(float t = -1, bool hit = false, float3 position = float3(0), float3 normal = float3(0), float distance = MAX_T);
};

// the threshold by which we consider a ray to have hit something if t is less than this value
float thresholdFrom(int t);

/// shoot a ray from `ray` by `t`, checking if it is a hit
// a single step of ray marching
RayStep march(Ray ray, float t);

// march a ray until it hits something or exceeds maxT stored in the ray
RayStep rayMarchTerrain(Ray originalRay);

#endif /* RayMarching_h */
