Shader "Custom/SDF_Raymarching"
{
    Properties
    {
        _BaseColor("Base Color", Color) = (1,1,1,1)
        _SphereParams("Sphere Parameters", Vector) = (0, 0, 0, 1)
    }
    SubShader
    {
        // 불투명 오브젝트처럼 보이기 위해 RenderType 설정
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" "Queue"="Geometry" }

        Pass
        {
            // 깊이 테스트를 무시하고 항상 위에 그리도록 설정
            ZTest Always
            ZWrite Off
            Cull Off
            Blend SrcAlpha OneMinusSrcAlpha // 배경과 합성하기 위해 블렌딩 추가
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _SphereParams;
                float4 _BaseColor;
            CBUFFER_END

            struct Attributes {
                uint vertexID : SV_VertexID; // Full Screen Pass는 ID를 쓰는 게 가장 정확합니다.
            };

            struct Varyings {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            // SDF 및 Normal 함수 (이전과 동일)
            float map(float3 p) {
                return length(p - _SphereParams.xyz) - _SphereParams.w;
            }

            float3 getNormal(float3 p) {
                float2 e = float2(0.001, 0);
                return normalize(float3(
                    map(p + e.xyy) - map(p - e.xyy),
                    map(p + e.yxy) - map(p - e.yxy),
                    map(p + e.yyx) - map(p - e.yyx)
                ));
            }

            Varyings vert(Attributes input) {
                Varyings output;
                // [수정] Full Screen Pass용 절차적 삼각형 생성 (가장 안전한 방식)
                output.positionCS = GetFullScreenTriangleVertexPosition(input.vertexID);
                output.uv = GetFullScreenTriangleTexCoord(input.vertexID);
                return output;
            }

            half4 frag(Varyings input) : SV_Target {
                // return half4(1, 0, 0, 1);
                float2 ndc = input.uv * 2.0 - 1.0;

                // // aspect ratio 보정 (게임뷰 해상도 대응)
                // // 프리뷰와 달리 게임뷰는 종횡비가 제각각입니다.
                // float aspect = _ScreenParams.x / _ScreenParams.y;
                // ndc.x *= aspect;
                
                float3 ro = _WorldSpaceCameraPos;
                
                float4 viewPos = mul(unity_CameraInvProjection, float4(ndc, 0, 1));
                viewPos.xyz /= viewPos.w;

                // 뷰 공간 방향을 월드 공간 방향으로 변환 (Ray Direction)
                // unity_MatrixInvV는 뷰 공간을 월드 공간으로 바꿔줍니다.
                float3 rd = normalize(mul((float3x3)unity_MatrixInvV, viewPos.xyz));

                // 3. 레이마칭 루프
                float t = 0;
                float3 p;
                bool hit = false;

                for(int i = 0; i < 128; i++) {
                    p = ro + rd * t;
                    float d = map(p);
                    if(d < 0.001) {
                        hit = true;
                        break;
                    }
                    t += d;
                    if(t > 50.0) break;
                }

                if(!hit) return half4(0, 0, 0, 0);
                float rawDepth = SampleSceneDepth(input.uv);
                float sceneZ = LinearEyeDepth(rawDepth, _ZBufferParams);
                if (t > sceneZ) return half4(0,0,0,0);

                // 4. 조명 계산
                float3 normal = getNormal(p);
                float3 lightDir = _MainLightPosition.xyz; // URP 메인 라이트 방향
                float diff = max(0.1, dot(normal, lightDir));

                return half4(_BaseColor.rgb * diff, 1.0);
            }
            ENDHLSL
        }
    }
}