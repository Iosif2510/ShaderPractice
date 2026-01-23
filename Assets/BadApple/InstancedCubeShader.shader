Shader "Custom/InstancedCubeShader"
{
    Properties {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // procedural:setup 부분을 통해 인스턴싱 데이터를 연결합니다.
        #pragma target 4.5
        #pragma surface surf Standard addshadow fullforwardshadows
        #pragma instancing_options procedural:setup

        struct CubeData {
            float3 position;
            float4 color;
        };

        // 컴퓨트 셰이더에서 썼던 것과 동일한 버퍼
        #if defined(UNITY_PROCEDURAL_INSTANCING_ENABLED)
            StructuredBuffer<CubeData> _CubeBuffer;
        #endif

        sampler2D _MainTex;
        struct Input {
            float2 uv_MainTex;
            float4 color : COLOR;
        };

        half _Glossiness;
        half _Metallic;

        // 이 함수가 각 큐브 인스턴스의 변환 행렬을 결정합니다.
        void setup() {
            #if defined(UNITY_PROCEDURAL_INSTANCING_ENABLED)
                CubeData data = _CubeBuffer[unity_InstanceID];
                
                // 큐브의 위치와 크기(Scale)를 행렬로 변환
                float3 pos = data.position;
                unity_ObjectToWorld = float4x4(
                    1, 0, 0, pos.x,
                    0, 1, 0, pos.y,
                    0, 0, 1, pos.z,
                    0, 0, 0, 1
                );
                
                // 역행렬 계산 (셰이더 필수 작업)
                unity_WorldToObject = unity_ObjectToWorld;
                unity_WorldToObject._14_24_34 *= -1;
                unity_WorldToObject._11_22_33 = 1.0f / unity_WorldToObject._11_22_33;
            #endif
        }

        void surf (Input IN, inout SurfaceOutputStandard o) {
            #if defined(UNITY_PROCEDURAL_INSTANCING_ENABLED)
                o.Albedo = _CubeBuffer[unity_InstanceID].color.rgb;
            #else
                o.Albedo = float3(1, 1, 1);
            #endif
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = 1.0;
        }
        ENDCG
    }
    FallBack "Diffuse"
}