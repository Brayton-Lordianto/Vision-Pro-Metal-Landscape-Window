//
//  Terrain.metal
//  PaintingLandscape
//
//  Created by Brayton Lordianto on 8/2/25.
//

#include "Terrain.h"
#include "../Shared/StandardLib.h"
#include "../Shared/ShaderDefines.h"

// MARK: terrain definition functions
// accepts XZ in grid space
// returns height in [-1, 1]
float normalizedTerrainNoise(float2 XZ) {
    // define point in grid
    float2 cellCorner = floor(XZ);
    float2 positionInCell = fract(XZ);
    float2 smoothedPositionsInCell = s_curve_2_continous(positionInCell);
    
    // get noise value at corners
    float2 directions[] = { float2(0,0), float2(1, 0), float2(0, 1), float2(1, 1) };
    float cellCornersNoise[4];
    for (int i = 0; i < 4; i++)
        cellCornersNoise[i] = hash(cellCorner + directions[i]);
    
    // get noise value at point in cell
    float interpolatedNoise = bilinear_interpolation(cellCornersNoise[0], cellCornersNoise[1], cellCornersNoise[2], cellCornersNoise[3], smoothedPositionsInCell);
    
    return interpolatedNoise * 2 - 1; // range to [-1, 1]
}

#define fbmOctaves 9
float normalizedTerrainHeight(float2 XZ, float roughness) { // a simple FBM noise function in context of a terrain
//    return normalizedTerrainNoise(XZ);
    matrix_float2x2 fbm2dRotation = matrix_float2x2( 0.8, -0.6,
                                                    0.6, 0.8 );
    float amplitudeFactor = pow(2, -roughness); // 1 / 2^{r}
    float frequencyFactor = 1.9;
    float amplitude = 1; // 1 / 2^{r*i=0}
    float frequency = 1; // 2*{i=0}
    float result = 0;
    float noise;
    for (int i = 0; i < fbmOctaves; ++i) {
        // rotate before adding: only works well in 2D -> noise(R(theta) x 2^i x XZ)
        noise = normalizedTerrainNoise(frequency * fbm2dRotation * XZ);
        result += amplitude * noise;
        // updates
        amplitude *= amplitudeFactor;
        frequency *= frequencyFactor;
    }
    return result;
}

// accepts XZ in world space
// returns in range [0, 1200]
float terrainHeight(float2 XZ) {
    float2 gridSpaceXZ = world2grid * XZ + gridOrigin;
    float normalizedHeight = normalizedTerrainHeight(gridSpaceXZ, 1);
    float height = normalizedHeight * terrainVariation + baseTerrainHeight;
    return height;
}
