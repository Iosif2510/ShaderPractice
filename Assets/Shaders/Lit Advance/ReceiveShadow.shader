Shader "Custom/Advanced Lit/Receive Shadow"
{
    Properties
    {
        [MainTexture] _BaseMap ("Albedo (RGB)", 2D) = "white" {}
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
        Tags { "RenderType" = "AlphaTest" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 normal       : TEXCOORD1;
                float3 lightDir     : TEXCOORD2;
                float3 viewDir      : TEXCOORD3;
                float3 tangent      : TEXCOORD4;
                float3 bitangent    : TEXCOORD5;
                float4 shadowCoords : TEXCOORD6;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            TEXTURE2D(_BumpMap);
            SAMPLER(sampler_BumpMap);

            CBUFFER_START(UnityPerMaterial)
            
            float4 _BaseMap_ST;
            half4 _Color;
            float4 _BumpMap_ST;
            half _BumpScale;
            half4 _SpecColor;
            half _SpecPower;
            half _AmbientIntensity;
            half _DiffuseIntensity;
            half _SpecularIntensity;
            
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                OUT.normal = TransformObjectToWorldNormal(IN.normalOS);
                OUT.tangent = normalize(TransformObjectToWorldDir(IN.tangentOS.xyz));
                OUT.bitangent = cross(OUT.normal, OUT.tangent) * IN.tangentOS.w;
                OUT.lightDir = normalize(_MainLightPosition.xyz);
                float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.viewDir = normalize(_WorldSpaceCameraPos.xyz - positionWS);

                // Get the VertexPositionInputs for the vertex position  
                VertexPositionInputs positions = GetVertexPositionInputs(IN.positionOS.xyz);

                // Convert the vertex position to a position on the shadow map
                float4 shadowCoordinates = GetShadowCoord(positions);
                // Pass the shadow coordinates to the fragment shader
                OUT.shadowCoords = shadowCoordinates;

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                // Phong Shading; interpolate normals per fragmant
                IN.normal = normalize(IN.normal);

                half4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv) * _Color;

                float3 normalTS = UnpackNormal(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, IN.uv));
                normalTS = normalize(normalTS);
                normalTS.xy *= _BumpScale;
                float3x3 TBN = float3x3(IN.tangent, IN.bitangent, IN.normal);
                float3 normal = normalize(mul(normalTS, TBN));

                // Ambient
                half3 ambient = SampleSH(normal) * _AmbientIntensity;
                // SampleSH: Samples the ambient light from spherical harmonics based onon the normal direction.

                // Diffuse
                float NdotL = saturate(dot(normal, IN.lightDir));
                half3 diffuse = NdotL * _MainLightColor.rgb * _DiffuseIntensity;
                
                // Specular
                float3 reflectDir = reflect(-IN.lightDir, normal);
                half spec = saturate(dot(reflectDir, IN.viewDir));
                spec = pow(spec, _SpecPower);
                half3 specular = spec * _SpecColor.rgb * _SpecularIntensity;
                
                // Get the value from the shadow map at the shadow coordinates
                half shadowAmount = MainLightRealtimeShadow(IN.shadowCoords);

                // Set the fragment color to the shadow value
                return half4((diffuse + specular) * shadowAmount + ambient, 1) * baseColor;
            }
            
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    }
    FallBack "Diffuse"
}