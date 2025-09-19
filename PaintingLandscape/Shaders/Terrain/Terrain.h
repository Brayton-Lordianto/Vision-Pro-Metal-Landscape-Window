//
//  Terrain.h
//  PaintingLandscape
//
//  Created by Brayton Lordianto on 8/2/25.
//

#ifndef Terrain_h
#define Terrain_h

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

// accepts XZ in grid space
// returns height in [-1, 1]
float normalizedTerrainNoise(float2 XZ);
float normalizedTerrainHeight(float2 XZ, float roughness); // a simple FBM noise function in context of a terrain 

// accepts XZ in world space
// returns in range [0, 1200]
float terrainHeight(float2 XZ);

#endif /* Terrain_h */
