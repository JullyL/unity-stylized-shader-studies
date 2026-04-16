Shader "Custom/Moebius3Pass"
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

        _HatchScale ("Hatch Scale", Range(1, 100)) = 25
        _HatchStrength ("Hatch Strength", Range(0, 1)) = 0.6

        _SpecPower ("Spec Power", Range(1, 128)) = 32
        _SpecStrength ("Spec Strength", Range(0, 2)) = 0.5

        _OutlineNoise ("Outline Noise", Range(0, 3)) = 0.5
        _DebugView ("Debug View", Range(0, 5)) = 0
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" }

        // =========================
        // Shared Helper Functions
        // =========================
        HLSLINCLUDE // shared by all passes in the shader
        #pragma vertex Vert
        

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"

        TEXTURE2D(_ColorDepthTex);
        SAMPLER(sampler_ColorDepthTex);

        TEXTURE2D(_NormalSpecTex);
        SAMPLER(sampler_NormalSpecTex);

        float4 _LineColor;
        float _Thickness;
        float _DepthThreshold;
        float _NormalThreshold;
        float _DepthStrength;
        float _NormalStrength;
        float _PosterizeSteps;
        float _HatchScale;
        float _HatchStrength;
        float _SpecPower;
        float _SpecStrength;
        float _OutlineNoise;
        float _DebugView;

        float SampleLinearDepth01(float2 uv)
        {
            float rawDepth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, uv).r;
            return Linear01Depth(rawDepth, _ZBufferParams);
        }

        float3 SampleSceneNormal(float2 uv)
        {
            float4 packedNormal = SAMPLE_TEXTURE2D(_CameraNormalsTexture, sampler_CameraNormalsTexture, uv);
            return normalize(packedNormal.xyz * 2.0 - 1.0);
        }

        float3 PosterizeColor(float3 color, float steps)
        {
            float luminance = dot(color, float3(0.299, 0.587, 0.114));
            float quantized = round(luminance * steps) / steps;
            float scale = quantized / max(luminance, 0.0001);
            return saturate(color * scale);
        }

        float Luma(float3 c) // luminance calculation
        {
            return dot(c, float3(0.299, 0.587, 0.114));
        }

        float Hash21(float2 p) //takes a 2D coordinate and returns a pseudo-random value in [0,1]
        {
            p = frac(p * float2(123.34, 456.21));
            p += dot(p, p + 45.32);
            return frac(p.x * p.y);
        }

        float HatchLine(float2 uv, float angle, float spacing, float thickness)
        {
            float s = sin(angle);
            float c = cos(angle);

            float2 r = float2(
                c * uv.x - s * uv.y,
                s * uv.x + c * uv.y
            );

            float v = abs(frac(r.x / spacing) - 0.5);
            return 1.0 - smoothstep(thickness, thickness + 0.02, v);
        }

        float CrossHatch(float2 uv, float luma)
        {
            float h1 = HatchLine(uv, radians(45.0), 0.12, 0.08);
            float h2 = HatchLine(uv, radians(-45.0), 0.12, 0.08);
            float h3 = HatchLine(uv, radians(0.0), 0.16, 0.08);

            if (luma > 0.5) return 0.0;
            else if (luma > 0.4) return h2;
            else if (luma > 0.3) return max(h1, h2);
            else return max(h3, max(h1, h2));
        }
        ENDHLSL

        // =========================
        // PASS 1: Color and Depth
        // =========================
        Pass
        {
            Name "StoreColorDepth"

            ZWrite Off
            ZTest Always
            Cull Off
            Blend Off

            HLSLPROGRAM
            #pragma fragment FragStoreColorDepth

            half4 FragStoreColorDepth(Varyings input) : SV_Target
            {
                float2 uv = input.texcoord;
                
                // current scene color at uv
                half4 sceneCol = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_LinearClamp, uv);
                // current scene depth at uv
                float depth01 = SampleLinearDepth01(uv);
                
                // Pack into RGBA: RGB=color, A=depth
                return half4(sceneCol.rgb, depth01);
            }
            ENDHLSL
        }

        // =========================
        // PASS 2: Normal and Specular
        // =========================
        Pass
        {
            Name "StoreNormalSpec"

            ZWrite Off
            ZTest Always
            Cull Off
            Blend Off

            HLSLPROGRAM
            #pragma fragment FragStoreNormalSpec

            float3 GetMainLightDirApprox()
            {
                return normalize(float3(0.4, 0.8, 0.2));
            }

            half4 FragStoreNormalSpec(Varyings input) : SV_Target
            {
                //uv coordinates
                float2 uv = input.texcoord;

                // get normal from the scene
                float3 n = SampleSceneNormal(uv);

                //define view angle 
                float3 v = float3(0, 0, 1);
                //light direction
                float3 l = GetMainLightDirApprox();
                //halfway between view and light
                float3 h = normalize(v + l);
                //Calculate a simple Blinn-Phong specular term
                float spec = pow(saturate(dot(n, h)), _SpecPower) * _SpecStrength;

                //convert it to 0-1 range for storage
                float3 encN = n * 0.5 + 0.5;

                return half4(encN, spec);
            }
            ENDHLSL
        }

        // =========================
        // PASS 3: Composite Final
        // =========================
        Pass
        {
            Name "CompositeFinal"

            ZWrite Off
            ZTest Always
            Cull Off
            Blend Off

            HLSLPROGRAM
            #pragma fragment FragComposite

            // Sample the depth stored in the first pass's alpha channel

            float SampleStoredDepth(float2 uv)
            {
                return SAMPLE_TEXTURE2D(_ColorDepthTex, sampler_ColorDepthTex, uv).a;
            }

            // Sample the color stored in the first pass's RGB channels

            float3 SampleStoredColor(float2 uv)
            {
                return SAMPLE_TEXTURE2D(_ColorDepthTex, sampler_ColorDepthTex, uv).rgb;
            }

            // Sample the normal and specular stored in the second pass

            float3 SampleStoredNormal(float2 uv)
            {
                float3 enc = SAMPLE_TEXTURE2D(_NormalSpecTex, sampler_NormalSpecTex, uv).rgb;
                return normalize(enc * 2.0 - 1.0);
            }

            // Sample the specular stored in the second pass's alpha channel

            float SampleStoredSpec(float2 uv)
            {
                return SAMPLE_TEXTURE2D(_NormalSpecTex, sampler_NormalSpecTex, uv).a;
            }


            half4 FragComposite(Varyings input) : SV_Target
            {
                float2 uv = input.texcoord;
                float3 color = SampleStoredColor(uv);
                float depth = SampleStoredDepth(uv);
                float3 normal = SampleStoredNormal(uv);

                // Improve depth visibility
                float depthVis = pow(depth, 0.2);

                float2 texel = _BlitTexture_TexelSize.xy * _Thickness;

                // Add some noise to the UVs for a sketchy outline effect
                float2 jitter = (float2(
                    Hash21(uv * 123.1),
                    Hash21(uv * 231.7)
                ) - 0.5) * texel * _OutlineNoise;

                float2 suv = uv + jitter;

                // Color + Posterization - remove smooth gradient
                float3 sceneCol = SampleStoredColor(suv);
                sceneCol = PosterizeColor(sceneCol, _PosterizeSteps);

                // Depth edge detection using depth differences with neighbors
                float dC = SampleStoredDepth(suv);
                float dL = SampleStoredDepth(suv + float2(-texel.x, 0));
                float dR = SampleStoredDepth(suv + float2( texel.x, 0));
                float dU = SampleStoredDepth(suv + float2(0,  texel.y));
                float dD = SampleStoredDepth(suv + float2(0, -texel.y));

                // Sum of absolute depth differences with neighbors
                float depthEdge =
                    abs(dC - dL) +
                    abs(dC - dR) +
                    abs(dC - dU) +
                    abs(dC - dD);

                depthEdge *= _DepthStrength;
                float depthMask = step(_DepthThreshold, depthEdge);

                // Normal edge detection using dot product differences
                float3 nC = SampleStoredNormal(suv);
                float3 nL = SampleStoredNormal(suv + float2(-texel.x, 0));
                float3 nR = SampleStoredNormal(suv + float2( texel.x, 0));
                float3 nU = SampleStoredNormal(suv + float2(0,  texel.y));
                float3 nD = SampleStoredNormal(suv + float2(0, -texel.y));

                // Sum of (1 - dot) differences with neighbors to measure normal change
                float normalEdge =
                    (1.0 - dot(nC, nL)) +
                    (1.0 - dot(nC, nR)) +
                    (1.0 - dot(nC, nU)) +
                    (1.0 - dot(nC, nD));

                normalEdge *= _NormalStrength;
                float normalMask = step(_NormalThreshold, normalEdge);

                //combine depth and normal masks to get final edge mask
                float finalMask = max(depthMask, normalMask);

                // Specular-based hatching
                // Sample the specular value stored in the second pass
                float spec = SampleStoredSpec(suv);
                // Calculate hatch pattern based on luminance and specular
                float luma = Luma(sceneCol);
                float hatch = CrossHatch(uv * _HatchScale, luma);

                float hatchAmount = hatch * _HatchStrength * (1.0 - spec);
                float3 shaded = lerp(sceneCol, sceneCol * 0.45, hatchAmount);

                shaded += spec.xxx * 0.2;

                // if (_DebugView == 1)
                //     {
                //         return float4(color, 1.0); // Pass1: Color
                //     }
                //     else if (_DebugView == 2)
                //     {
                //         return float4(depthVis, depthVis, depthVis, 1.0); // Pass1: Depth
                //     }
                //     else if (_DebugView == 3)
                //     {
                //         return float4(normal * 0.5 + 0.5, 1.0); // Pass2: Normal
                //     }
                //     else if (_DebugView == 4)
                //     {
                //         return float4(spec, spec, spec, 1.0); // Pass2: Specular
                //     }
                return lerp(float4(shaded, 1.0), _LineColor, finalMask);
                
                // float4 cd = SAMPLE_TEXTURE2D(_ColorDepthTex, sampler_ColorDepthTex, uv);
                // return float4(cd.a, cd.a, cd.a, 1);
            }
            ENDHLSL
        }
    }
}
