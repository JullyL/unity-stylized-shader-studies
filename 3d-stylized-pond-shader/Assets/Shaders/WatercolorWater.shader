Shader "Stylized/WatercolorWater"
{
    Properties
    {
        _BaseColor("Base Color", Color) = (0.38, 0.72, 0.68, 0.92)
        _BaseColor2("Depth Tint", Color) = (0.22, 0.52, 0.60, 0.95)

        // Large wash: broad, slow pigment blobs (guide: 1.5–4.0)
        _NoiseScale("Large Wash Scale", Float) = 2.5
        _NoiseSpeed("Animation Speed", Range(0.0, 0.2)) = 0.03
        // Keep subtle — multiplicative modulation, not additive (guide: 0.05–0.15)
        _NoiseStrength("Large Wash Strength", Range(0.0, 0.20)) = 0.10

        // Secondary wash: medium blobs for hue variation (guide: 3.0–6.0)
        _SecondaryNoiseScale("Secondary Wash Scale", Float) = 4.5
        _SecondaryNoiseStrength("Secondary Wash Strength", Range(0.0, 0.15)) = 0.07

        // Almost imperceptible — just enough to feel alive (guide: 0.002–0.008)
        _DistortionStrength("UV Distortion Strength", Range(0.0, 0.02)) = 0.005

        // Low frequency paper grain — NOT the old *18 tiling (guide: 0.5–2.0)
        _PaperTextureScale("Paper Texture Tiling", Float) = 1.5
        _PaperTexture("Paper Texture", 2D) = "white" {}
        _PaperTextureStrength("Paper Influence", Range(0.0, 2.0)) = 0.08

        // Wide soft zone for watercolor bleed (guide: 0.6–0.9)
        _EdgeSoftness("Edge Softness", Range(0.1, 1.0)) = 0.75
        _EdgeNoiseStrength("Edge Noise Strength", Range(0.0, 0.20)) = 0.10

        // Watercolor needs visible desaturation + softness (guide: 0.2–0.35 / 0.2–0.4)
        _FinalDesaturation("Final Desaturation", Range(0.0, 0.4)) = 0.25
        _PaintSoftness("Paint Softness", Range(0.0, 0.4)) = 0.28
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Transparent"
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Transparent"
        }

        Pass
        {
            Name "WatercolorForward"
            Tags { "LightMode" = "UniversalForward" }

            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float4 _BaseColor2;
                float _NoiseScale;
                float _NoiseSpeed;
                float _NoiseStrength;
                float _SecondaryNoiseScale;
                float _SecondaryNoiseStrength;
                float _DistortionStrength;
                float _PaperTextureScale;
                float _PaperTextureStrength;
                float _EdgeSoftness;
                float _EdgeNoiseStrength;
                float _FinalDesaturation;
                float _PaintSoftness;
            CBUFFER_END

            TEXTURE2D(_PaperTexture);
            SAMPLER(sampler_PaperTexture);

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            float Hash21(float2 p)
            {
                float3 p3 = frac(float3(p.x, p.y, p.x) * 0.1031);
                p3 += dot(p3, p3.yzx + 33.33);
                return frac((p3.x + p3.y) * p3.z);
            }

            float ValueNoise(float2 p)
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

            float2 RotateUV(float2 uv, float angle)
            {
                float s = sin(angle);
                float c = cos(angle);
                float2 p = uv - 0.5;
                return float2(p.x * c - p.y * s, p.x * s + p.y * c) + 0.5;
            }

            // 2 samples only — keeps frequency low, washes broad and soft
            float WashNoise(float2 uv, float scale, float time, float2 flow)
            {
                float2 p = uv * scale + flow * time;
                float n1 = ValueNoise(p);
                float n2 = ValueNoise(p * 1.7 + float2(17.3, 41.7));
                return lerp(n1, n2, 0.3);
            }

            float SignedNoise(float n) { return n * 2.0 - 1.0; }

            float3 ApplyPaintFilter(float3 color, float softness, float desaturation)
            {
                color = saturate(0.5 + (color - 0.5) * (1.0 - softness));
                float lum = dot(color, float3(0.299, 0.587, 0.114));
                color = lerp(color, lum.xxx, desaturation);
                return saturate(color + softness * 0.06);
            }

            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = input.uv;
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                float2 uv = input.uv;
                float time = _Time.y * _NoiseSpeed;

                // UV distortion — very low frequency source, barely perceptible
                float2 distortionField = float2(
                    SignedNoise(WashNoise(uv + float2(0.11, -0.07), _NoiseScale * 0.7, time, float2(0.04, 0.02))),
                    SignedNoise(WashNoise(RotateUV(uv, 0.65), _NoiseScale * 0.7, time * 0.8, float2(-0.02, 0.04)))
                );
                float2 uvDistorted = uv + distortionField * _DistortionStrength;

                // Depth gradient
                float radialDepth  = smoothstep(0.10, 0.78, length(uvDistorted - float2(0.5, 0.46)));
                float verticalDepth = smoothstep(0.0, 1.0, uvDistorted.y);
                float depthMask = saturate(radialDepth * 0.78 + verticalDepth * 0.22);
                float4 baseTint = lerp(_BaseColor, _BaseColor2, depthMask);

                // Three wash samples at very different scales
                float largeWash  = WashNoise(uvDistorted, _NoiseScale, time, float2(0.06, 0.03));
                float mediumWash = WashNoise(RotateUV(uvDistorted, 0.85), _SecondaryNoiseScale, time * 0.85, float2(-0.03, 0.05));
                // Very large scale pooling wash for big-area color pooling
                float poolWash   = WashNoise(uvDistorted, _NoiseScale * 0.35, time * 0.4, float2(0.01, 0.02));

                // Multiplicative modulation — remap [0,1] → [0.88, 1.10], no additive shadow/lift
                float washMult   = lerp(1.0 - _NoiseStrength * 1.2, 1.0 + _NoiseStrength, largeWash);
                float mediumMult = lerp(1.0 - _SecondaryNoiseStrength * 0.8, 1.0 + _SecondaryNoiseStrength * 0.7, mediumWash);

                // 3-tone hue variation: cool blue ↔ base teal ↔ warm green
                float3 blueTone  = baseTint.rgb * float3(0.91, 0.97, 1.10);
                float3 greenTone = baseTint.rgb * float3(0.96, 1.07, 0.93);
                float3 waterColor = lerp(blueTone, greenTone, mediumWash);
                waterColor = lerp(waterColor, baseTint.rgb, 0.30);

                // Apply multiplicative wash variation (subtle — not additive)
                waterColor *= washMult;
                waterColor *= lerp(1.0, mediumMult, 0.45);

                // Large-scale color pooling: gentle hue drift across big areas
                float3 poolTintA = baseTint.rgb * float3(0.97, 1.04, 1.02);
                float3 poolTintB = baseTint.rgb * float3(1.02, 0.97, 0.96);
                waterColor = lerp(waterColor, lerp(poolTintA, poolTintB, poolWash), _NoiseStrength * 0.8);

                // Paper texture — sample from texture asset
                float4 paperTex = SAMPLE_TEXTURE2D(_PaperTexture, sampler_PaperTexture, uvDistorted * _PaperTextureScale);
                float paper = paperTex.r; // Use red channel for grayscale paper grain
                float paperMult = lerp(1.0 - _PaperTextureStrength, 1.0 + _PaperTextureStrength * 0.6, paper);
                waterColor *= paperMult;

                // Edge bleeding — normalized distance so softness 0.6–0.9 maps meaningfully
                // edgeDistance max is ~0.5 for a unit UV quad; *2 normalises to 0–1
                float edgeDistance = min(min(uv.x, uv.y), min(1.0 - uv.x, 1.0 - uv.y));
                float edgeNoise = WashNoise(
                    RotateUV(uvDistorted + float2(0.31, -0.22), 0.92),
                    _SecondaryNoiseScale * 0.5,
                    time * 0.6,
                    float2(0.02, -0.03)
                );
                float normEdge = edgeDistance * 2.0 + SignedNoise(edgeNoise) * _EdgeNoiseStrength;
                float edgeMask = smoothstep(0.0, _EdgeSoftness, normEdge);

                // Soft color bleed toward edge
                float bleed = 1.0 - edgeMask;
                float3 bleedTint = saturate(baseTint.rgb + float3(0.08, 0.06, 0.05));
                waterColor = lerp(waterColor, bleedTint, bleed * 0.35);

                waterColor = ApplyPaintFilter(saturate(waterColor), _PaintSoftness, _FinalDesaturation);

                return half4(waterColor, saturate(baseTint.a * edgeMask));
            }
            ENDHLSL
        }
    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
