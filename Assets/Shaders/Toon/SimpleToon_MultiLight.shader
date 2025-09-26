Shader "Custom/Toon/SimpleToon MultiLight"
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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            // Use shader model 3.0 target, to get nicer looking lighting
            #pragma target 3.0

                        // This multi_compile declaration is required for the Forward rendering path
            #pragma multi_compile _ _ADDITIONAL_LIGHTS
            
            // This multi_compile declaration is required for the Forward+ rendering path
            #pragma multi_compile _ _FORWARD_PLUS

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            
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
                float3 viewDir      : TEXCOORD3;
                float3 positionWS   : TEXCOORD4;
                float4 shadowCoords : TEXCOORD5;
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
                VertexPositionInputs positions = GetVertexPositionInputs(IN.positionOS.xyz);
                
                OUT.positionHCS = positions.positionCS;
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                OUT.normal = TransformObjectToWorldNormal(IN.normalOS);
                OUT.positionWS = positions.positionWS;
                OUT.viewDir = normalize(_WorldSpaceCameraPos.xyz - OUT.positionWS);
                
                float4 shadowCoordinates = GetShadowCoord(positions);
                OUT.shadowCoords = shadowCoordinates;
                return OUT;
            }

            float RelativeLuminance(float3 color)
            {
                return dot(color, float3(0.2126, 0.7152, 0.0722));
            }

            float3 CalculateLighting(half3 baseColor, Light light, float3 normal)
            {
                float NdotL = saturate(dot(normal, light.direction));
                NdotL *= light.distanceAttenuation * light.shadowAttenuation;
                float3 diffuse = ceil(NdotL * _BrightnessStep) / _BrightnessStep * light.color * _DiffuseIntensity;
                return diffuse * baseColor;
            }

            float3 LightLoop(half3 color, InputData inputData)
            {
                float3 lighting = 0;

                Light mainLight = GetMainLight();
                lighting += CalculateLighting(color, mainLight, inputData.normalWS);

                // Get additional lights
                #if defined(_ADDITIONAL_LIGHTS)
                
                #if USE_FORWARD_PLUS
                // Additional light loop for non-main directional lights. This block is specific to Forward+.
                UNITY_LOOP for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
                {
                    Light additionalLight = GetAdditionalLight(lightIndex, inputData.positionWS, inputData.shadowCoord);
                    lighting += CalculateLighting(color, additionalLight, inputData.normalWS);
                }
                #endif
                // Additional light loop.
                uint pixelLightCount = GetAdditionalLightsCount();
                LIGHT_LOOP_BEGIN(pixelLightCount)
                    Light additionalLight = GetAdditionalLight(lightIndex, inputData.positionWS, inputData.shadowCoord);
                    lighting += CalculateLighting(color, additionalLight, inputData.normalWS);
                LIGHT_LOOP_END
                #endif

                return lighting;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                // Phong Shading; interpolate normals per fragmant
                IN.normal = normalize(IN.normal);

                half4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv) * _Color;

                // Ambient
                half3 ambient = SampleSH(IN.normal) * baseColor * _AmbientIntensity;
                // SampleSH: Samples the ambient light from spherical harmonics based on the normal direction.

                // Diffuse

                InputData inputData = (InputData)0;
                inputData.positionCS = IN.positionHCS;
                inputData.positionWS = IN.positionWS;
                inputData.normalWS = IN.normal;
                inputData.viewDirectionWS = GetWorldSpaceNormalizeViewDir(IN.positionWS);
                inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(IN.positionHCS);
                inputData.shadowCoord = IN.shadowCoords;

                float3 lighting = LightLoop(baseColor.rgb, inputData);
                
                // float NdotL = saturate(dot(IN.normal, IN.lightDir));
                // half3 lighting = ceil(NdotL * _BrightnessStep) / _BrightnessStep * _MainLightColor.rgb * _DiffuseIntensity;
                // lighting += ambient;
                // baseColor.rgb *= lighting;
                
                // Specular
                // float3 reflectDir = reflect(-IN.lightDir, IN.normal);
                // half spec = saturate(dot(reflectDir, IN.viewDir));
                // spec = floor(pow(spec, _SpecPower) * _SpecularStep) / _SpecularStep;
                // half3 specColor = spec * _SpecColor.rgb;
                // baseColor.rgb += specColor * _SpecularIntensity;

                return half4(lighting + ambient, 1);
            }

            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    }
    FallBack "Diffuse"
}
