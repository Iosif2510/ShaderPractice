Shader "Custom/Basic Lit/Phong with Gourad Shading"
{
    Properties
    {
        [MainTexture]_BaseMap ("Albedo (RGB)", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
        [HDR]_SpecColor("Specular", Color) = (0.2, 0.2, 0.2)
        _SpecPower("Specular Power", Float) = 10
        
        _AmbientIntensity("Ambient Intensity", Range(0, 2)) = 1
        _DiffuseIntensity("Diffuse Intensity", Range(0, 2)) = 1
        _SpecularIntensity("Specular Intensity", Range(0, 2)) = 1
        
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" }
        LOD 200
        
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
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
                half3 lighting      : COLOR0;
                half3 specColor     : COLOR1;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
            
            float4 _BaseMap_ST;
            half4 _Color;
            half4 _SpecColor;
            half _SpecPower;
            half _AmbientIntensity;
            half _DiffuseIntensity;
            half _SpecularIntensity;
            
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);

                float3 normalWS = normalize(TransformObjectToWorldNormal(IN.normalOS));
                // Ambient
                half3 ambient = SampleSH(normalWS) * _AmbientIntensity;

                // Diffuse
                float3 lightDir = normalize(_MainLightPosition.xyz);
                float NdotL = saturate(dot(normalWS, lightDir));
                OUT.lighting = NdotL * _MainLightColor.rgb * _DiffuseIntensity + ambient;

                // Specular
                float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - positionWS);
                float3 reflectDir = reflect(-lightDir, normalWS);
                half spec = saturate(dot(reflectDir, viewDir));
                spec = pow(spec, _SpecPower);
                OUT.specColor = spec * _SpecColor.rgb * _SpecularIntensity;
                
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv) * _Color;
                
                baseColor.rgb *= IN.lighting;
                baseColor.rgb += IN.specColor;

                return baseColor;
            }

            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    }
    FallBack "Diffuse"
}
