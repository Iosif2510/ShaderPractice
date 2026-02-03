Shader "Custom/BadApple_HLSL"
{
Properties
    {
//        _BaseMap("Albedo", 2D) = "white" {}
        [MainColor] _BaseColor("Main Color", Color) = (1, 1, 1, 1)
        _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5
        _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" "LightMode" = "UniversalForward" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 4.5
            
            // 인스턴싱 관련 키워드
            #pragma multi_compile_instancing
            #pragma instancing_options procedural:setup

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile _ _FORWARD_PLUS

            // URP 핵심 라이브러리 포함
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct CubeData {
                float3 position;
                float4 color;
            };

            // StructuredBuffer 선언 (이름은 C#과 일치시켜야 함)
            #if defined(UNITY_PROCEDURAL_INSTANCING_ENABLED)
                StructuredBuffer<CubeData> _CubeBuffer;
            #endif

            // 회전 행렬 생성 함수 (Y축 기준)
            float4x4 RotationZ(float angle) {
                float s, c;
                sincos(angle, s, c);
                return float4x4(
                    c, -s, 0, 0,
                    s, c, 0, 0,
                    0, 0, 1, 0,
                    0, 0, 0, 1
                );
            }

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float _Metallic;
                float _Smoothness;
            CBUFFER_END

            void setup()
            {
                #if defined(UNITY_PROCEDURAL_INSTANCING_ENABLED)
                    CubeData data = _CubeBuffer[unity_InstanceID];
                    float brightness = data.color.r; 
                    float angle = (1.0 - brightness) * (PI * 0.25f);
                    
                    float s, c;
                    sincos(angle, s, c);

                    // 1. Object To World (위치 + Z축 회전)
                    unity_ObjectToWorld = float4x4(
                        c, -s, 0, data.position.x,
                        s,  c, 0, data.position.y,
                        0,  0, 1, data.position.z,
                        0,  0, 0, 1
                    );

                    // 2. World To Object (역행렬) - 노멀 연산의 핵심
                    // 회전 행렬 부분은 전치(Transpose)하고, 위치는 역변환 적용
                    float3x3 rotT = float3x3(
                        c, s, 0,
                       -s, c, 0,
                        0, 0, 1
                    );
                    
                    unity_WorldToObject = 0;
                    unity_WorldToObject._11_12_13 = rotT._11_12_13;
                    unity_WorldToObject._21_22_23 = rotT._21_22_23;
                    unity_WorldToObject._31_32_33 = rotT._31_32_33;
                    
                    // 역방향 이동: -R^T * translation
                    unity_WorldToObject._14_24_34 = -mul(rotT, data.position);
                    unity_WorldToObject._44 = 1;
                #endif
            }

            struct Attributes {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float4 color : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings vert(Attributes input, uint instanceID : SV_InstanceID)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                #if defined(UNITY_PROCEDURAL_INSTANCING_ENABLED)
                    output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                    output.positionCS = TransformWorldToHClip(output.positionWS);
                    output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                    output.color = _CubeBuffer[instanceID].color;
                #else
                    output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                    output.positionCS = TransformWorldToHClip(output.positionWS);
                    output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                    output.color = float4(1, 1, 1, 1);
                #endif
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);

                // 1. 노멀 정규화 (매우 중요: 이게 안 되면 내적 값이 0이 될 수 있음)
                float3 normalWS = normalize(input.normalWS);
                float3 viewDirWS = SafeNormalize(GetCameraPositionWS() - input.positionWS);

                // 2. 조명 데이터 가져오기
                // 셰이더 내부에서 메인 라이트 데이터를 명시적으로 로드합니다.
                float4 shadowCoord = TransformWorldToShadowCoord(input.positionWS);

                // 3. InputData 채우기
                InputData inputData = (InputData)0;
                
                inputData.positionWS = input.positionWS;
                inputData.normalWS = normalWS;
                inputData.viewDirectionWS = viewDirWS;
                inputData.shadowCoord = shadowCoord;
                inputData.bakedGI = SampleSH(normalWS);
                inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);

                // 4. SurfaceData 채우기
                SurfaceData surfaceData = (SurfaceData)0;
                surfaceData.albedo = _BaseColor.rgb;
                surfaceData.metallic = _Metallic;
                surfaceData.smoothness = _Smoothness;
                surfaceData.specular = float3(0, 0, 0); // 기본값
                surfaceData.occlusion = 1.0;
                surfaceData.alpha = 1.0;

                // 5. 드디어 PBR 호출
                return UniversalFragmentPBR(inputData, surfaceData);
            }
            ENDHLSL
        }

    }
}