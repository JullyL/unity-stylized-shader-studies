Shader "Pond/WatercolorPondMaster"
{
    Properties
    {
        _WaterColor ("Water Color", Color) = (0.61, 0.83, 0.82, 0.82)
        _PigmentColor ("Pigment Color", Color) = (0.16, 0.39, 0.43, 1)
        _WashScale ("Wash Scale", Range(0.5, 18)) = 5
        _DriftSpeed ("Drift Speed", Range(0, 1)) = 0.08
        _PaperGrainTexture ("Paper Grain Texture", 2D) = "white" {}
        _PaperStrength ("Paper Strength", Range(0, 1)) = 0.35
        _LilyMask ("Lily Mask", 2D) = "black" {}
        _LilyAlbedo ("Lily Albedo", 2D) = "black" {}
        _LilyMaskScale ("Lily Mask Scale", Float) = 1
        _LilyMaskOffset ("Lily Mask Offset", Vector) = (0, 0, 0, 0)
        _LilyRadialIntensity ("Lily Radial Intensity", Range(0, 1)) = 0.3
        _LilyVeinCount ("Lily Vein Count", Float) = 6
        _LilyVeinIntensity ("Lily Vein Intensity", Range(0, 0.5)) = 0.1
        _LilyColorVariation ("Lily Color Variation", Range(0, 0.2)) = 0.08
        _DepthMap ("Depth Map", 2D) = "gray" {}
        _RevealAmount ("Reveal Amount", Range(0, 1)) = 1
        _FishTexture ("Fish Texture", 2D) = "white" {}
        _FishSpeed ("Fish Speed", Range(-2, 2)) = 0.18
        _DistortionStrength ("Distortion Strength", Range(0, 1)) = 0.2
        _DepthTint ("Depth Tint", Color) = (0.22, 0.48, 0.51, 1)
        _SurfaceOpacity ("Surface Opacity", Range(0.35, 1)) = 0.86
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
        }

        Pass
        {
            Name "WatercolorComposite"
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

            TEXTURE2D(_LilyMask);
            SAMPLER(sampler_LilyMask);
            TEXTURE2D(_LilyAlbedo);
            SAMPLER(sampler_LilyAlbedo);
            TEXTURE2D(_DepthMap);
            SAMPLER(sampler_DepthMap);
            TEXTURE2D(_FishTexture);
            SAMPLER(sampler_FishTexture);
            TEXTURE2D(_PaperGrainTexture);
            SAMPLER(sampler_PaperGrainTexture);


            CBUFFER_START(UnityPerMaterial)
                float4 _WaterColor;
                float4 _PigmentColor;
                float4 _DepthTint;
                float4 _LilyMask_ST;
                float4 _LilyAlbedo_ST;
                float4 _LilyMaskOffset;
                float4 _DepthMap_ST;
                float4 _FishTexture_ST;
                float4 _PaperGrainTexture_ST;
                float _LilyMaskScale;
                float _LilyRadialIntensity;
                float _LilyVeinCount;
                float _LilyVeinIntensity;
                float _LilyColorVariation;
                float _WashScale;
                float _DriftSpeed;
                float _PaperStrength;
                float _RevealAmount;
                float _FishSpeed;
                float _DistortionStrength;
                float _SurfaceOpacity;
            CBUFFER_END

            float Hash21(float2 p)
            {
                p = frac(p * float2(123.34, 345.45));
                p += dot(p, p + 34.345);
                return frac(p.x * p.y);
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

            float Fbm(float2 p)
            {
                float sum = 0.0;
                float amp = 0.5;
                float2 shift = float2(17.3, 41.7);

                [unroll]
                for (int i = 0; i < 4; i++)
                {
                    sum += ValueNoise(p) * amp;
                    p = p * 2.03 + shift;
                    amp *= 0.5;
                }

                return sum;
            }

            // Radial gradient for lily center depth
            float RadialShade(float2 uv, float innerRadius, float outerRadius)
            {
                float2 p = uv - 0.5;
                float r = length(p);
                return smoothstep(outerRadius, innerRadius, r);
            }

            // Procedural veins using radial lines
            float ProceduralVeins(float2 uv, float veinCount, float intensity)
            {
                float2 p = uv - 0.5;
                float r = length(p);
                float angle = atan2(p.y, p.x);
                
                // Create radial vein pattern
                float veins = sin(angle * veinCount);
                veins = abs(veins);
                veins = smoothstep(0.5, 0.2, veins);
                
                // Fade toward center and edges
                veins *= smoothstep(0.05, 0.25, r);
                veins *= smoothstep(0.5, 0.35, r);
                
                return veins * intensity;
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
                float2 uv = input.uv;
                float time = _Time.y;

                float2 driftA = uv * _WashScale + float2(time * _DriftSpeed, time * _DriftSpeed * 0.37);
                float2 driftB = uv * (_WashScale * 2.25) + float2(-time * _DriftSpeed * 0.43, time * _DriftSpeed * 0.61);
                float wash = Fbm(driftA) * 0.68 + Fbm(driftB) * 0.32;

                float paper = SAMPLE_TEXTURE2D(_PaperGrainTexture, sampler_PaperGrainTexture, TRANSFORM_TEX(uv, _PaperGrainTexture)).r;
                float3 color = lerp(_WaterColor.rgb, _PigmentColor.rgb, saturate(wash * 0.56));
                color *= lerp(0.9, 1.12, paper);
                color += (paper - 0.5) * _PaperStrength * 0.2;

                float depth = SAMPLE_TEXTURE2D(_DepthMap, sampler_DepthMap, TRANSFORM_TEX(uv, _DepthMap)).r;
                float reveal = smoothstep(depth - 0.09, depth + 0.09, _RevealAmount);

                // Procedural UV distortion based on noise
                float distortNoise1 = Fbm(uv * 14.0 + time * 0.12);
                float distortNoise2 = Fbm(uv * 17.0 - time * 0.09);
                float2 uvDistortion = (float2(distortNoise1, distortNoise2) - 0.5) * 0.08;
                float2 maskUv = uv / _LilyMaskScale + _LilyMaskOffset.xy + 0.5 * (1 - 1.0 / _LilyMaskScale);
                float2 lilySurfaceUv = maskUv + uvDistortion * _DistortionStrength;

                // Sample mask and albedo with the same moving surface coordinates.
                float lilyMask = SAMPLE_TEXTURE2D(_LilyMask, sampler_LilyMask, lilySurfaceUv).r;
                float3 lilyAlbedo = SAMPLE_TEXTURE2D(_LilyAlbedo, sampler_LilyAlbedo, lilySurfaceUv).rgb;
                float albedoLuma = dot(lilyAlbedo, float3(0.299, 0.587, 0.114));
                float albedoCoverage = smoothstep(0.04, 0.14, albedoLuma);
                lilyMask *= albedoCoverage;

                float lilyCore = smoothstep(0.5, 0.62, lilyMask) * reveal;
                float lilySoft = smoothstep(0.16, 0.5, lilyMask) * reveal;

                // Procedural radial shading for lily depth
                float radialShade = RadialShade(lilySurfaceUv, 0.1, 0.45) * _LilyRadialIntensity;

                // Procedural veins for texture variation
                float veins = ProceduralVeins(lilySurfaceUv, _LilyVeinCount, _LilyVeinIntensity);

                // Noise-based color variation
                float colorVar = Fbm(lilySurfaceUv * 8.0 + time * 0.05) - 0.5;

                // Combine lily color with procedural effects
                float3 lilyColor = lilyAlbedo * lerp(0.9, 1.12, wash);
                lilyColor += radialShade * float3(0.15, 0.2, 0.1);
                lilyColor += veins * float3(0.08, 0.1, 0.05);
                lilyColor += colorVar * _LilyColorVariation;

                float2 fishUv = uv * float2(2.15, 1.35) + float2(time * _FishSpeed, sin(time * 0.41) * 0.08);
                fishUv += uvDistortion * 0.1;
                half4 fish = SAMPLE_TEXTURE2D(_FishTexture, sampler_FishTexture, TRANSFORM_TEX(frac(fishUv), _FishTexture));
                float fishAlpha = fish.a * (1.0 - lilyCore * 0.85) * smoothstep(0.95, 0.25, depth) * 0.55;
                float3 fishColor = lerp(fish.rgb, _DepthTint.rgb, 0.38 + depth * 0.25);
                color = lerp(color, fishColor, fishAlpha);

                color = lerp(color, lilyColor, lilyCore * 0.96);

                color = saturate(color);
                float alpha = saturate(max(_SurfaceOpacity, max(lilySoft, fishAlpha * 0.65)));
                return half4(color, alpha);
            }
            ENDHLSL
        }
    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
