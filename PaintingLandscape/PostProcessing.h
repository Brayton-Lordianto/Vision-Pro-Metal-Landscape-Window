//
//  PostProcessing.h
//  PaintingLandscape
//
//  Created by Brayton Lordianto on 8/2/25.
//

#ifndef PostProcessing_h
#define PostProcessing_h

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

float3 colorCorrection(float3 color);

#endif /* PostProcessing_h */
