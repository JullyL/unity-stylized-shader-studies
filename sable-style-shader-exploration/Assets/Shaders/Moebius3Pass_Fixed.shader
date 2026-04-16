Shader "Custom/Moebius3Pass_Fixed"
{
    Properties
    {
        _LineColor ("Line Color", Color) = (0,0,0,1)
        _Thickness ("Thickness", Range(0.5, 4)) = 1

        _DepthThreshold ("Depth Threshold", Range(0.0001, 0.05)) = 0.0001
        _NormalThreshold ("Normal Threshold", Range(0.001, 1.0)) = 0.1

        _DepthStrength ("Depth Strength", Range(0, 5)) = 1
        _NormalStrength ("Normal Strength", Range(0, 5)) = 1

        _PosterizeSteps ("Posterize Steps", Range(2, 8)) = 4

        _HatchTex ("Hatch Texture (RGB packed)", 2D) = "white" {}
        _HatchTiling ("Hatch Tiling", Range(1, 200)) = 40
        _HatchStrength ("Hatch Strength", Range(0, 1)) = 0.6
        _HatchDarkness ("Hatch Darkness", Range(0, 1)) = 0.6

        _SpecPower ("Spec Power", Range(1, 128)) = 32
        _SpecStrength ("Spec Strength", Range(0, 2)) = 0.5

        _OutlineNoise ("Outline Noise", Range(0, 3)) = 0.5
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" }

        HLSLINCLUDE
        #pragma vertex Vert

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"

        TEXTURE2D(_HatchTex);
        SAMPLER(sampler_HatchTex);

        float4 _LineColor;
        float _Thickness;
        float _DepthThreshold;
        float _NormalThreshold;
        float _DepthStrength;
        float _NormalStrength;
        float _PosterizeSteps;
        float _HatchTiling;
        float _HatchStrength;
        float _HatchDarkness;
        float _SpecPower;
        float _SpecStrength;
        float _OutlineNoise;

        float SampleLinearDepth01(float2 uv)
        {
            float rawDepth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, uv).r;
            return Linear01Depth(rawDepth, _ZBufferParams);
        }

        float3 SampleSceneNormal(float2 uv)
        {
            float4 packed = SAMPLE_TEXTURE2D(_CameraNormalsTexture, sampler_CameraNormalsTexture, uv);
            return normalize(packed.xyz * 2.0 - 1.0);
        }

        float3 Posterize(float3 c, float steps)
        {
            float l = dot(c, float3(0.299, 0.587, 0.114));
            float q = round(l * steps) / steps;
            return c * (q / max(l, 1e-4));
        }

        float PosterizeBrightness(float luma, float steps)
        {
            return saturate(round(saturate(luma) * steps) / steps);
        }

        float Luma(float3 c)
        {
            return dot(c, float3(0.299, 0.587, 0.114));
        }

        float GetVideoStyleHatch(float2 uv, float lighting)
        {
            float2 hatchUV = uv * _HatchTiling;

            // Interpret the texture as black ink on white paper so the default white texture produces no hatching.
            float3 hatchTex = 1.0 - SAMPLE_TEXTURE2D(_HatchTex, sampler_HatchTex, hatchUV).rgb;

            if (lighting > 0.75)
                return 0.0;

            if (lighting > 0.5)
                return saturate(hatchTex.r);

            if (lighting > 0.25)
                return saturate(max(hatchTex.r, hatchTex.g));

            return saturate(max(hatchTex.b, max(hatchTex.r, hatchTex.g)));
        }

        ENDHLSL

        // =========================
        // PASS 1: Depth (SAFE)
        // =========================
        Pass
        {
            Name "StoreDepth"

            ZWrite Off
            ZTest Always
            Cull Off

            HLSLPROGRAM
            #pragma fragment FragDepth

            float FragDepth(Varyings input) : SV_Target
            {
                return SampleLinearDepth01(input.texcoord);
            }

            ENDHLSL
        }

        // =========================
        // PASS 2: Normal + Spec
        // =========================
        Pass
        {
            Name "StoreNormalSpec"

            ZWrite Off
            ZTest Always
            Cull Off

            HLSLPROGRAM
            #pragma fragment FragNormalSpec

            float4 FragNormalSpec(Varyings input) : SV_Target
            {
                float2 uv = input.texcoord;

                float3 n = SampleSceneNormal(uv);

                float3 l = normalize(float3(0.4, 0.8, 0.2));
                float3 v = float3(0,0,1);
                float3 h = normalize(l + v);

                float spec = pow(saturate(dot(n, h)), _SpecPower) * _SpecStrength;

                return float4(n * 0.5 + 0.5, spec);
            }

            ENDHLSL
        }

        // =========================
        // PASS 3: FINAL (CORRECT)
        // =========================
        Pass
        {
            Name "Composite"

            ZWrite Off
            ZTest Always
            Cull Off

            HLSLPROGRAM
            #pragma fragment FragFinal

            float4 FragFinal(Varyings input) : SV_Target
            {
                float2 uv = input.texcoord;

                // ALWAYS use BlitTexture for color
                float3 color = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_LinearClamp, uv).rgb;

                // Keep the scene color flat; the hatch should carry the shading.
                color = Posterize(color, _PosterizeSteps);

                float2 texel = _BlitTexture_TexelSize.xy * _Thickness;

                float dC = SampleLinearDepth01(uv);
                float dL = SampleLinearDepth01(uv + float2(-texel.x, 0));
                float dR = SampleLinearDepth01(uv + float2(texel.x, 0));

                float depthEdge = abs(dC - dL) + abs(dC - dR);
                float depthMask = step(_DepthThreshold, depthEdge * _DepthStrength);

                float3 nC = SampleSceneNormal(uv);
                float3 nR = SampleSceneNormal(uv + float2(texel.x, 0));

                float normalEdge = 1.0 - dot(nC, nR);
                float normalMask = step(_NormalThreshold, normalEdge * _NormalStrength);

                float edge = max(depthMask, normalMask);

                float3 l = normalize(float3(0.4, 0.8, 0.2));
                float lighting = saturate(dot(nC, l));
                float hatch = GetVideoStyleHatch(uv, lighting);

                color = lerp(color, color * (1.0 - _HatchDarkness), hatch * _HatchStrength);

                return lerp(float4(color,1), _LineColor, edge);

            }

            ENDHLSL
        }
    }
}
