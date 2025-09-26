Shader "Custom/Basic Lit/Phong"
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
                float3 normal       : TEXCOORD1;
                float3 lightDir     : TEXCOORD2;
                float3 viewDir      : TEXCOORD3;
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
                OUT.normal = TransformObjectToWorldNormal(IN.normalOS);
                OUT.lightDir = normalize(_MainLightPosition.xyz);
                float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.viewDir = normalize(_WorldSpaceCameraPos.xyz - positionWS);
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
                half3 lighting = NdotL * _MainLightColor.rgb * _DiffuseIntensity;
                lighting += ambient;
                baseColor.rgb *= lighting;
                
                // Specular
                float3 reflectDir = reflect(-IN.lightDir, IN.normal);
                half spec = saturate(dot(reflectDir, IN.viewDir));
                spec = pow(spec, _SpecPower);
                half3 specColor = spec * _SpecColor.rgb;
                baseColor.rgb += specColor * _SpecularIntensity;

                return baseColor;
            }

            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    }
    FallBack "Diffuse"
}
