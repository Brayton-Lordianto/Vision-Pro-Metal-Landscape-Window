//
//  PostProcessing.metal
//  PaintingLandscape
//
//  Created by Brayton Lordianto on 8/2/25.
//

#include "PostProcessing.h"
#include "StandardLib.h"

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
