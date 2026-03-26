Shader "Custom/ObjectFlatDepthNormals"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (0.85, 0.62, 0.45, 1)
        _LineColor ("Hatch Color", Color) = (0,0,0,1)

        _PosterizeSteps ("Posterize Steps", Range(2, 6)) = 3

        _HatchDensity ("Hatch Density", Range(1, 50)) = 12
        _HatchThickness ("Hatch Thickness", Range(0.01, 0.3)) = 0.08
        _HatchNormalStrength ("Hatch Normal Strength", Range(0, 2)) = 0.7
        _ShadowLift ("Shadow Lift", Range(0, 1)) = 0.2

        _ShadowBand1 ("Shadow Band 1", Range(0,1)) = 0.75
        _ShadowBand2 ("Shadow Band 2", Range(0,1)) = 0.5
        _ShadowBand3 ("Shadow Band 3", Range(0,1)) = 0.25
    }

    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
            "RenderPipeline"="UniversalPipeline"
            "Queue"="Geometry"
        }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        CBUFFER_START(UnityPerMaterial)
            float4 _BaseColor;
            float4 _LineColor;
            float _PosterizeSteps;
            float _HatchDensity;
            float _HatchThickness;
            float _HatchNormalStrength;
            float _ShadowLift;
            float _ShadowBand1;
            float _ShadowBand2;
            float _ShadowBand3;
        CBUFFER_END

        struct Attributes
        {
            float4 positionOS : POSITION;
            float3 normalOS   : NORMAL;
        };

        struct ForwardVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 positionOS : TEXCOORD0;
            float3 positionWS : TEXCOORD1;
            float3 normalWS   : TEXCOORD2;
            float4 shadowCoord : TEXCOORD3;
        };

        struct DepthVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 positionOS : TEXCOORD0;
            float3 positionWS : TEXCOORD1;
            float3 normalWS   : TEXCOORD2;
        };

        float PosterizeValue(float value, float steps)
        {
            return round(saturate(value) * steps) / steps;
        }

        float HatchHorizontalOS(float3 posOS, float density, float thickness)
        {
            float v = frac(posOS.y * density);
            return step(v, thickness);
        }

        float HatchVerticalOS(float3 posOS, float density, float thickness)
        {
            float v = frac(posOS.x * density);
            return step(v, thickness);
        }

        float HatchDiagonalOS(float3 posOS, float density, float thickness)
        {
            float v = frac((posOS.x + posOS.y) * density);
            return step(v, thickness);
        }

        float GetHatchMask(float3 posOS, float lighting)
        {
            float hatchH = HatchHorizontalOS(posOS, _HatchDensity, _HatchThickness);
            float hatchV = HatchVerticalOS(posOS, _HatchDensity, _HatchThickness);
            float hatchD = HatchDiagonalOS(posOS, _HatchDensity, _HatchThickness);

            float hatchMask = 0.0;

            if (lighting < _ShadowBand1)
                hatchMask = max(hatchMask, hatchH);

            if (lighting < _ShadowBand2)
                hatchMask = max(hatchMask, hatchV);

            if (lighting < _ShadowBand3)
                hatchMask = max(hatchMask, hatchD);

            return saturate(hatchMask);
        }

        float3 GetHatchDirection(float3 normalWS)
        {
            float3 tangent = cross(float3(0, 1, 0), normalWS);
            if (dot(tangent, tangent) < 1e-5)
                tangent = cross(float3(1, 0, 0), normalWS);
            return normalize(tangent);
        }

        float3 ApplyHatchToNormal(float3 posOS, float3 normalWS, float lighting)
        {
            float3 tangent = GetHatchDirection(normalWS);
            float3 bitangent = normalize(cross(normalWS, tangent));

            float hatchH = HatchHorizontalOS(posOS, _HatchDensity, _HatchThickness);
            float hatchV = HatchVerticalOS(posOS, _HatchDensity, _HatchThickness);
            float hatchD = HatchDiagonalOS(posOS, _HatchDensity, _HatchThickness);

            float3 perturb = 0;

            if (lighting < _ShadowBand1 && hatchH > 0.5)
                perturb += bitangent;

            if (lighting < _ShadowBand2 && hatchV > 0.5)
                perturb += tangent;

            if (lighting < _ShadowBand3 && hatchD > 0.5)
                perturb += normalize(tangent + bitangent);

            return normalize(normalWS + perturb * _HatchNormalStrength);
        }

        ForwardVaryings VertForward(Attributes IN)
        {
            ForwardVaryings OUT;
            VertexPositionInputs pos = GetVertexPositionInputs(IN.positionOS.xyz);
            VertexNormalInputs nrm = GetVertexNormalInputs(IN.normalOS);

            OUT.positionCS = pos.positionCS;
            OUT.positionOS = IN.positionOS.xyz;
            OUT.positionWS = pos.positionWS;
            OUT.normalWS = NormalizeNormalPerVertex(nrm.normalWS);
            OUT.shadowCoord = GetShadowCoord(pos);
            return OUT;
        }

        DepthVaryings VertDepth(Attributes IN)
        {
            DepthVaryings OUT;
            VertexPositionInputs pos = GetVertexPositionInputs(IN.positionOS.xyz);
            VertexNormalInputs nrm = GetVertexNormalInputs(IN.normalOS);

            OUT.positionCS = pos.positionCS;
            OUT.positionOS = IN.positionOS.xyz;
            OUT.positionWS = pos.positionWS;
            OUT.normalWS = NormalizeNormalPerVertex(nrm.normalWS);
            return OUT;
        }
        ENDHLSL

        Pass
        {
            Name "ForwardFlat"
            Tags { "LightMode"="UniversalForward" }

            ZWrite On
            ZTest LEqual
            Cull Back
            Blend One Zero

            HLSLPROGRAM
            #pragma vertex VertForward
            #pragma fragment FragForward

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _SHADOWS_SOFT

            half4 FragForward(ForwardVaryings IN) : SV_Target
            {
                float3 normalWS = normalize(IN.normalWS);

                Light mainLight = GetMainLight(IN.shadowCoord);
                float3 lightDir = normalize(mainLight.direction);

                float NdotL = saturate(dot(normalWS, lightDir));
                float lighting = NdotL * mainLight.shadowAttenuation;
                float litBand = PosterizeValue(lighting, _PosterizeSteps);
                litBand = lerp(_ShadowLift, 1.0, litBand);

                float3 color = _BaseColor.rgb * litBand;
                float hatchMask = GetHatchMask(IN.positionOS, lighting);
                color = lerp(color, _LineColor.rgb, hatchMask);

                return half4(color, 1.0);
            }
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode"="DepthOnly" }

            ZWrite On
            ColorMask 0
            Cull Back

            HLSLPROGRAM
            #pragma vertex VertDepthOnly
            #pragma fragment FragDepthOnly

            struct DepthOnlyAttributes
            {
                float4 positionOS : POSITION;
            };

            struct DepthOnlyVaryings
            {
                float4 positionCS : SV_POSITION;
            };

            DepthOnlyVaryings VertDepthOnly(DepthOnlyAttributes IN)
            {
                DepthOnlyVaryings OUT;
                VertexPositionInputs pos = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionCS = pos.positionCS;
                return OUT;
            }

            half4 FragDepthOnly(DepthOnlyVaryings IN) : SV_Target
            {
                return 0;
            }
            ENDHLSL
        }

        Pass
        {
            Name "DepthNormalsOnly"
            Tags { "LightMode"="DepthNormalsOnly" }

            ZWrite On
            Cull Back

            HLSLPROGRAM
            #pragma vertex VertDepth
            #pragma fragment FragDepthNormals

            half4 FragDepthNormals(DepthVaryings IN) : SV_Target
            {
                float3 normalWS = normalize(IN.normalWS);
                Light mainLight = GetMainLight();
                float lighting = saturate(dot(normalWS, normalize(mainLight.direction)));

                float3 hatchedNormal = ApplyHatchToNormal(IN.positionOS, normalWS, lighting);
                return float4(hatchedNormal * 0.5 + 0.5, 1.0);
            }
            ENDHLSL
        }

        Pass
        {
            Name "DepthNormals"
            Tags { "LightMode"="DepthNormals" }

            ZWrite On
            Cull Back

            HLSLPROGRAM
            #pragma vertex VertDepth
            #pragma fragment FragDepthNormals

            half4 FragDepthNormals(DepthVaryings IN) : SV_Target
            {
                float3 normalWS = normalize(IN.normalWS);
                Light mainLight = GetMainLight();
                float lighting = saturate(dot(normalWS, normalize(mainLight.direction)));

                float3 hatchedNormal = ApplyHatchToNormal(IN.positionOS, normalWS, lighting);
                return float4(hatchedNormal * 0.5 + 0.5, 1.0);
            }
            ENDHLSL
        }
    }

    FallBack Off
}
