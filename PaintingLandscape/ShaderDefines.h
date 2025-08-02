//
//  ShaderDefines.h
//  PaintingLandscape
//
//  Created by Brayton Lordianto on 8/2/25.
//

#ifndef ShaderDefines_h
#define ShaderDefines_h

#define MIN_T 15
#define MAX_T 2000
#define terrainMaxHeight 840 // meters
#define maxSteps 200
#define stepFactor 0.8

#define terrainVariation 600 // controls range of elevation differences
#define baseTerrainHeight 600
#define world2grid 1.0/2000.0
#define gridOrigin float2(1, -2);

#endif /* ShaderDefines_h */
