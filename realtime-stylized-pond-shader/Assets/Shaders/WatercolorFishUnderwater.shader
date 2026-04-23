Shader "Pond/WatercolorFishUnderwater"
{
    Properties
    {
        _FishTexture ("Fish Texture", 2D) = "white" {}
        _DepthTint ("Depth Tint", Color) = (0.22, 0.48, 0.51, 1)
        _DistortionStrength ("Distortion Strength", Range(0, 1)) = 0.18
        _FishOpacity ("Fish Opacity", Range(0, 1)) = 0.75
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Transparent"
            "Queue" = "Transparent-20"
        }

        Pass
        {
            Name "UnderwaterFish"
            Tags { "LightMode" = "UniversalForward" }

            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Off

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            TEXTURE2D(_FishTexture);
            SAMPLER(sampler_FishTexture);

            CBUFFER_START(UnityPerMaterial)
                float4 _FishTexture_ST;
                float4 _DepthTint;
                float _DistortionStrength;
                float _FishOpacity;
            CBUFFER_END

            float Hash21(float2 p)
            {
                p = frac(p * float2(113.7, 271.9));
                p += dot(p, p + 19.19);
                return frac(p.x * p.y);
            }

            float Noise(float2 p)
            {
                float2 i = floor(p);
                float2 f = frac(p);
                f = f * f * (3.0 - 2.0 * f);
                float a = Hash21(i);
                float b = Hash21(i + float2(1.0, 0.0));
                float c = Hash21(i + float2(0.0, 1.0));
                float d = Hash21(i + float2(1.0, 1.0));
                return lerp(lerp(a, b, f.x), lerp(c, d, f.x), f.y);
            }

            Varyings Vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = input.uv;
                return output;
            }

            half4 Frag(Varyings input) : SV_Target
            {
                float2 uv = TRANSFORM_TEX(input.uv, _FishTexture);
                float ripple = Noise(input.uv * 9.0 + _Time.y * 0.35);
                uv += (ripple - 0.5) * _DistortionStrength * 0.05;

                half4 fish = SAMPLE_TEXTURE2D(_FishTexture, sampler_FishTexture, uv);
                float3 tinted = lerp(fish.rgb, _DepthTint.rgb, 0.32);
                return half4(tinted, fish.a * _FishOpacity);
            }
            ENDHLSL
        }
    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
