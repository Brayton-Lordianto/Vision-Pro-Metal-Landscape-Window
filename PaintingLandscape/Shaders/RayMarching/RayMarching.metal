//
//  RayMarching.metal
//  PaintingLandscape
//
//  Created by Brayton Lordianto on 8/2/25.
//

#include "RayMarching.h"
#include "../Terrain/Terrain.h"

Ray::Ray(float3 origin, float3 direction, float minT, float maxT)
    : origin(origin), direction(direction), inverseDirection(1.0 / direction), minT(minT), maxT(maxT) {}

Ray Ray::toScreenUV(float2 uv, Camera cam) {
    float3 viewDirection = normalize(float3(uv, cam.focalLength));
    float3 worldDirection = cam.cam2world(viewDirection);
    return Ray(cam.position, worldDirection, MIN_T, MAX_T);
}

// MARK: RayMarching
RayStep RayStep::miss() { return RayStep(-1); }

RayStep::RayStep(float t, bool hit, float3 position, float3 normal, float distance)
    : t(t), hit(hit), position(position), normal(normal), distance(distance) { }

float thresholdFrom(int t) { return 0.001 * t; } // this is needed for numerical stability

RayStep march(Ray ray, float t) {
    float threshold = thresholdFrom(t);
    float3 position = ray.origin + ray.direction * t;
    float height = terrainHeight(float2(position.x, position.z));
    float distance = position.y - height;
    bool hit = (distance < threshold);
    return RayStep(t, hit, position, float3(0), distance);
}

RayStep rayMarchTerrain(Ray originalRay) {
    // for early out optimization to high terrain heights
    float tToCeiling = (terrainMaxHeight - originalRay.origin.y) / originalRay.direction.y;
    if (tToCeiling > 0.0) // true if pointing down. only use max t then.
        originalRay.maxT = min(originalRay.maxT, tToCeiling);
    
    // main loop
    float t = originalRay.minT, threshold;
    RayStep prevStep, currStep;
    for (int _ = 0; _ < maxSteps; ++_) {
        currStep = march(originalRay, t);
        if (currStep.hit) break;
        
        prevStep = currStep;
        t += prevStep.distance * stepFactor;
        if (t > originalRay.maxT) // it is too far, so just stop here and call it a miss
            return RayStep::miss();
    }
    
    // return your t value by linearly interpolating to get
    // where height = threshold (super close to terrain)
    if (!currStep.hit) return RayStep::miss();
    threshold = thresholdFrom(currStep.t);
    float finalDistDiff = currStep.distance - prevStep.distance;
    float goalDist = threshold - prevStep.distance;
    currStep.t = mix(prevStep.t, currStep.t, goalDist / finalDistDiff);
    return currStep;
}
