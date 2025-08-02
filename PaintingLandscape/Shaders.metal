//
//  Shaders.metal
//

// File for Metal kernel and shader functions

#include <metal_stdlib>
#include <simd/simd.h>

// Including header shared between this Metal shader code and Swift/C code executing Metal API commands
#import "ShaderTypes.h"

using namespace metal;

typedef struct
{
    float3 position [[attribute(VertexAttributePosition)]];
    float2 texCoord [[attribute(VertexAttributeTexcoord)]];
} Vertex;

typedef struct
{
    float4 position [[position]];
    float2 texCoord;
} ColorInOut;

vertex ColorInOut vertexShader(Vertex in [[stage_in]],
                               ushort amp_id [[amplification_id]],
                               constant UniformsArray & uniformsArray [[ buffer(BufferIndexUniforms) ]])
{
    ColorInOut out;

    Uniforms uniforms = uniformsArray.uniforms[amp_id];
    
    float4 position = float4(in.position, 1.0);
    out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * position;
    out.texCoord = in.texCoord;

    return out;
}

// MARK: STANDARD METHODS
template<typename F>
F bilinear_interpolation(F a, F b, F c, F d, float2 ij) {
    F i0 = mix(a, b, ij.x), i1 = mix(c, d, ij.x); // lerp in i
    return mix(i0, i1, ij.y); // lerp in j
}
template<typename F> F s_curve_1_continous(F t) { // cubic continous
    return t * t * (3.0 - 2.0 * t); // 3t^2 - 2t^3
}
template<typename F> F s_curve_2_continous(F t) { // quintic continous
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0); // 6t^5 - 15t^4 + 10t^3
}
float3 gammaCorrection(float3 color, float gammaFactor = 0.4545) {
    return pow(color, gammaFactor);
}
float hash(float2 p) {
    // random number generator that is seeded by the input coordinates
    p = 50.0 * fract(p * 0.3183099);
    return fract(p.x * p.y * (p.x + p.y));
}

struct Camera {
    float3 position;
    float3 target;
    float cameraRoll;
    float focalLength;
    matrix_float3x3 lookAtMatrix;
    Camera(float3 position, float3 target, float focalLength, float cameraRoll = 0) : position(position), target(target), cameraRoll(cameraRoll), focalLength(focalLength) {
            lookAtMatrix = cam2world_matrix(position, target, cameraRoll);
    }
    
    float3 cam2world(float3 viewDirection) {
        return lookAtMatrix * viewDirection;
    }
    
// camera matrices
private:
    static matrix_float3x3 cam2world_matrix(float3 camPos, float3 target, float3 provisionalUp) {
        float3 view2cam = normalize(camPos - target);
        float3 right = cross(-view2cam, provisionalUp);
        float3 up = cross(right, -view2cam);
        return matrix_float3x3(right, up, -view2cam);
    }
    static matrix_float3x3 cam2world_matrix(float3 camPos, float3 target, float cameraRoll = 0) {
        float3 provisionalUp = float3(sin(cameraRoll), cos(cameraRoll), 0);
        return cam2world_matrix(camPos, target, provisionalUp);
    }
};

matrix_float3x3 setCamera( float3 ro, float3 ta, float cr )
{
    float3 cw = normalize(ta-ro);
    float3 cp = float3(sin(cr), cos(cr),0.0);
    float3 cu = normalize( cross(cw,cp) );
    float3 cv = normalize( cross(cu,cw) );
    return matrix_float3x3( cu, cv, cw );
}


// MARK: post processing
float3 colorCorrection(float3 color) {
    color *= 1.1;
    color -= 0.02;
    color = clamp(color, 0, 1);
    color = gammaCorrection(color);
    color = s_curve_1_continous(color); // gives higher contrast
    
    float3 softGreen = float3(1,.92,1);
    float3 goldenHourRedTint = float3(1.02,.99,.9);
    float bluishShadowBias = 0.1;
    color *= softGreen * goldenHourRedTint;
    color.b += bluishShadowBias;
    return color;
}

