//
//  Terrain.metal
//  PaintingLandscape
//
//  Created by Brayton Lordianto on 8/2/25.
//

#include "Terrain.h"
#include "StandardLib.h"
#include "ShaderDefines.h"

// MARK: terrain definition functions
// accepts XZ in grid space
// returns height in [-1, 1]
float normalizedTerrainHeight(float2 XZ) {
    // define point in grid
    float2 cellCorner = floor(XZ);
    float2 positionInCell = fract(XZ);
    float2 smoothedPositionsInCell = s_curve_2_continous(positionInCell);
    
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
float terrainHeight(float2 XZ) {
    float2 gridSpaceXZ = world2grid * XZ + gridOrigin;
    float normalizedHeight = normalizedTerrainHeight(gridSpaceXZ);
    float height = normalizedHeight * terrainVariation + baseTerrainHeight;
    return height;
}
