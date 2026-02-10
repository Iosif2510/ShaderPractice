Shader "_2510/SimpleMeshOutline/StencilOverwrite"
{
    Properties
    {
        // Define a material property for the stencil reference
        [IntRange] _StencilRef ("Stencil Reference ID", Range(0, 255)) = 4
        // Other properties...
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "Queue" = "Geometry-1" }

        Pass
        {
            ColorMask 0
            ZWrite Off
            
            Stencil
            {
                Ref [_StencilRef]         // The reference value to write
                Comp Always   // The stencil test always passes
                Pass Replace  // If both stencil and depth tests pass, replace the buffer value with the reference value
                Fail Keep     // If the stencil test fails, keep the current value
//                ZFail Keep    // If the depth test fails, keep the current value
//                WriteMask 255 // Ensures all 8 bits of the stencil buffer can be written to
            }
            
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                return 0;
            }
            ENDHLSL
        }
    }
}
