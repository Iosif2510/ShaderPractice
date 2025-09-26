Shader "Custom/Toon/SimpleToon ReceiveShadow"
{
    Properties
    {
        [MainTexture]_BaseMap ("Albedo (RGB)", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
        
        _AmbientIntensity("Ambient Intensity", Range(0, 2)) = 1
        _DiffuseIntensity("Diffuse Intensity", Range(0, 2)) = 1
        
        _BrightnessStep("Brightness Step", Integer) = 3
        _SpecularStep("Specular Step", Integer) = 1
        
        _OutlineColor ("Outline Color", Color) = (0,0,0,1)
        _OutlineSize ("Outline Size", Range(0.0, 0.1)) = 0.02
        
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" }
        LOD 200
        
        Pass
        {
            Name "Outline"
            Cull Front
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #pragma target 3.0

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
            };

            CBUFFER_START(UnityPerMaterial)

            half4 _OutlineColor;
            half _OutlineSize;
            
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                float3 pos = IN.positionOS.xyz + IN.normalOS * _OutlineSize;
                OUT.positionHCS = TransformObjectToHClip(pos);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                return _OutlineColor;
            }
            
            ENDHLSL
        }

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            Name "Distinct Brightness"
            Cull Back
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            // Use shader model 3.0 target, to get nicer looking lighting
            #pragma target 3.0
            
            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
                float3 normalOS     : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 normal       : TEXCOORD1;
                float3 lightDir     : TEXCOORD2;
                float3 viewDir      : TEXCOORD3;
                float4 shadowCoord  : TEXCOORD4;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
            
            float4 _BaseMap_ST;
            half4 _Color;
            half _AmbientIntensity;
            half _DiffuseIntensity;
            int _BrightnessStep;
            
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                OUT.normal = TransformObjectToWorldNormal(IN.normalOS);
                OUT.lightDir = normalize(_MainLightPosition.xyz);
                float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.viewDir = normalize(_WorldSpaceCameraPos.xyz - positionWS);

                // Get the VertexPositionInputs for the vertex position  
                VertexPositionInputs positions = GetVertexPositionInputs(IN.positionOS.xyz);

                // Convert the vertex position to a position on the shadow map
                float4 shadowCoordinates = GetShadowCoord(positions);
                // Pass the shadow coordinates to the fragment shader
                OUT.shadowCoord = shadowCoordinates;
                
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                // Phong Shading; interpolate normals per fragmant
                IN.normal = normalize(IN.normal);

                half4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv) * _Color;

                // Ambient
                half3 ambient = SampleSH(IN.normal) * _AmbientIntensity;
                // SampleSH: Samples the ambient light from spherical harmonics based on the normal direction.

                // Diffuse
                float NdotL = saturate(dot(IN.normal, IN.lightDir));
                half3 lighting = ceil(NdotL * _BrightnessStep) / _BrightnessStep * _MainLightColor.rgb * _DiffuseIntensity;

                half shadowAmount = ceil(MainLightRealtimeShadow(IN.shadowCoord) * _BrightnessStep) / _BrightnessStep;

                return baseColor * half4(lighting * shadowAmount + ambient, 1);
            }

            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    }
    FallBack "Diffuse"
}
