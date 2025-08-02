//
//  Shaders.metal
//

// File for Metal kernel and shader functions

#include <metal_stdlib>
#include <simd/simd.h>

// Including header shared between this Metal shader code and Swift/C code executing Metal API commands
#import "ShaderTypes.h"
#include "StandardLib.h"
#include "PostProcessing.h"
#include "Terrain.h"
#include "RayMarching.h"

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