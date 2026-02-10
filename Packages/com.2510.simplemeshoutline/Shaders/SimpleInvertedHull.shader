Shader "_2510/SimpleMeshOutline/SimpleInvertedHull"
{
    Properties
    {
        [MainColor] [HDR] _BaseColor("Color", Color) = (1, 1, 1, 1)
        _Thickness("Thickness", Range(0.0, 0.1)) = 0.02
        [IntRange] _StencilRef("Stencil Reference ID", Range(0, 255)) = 4
    }

    SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent+1" "RenderPipeline" = "UniversalPipeline" "LightMode" = "UniversalForward" }
        
        Pass
        {
            Cull Front
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            
            Stencil
            {
                Ref [_StencilRef]
                Comp NotEqual
                Pass Keep
            }
                        
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float4 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float _Thickness;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(IN.normalOS.xyz);

                normalWS = normalize(normalWS);
                positionWS += normalWS * _Thickness;

                OUT.positionHCS = TransformWorldToHClip(positionWS);
                OUT.uv = IN.uv;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half4 color = _BaseColor;
                return color;
            }
            ENDHLSL
        }
    }
}