// MARK: terrain definition functions
// accepts XZ in grid space
// returns height in [-1, 1]
float normalizedTerrainHeight(float2 XZ) {
    // define point in grid
    float2 cellCorner = floor(XZ);
    float2 positionInCell = fract(XZ);
    float2 smoothedPositionsInCell = s_curve_2_continous(positionInCell);
//     if (positionInCell.x >= .99) return 1.; /// good debug test
    
    // get heights at corners
    float2 directions[] = { float2(0,0), float2(1, 0), float2(0, 1), float2(1, 1) };
    float cellCornersHeight[4];
    for (int i = 0; i < 4; i++)
        cellCornersHeight[i] = hash(cellCorner + directions[i]);
    
    // get height at point in cell
    float interpolatedHeight = bilinear_interpolation(cellCornersHeight[0], cellCornersHeight[1], cellCornersHeight[2], cellCornersHeight[3], smoothedPositionsInCell);
    
    return interpolatedHeight * 2 - 1; // range to [-1, 1]
}

// accepts XZ in world space
// returns in range [0, 1200]
#define terrainVariation 600 // controls range of elevation differences
#define baseTerrainHeight 600
#define world2grid 1.0/2000.0
#define gridOrigin float2(1, -2);
float terrainHeight(float2 XZ) {
    float2 gridSpaceXZ = world2grid * XZ + gridOrigin;
    float normalizedHeight = normalizedTerrainHeight(gridSpaceXZ);
    float height = normalizedHeight * terrainVariation + baseTerrainHeight;
    return height;
}


// MARK: STANDARD RAY TRACING STRUCTURES
#define MIN_T 15
#define MAX_T 2000
#define terrainMaxHeight 840 // meters
#define maxSteps 200
#define stepFactor 0.8
struct Ray {
    float3 origin, direction, inverseDirection;
    float minT, maxT;
    Ray(float3 origin, float3 direction, float minT = MIN_T, float maxT = MAX_T)
        : origin(origin), direction(direction), inverseDirection(1.0 / direction), minT(minT), maxT(maxT) {}
    
    static Ray toScreenUV(float2 uv, Camera cam) {
        float3 viewDirection = normalize(float3(uv, cam.focalLength));
        float3 worldDirection = cam.cam2world(viewDirection);
        return Ray(cam.position, worldDirection, MIN_T, MAX_T);
    }
};

struct RayStep {
    float t;
    float3 position;
    float3 normal;
    float3 metadata;
    float distance;
    bool hit;
    // BSDF parameters not used
    static RayStep miss() { return RayStep(-1); }
    RayStep(float t = -1, bool hit = false, float3 position = float3(0), float3 normal = float3(0), float distance = MAX_T)
        : t(t), hit(hit), position(position), normal(normal), distance(distance) { }
};

// MARK: RayMarching

/// MARK: shoot a ray from `ray` by `t`, checking if it is a hit
float thresholdFrom(int t) { return 0.001 * t; } // this is needed for numerical stability

RayStep march(Ray ray, float t) {
    float threshold = thresholdFrom(t);
    float3 position =ray.origin + ray.direction * t;
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

// MAIN
fragment float4 fragmentShader(
    ColorInOut in [[stage_in]],
    constant UniformsArray& uniformsArray [[ buffer(BufferIndexUniforms) ]]
) {
    // shift in texcoord coordinate frame in accordance with shadertoy
    float2 newTexCoord = float2(in.texCoord.x, 1-in.texCoord.y);
    float2 resolution = float2(1280.0, 720.0);
    float2 fragCoord = newTexCoord * resolution;
    float2 uv = (2.0 * fragCoord - resolution) / resolution.y;
    float3 color;
        
    // ray tracing setup
    float3 ro = float3(0.0, 401.5, 6.0);
    float3 lookDir = uniformsArray.uniforms[0].lookDir;
    float3 target = lookDir + ro;
    float focalLength = -1.5;
    Camera cam(ro, target, focalLength);
    Ray ray = Ray::toScreenUV(uv, cam);
    
    // perform ray marching
    RayStep hit = rayMarchTerrain(ray);
    if (hit.t > 0)
        color = float3(1,1,1);
    else
        color = float3(0,0,0);
    
    // END
    return float4(colorCorrection(color),1);
}
