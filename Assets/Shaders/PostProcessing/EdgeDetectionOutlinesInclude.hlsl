#ifndef SOBEL_OUTLINE_INCLUDED
#define SOBEL_OUTLINE_INCLUDED

static float2 sobelSamplePoints[9] = {
    float2(-1, 1), float2(0, 1), float2(1, 1),
    float2(-1, 0), float2(0, 0), float2(1, 0),
    float2(-1, -1), float2(0, -1), float2(1, -1)
};

static float sobelKernelX[9] = {
    -1, 0, 1,
    -2, 0, 2,
    -1, 0, 1
};

static float sobelKernelY[9] = {
    1, 2, 1,
    0, 0, 0,
    -1, -2, -1
};

void DepthSobel_float(float2 UV, float Thickness, out float Out)
{
    float2 sobel = 0;
    [unroll] for (int i = 0; i < 9; i++)
    {
        float2 depth = SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV + sobelSamplePoints[i] * Thickness);
        sobel += depth * float2(sobelKernelX[i], sobelKernelY[i]);
    }

    Out = length(sobel);
}

#endif
