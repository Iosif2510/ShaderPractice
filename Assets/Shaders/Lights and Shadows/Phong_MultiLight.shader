Shader "Custom/Advanced Lit/Phong Multiple Light"
{
    Properties
    {
        [MainTexture]_BaseMap ("Albedo (RGB)", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
        [HDR]_SpecColor("Specular", Color) = (0.2, 0.2, 0.2)
        _SpecPower("Specular Power", Float) = 10
        [Normal]_BumpMap("Normal Map", 2D) = "bump" {}
        _BumpScale("Normal Scale", Range(0, 2)) = 1
        
        _AmbientIntensity("Ambient Intensity", Range(0, 2)) = 1
        _DiffuseIntensity("Diffuse Intensity", Range(0, 2)) = 1
        _SpecularIntensity("Specular Intensity", Range(0, 2)) = 1
        
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" "LightMode" = "UniversalForward" }
        LOD 200
        
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // Use shader model 3.0 target, to get nicer looking lighting
            #pragma target 3.0

            // This multi_compile declaration is required for the Forward rendering path
            #pragma multi_compile _ _ADDITIONAL_LIGHTS
            
            // This multi_compile declaration is required for the Forward+ rendering path
            #pragma multi_compile _ _FORWARD_PLUS

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RealtimeLights.hlsl"
            
            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 normal       : TEXCOORD1;
                float3 positionWS   : TEXCOORD2;
                float3 viewDir      : TEXCOORD3;
                float3 tangent      : TEXCOORD4;
                float3 bitangent    : TEXCOORD5;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            TEXTURE2D(_BumpMap);
            SAMPLER(sampler_BumpMap);

            CBUFFER_START(UnityPerMaterial)
            
            float4 _BaseMap_ST;
            float4 _BumpMap_ST;
            float _BumpScale;
            half4 _Color;
            half4 _SpecColor;
            float _SpecPower;
            float _AmbientIntensity;
            float _DiffuseIntensity;
            float _SpecularIntensity;
            
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                OUT.normal = TransformObjectToWorldNormal(IN.normalOS);
                OUT.tangent = normalize(TransformObjectToWorldDir(IN.tangentOS.xyz));
                OUT.bitangent = cross(OUT.normal, OUT.tangent) * IN.tangentOS.w;
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.viewDir = normalize(_WorldSpaceCameraPos.xyz - OUT.positionWS);
                return OUT;
            }

            float3 CalculateLighting(half3 baseColor, Light light, float3 normal, float3 viewDir)
            {
                float NdotL = saturate(dot(normal, normalize(light.direction)));
                float3 diffuse = NdotL * light.color.rgb * light.distanceAttenuation * light.shadowAttenuation * _DiffuseIntensity;

                float3 reflectDir = reflect(-light.direction, normal);
                half spec = saturate(dot(reflectDir, viewDir));
                spec = pow(spec, _SpecPower);
                float3 specColor = spec * _SpecColor.rgb * light.color.rgb * light.shadowAttenuation * _SpecularIntensity;

                return diffuse * baseColor + specColor;
            }

            float3 LightLoop(half3 color, InputData inputData)
            {
                float3 lighting = 0;
                
                // Get the main light
                Light mainLight = GetMainLight();
                lighting += CalculateLighting(color, mainLight, inputData.normalWS, inputData.viewDirectionWS);

                // Get additional lights
                #if defined(_ADDITIONAL_LIGHTS)
                
                #if USE_FORWARD_PLUS
                // Additional light loop for non-main directional lights. This block is specific to Forward+.
                UNITY_LOOP for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
                {
                    Light additionalLight = GetAdditionalLight(lightIndex, inputData.positionWS, half4(1,1,1,1));
                    lighting += CalculateLighting(color, additionalLight, inputData.normalWS, inputData.viewDirectionWS);
                }
                #endif
                // Additional light loop.
                uint pixelLightCount = GetAdditionalLightsCount();
                LIGHT_LOOP_BEGIN(pixelLightCount)
                    Light additionalLight = GetAdditionalLight(lightIndex, inputData.positionWS, half4(1,1,1,1));
                    lighting += CalculateLighting(color, additionalLight, inputData.normalWS, inputData.viewDirectionWS);
                LIGHT_LOOP_END
                
                #endif
                return lighting;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                // Phong Shading; interpolate normals per fragmant
                IN.normal = normalize(IN.normal);

                half4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv) * _Color;

                // Calculate Normal
                float3 normalTS = UnpackNormal(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, IN.uv));
                normalTS = normalize(normalTS);
                normalTS.xy *= _BumpScale;
                float3x3 TBN = float3x3(IN.tangent, IN.bitangent, IN.normal);
                float3 normal = normalize(mul(normalTS, TBN));
                
                // Ambient
                half3 ambient = SampleSH(normal) * baseColor * _AmbientIntensity;
                // SampleSH: Samples the ambient light from spherical harmonics based on the normal direction.

                // Diffuse with Normal map

                InputData inputData = (InputData)0;
                inputData.positionWS = IN.positionWS;
                inputData.normalWS = normal;
                inputData.viewDirectionWS = GetWorldSpaceNormalizeViewDir(IN.positionWS);
                inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(IN.positionHCS);
                
                float3 lighting = LightLoop(baseColor, inputData);

                return half4(lighting + ambient, 1);
            }

            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    }
    FallBack "Diffuse"
}
