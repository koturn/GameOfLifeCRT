Shader "koturn/GameOfLife/CRT/GameOfLife"
{
    Properties
    {
        _Color ("Cell Color", Color) = (0.0, 1.0, 0.0, 1.0)

        // shader_feature_fragment: _CUTOUTSIDE_ON
        [Toggle]
        _CutOutside ("Cut outside of texture; Treat as zero outside texels", Float) = 0

        // shader_feature_fragment: _COMPMETHOD_NORMAL _COMPMETHOD_ACCURATE
        [KeywordEnum(Normal, Accurate)]
        _CompMethod ("Compare method", Float) = 0
    }

    SubShader
    {
        ZTest Always
        ZWrite Off

        Pass
        {
            Name "Update"

            CGPROGRAM
            #pragma target 3.0

            #include "UnityCustomRenderTexture.cginc"

            #pragma vertex CustomRenderTextureVertexShader
            #pragma fragment frag
            #pragma shader_feature_local_fragment _ _CUTOUTSIDE_ON
            #pragma shader_feature_local_fragment _COMPMETHOD_NORMAL _COMPMETHOD_ACCURATE

            //! Allowable floating point calculation error.
            static const float eps = 1.0e-3;
            //! Four-dimensional vector with all elements 1.
            static const float4 ones4 = float4(1.0, 1.0, 1.0, 1.0);
            //! Color for alive cells.
            uniform float4 _Color;

#ifdef _CUTOUTSIDE_ON
            /*!
             * @brief Return 0 when specified outside the texture.
             * @param [in] tex  A texture sampler.
             * @param [in] uv  Coordinate of UV.
             * @return (0.0, 0.0, 0.0, 0.0) of uv is outside of texture, otherwise color on specified corrdinate.
             */
            inline float tex2DCutOutsideA(sampler2D tex, float2 uv) {
                const float2 v = step(0.0, uv) * step(uv, 1.0);
                return v.x * v.y * tex2D(tex, uv).a;
            }
#endif  // _CUTOUTSIDE_ON

            /*!
             * @brief Fragment shader function.
             * @param [in] i  Input of custom render texture.
             * @return RGBA value of texel.
             */
            float4 frag(v2f_customrendertexture i) : COLOR
            {
                const float2 d = 1.0 / _CustomRenderTextureInfo.xy;
                const float2 uv = i.globalTexcoord;

#ifdef _CUTOUTSIDE_ON
                const float sum = dot(
                    step(
                        _Color.a,
                        float4(
                            tex2DCutOutsideA(_SelfTexture2D, uv - d),
                            tex2DCutOutsideA(_SelfTexture2D, float2(uv.x, uv.y - d.y)),
                            tex2DCutOutsideA(_SelfTexture2D, float2(uv.x + d.x, uv.y - d.y)),
                            tex2DCutOutsideA(_SelfTexture2D, float2(uv.x - d.x, uv.y))))
                    + step(
                        _Color.a,
                        float4(
                            tex2DCutOutsideA(_SelfTexture2D, float2(uv.x + d.x, uv.y)),
                            tex2DCutOutsideA(_SelfTexture2D, float2(uv.x - d.x, uv.y + d.y)),
                            tex2DCutOutsideA(_SelfTexture2D, float2(uv.x, uv.y + d.y)),
                            tex2DCutOutsideA(_SelfTexture2D, uv + d))),
                    ones4);
#else
                const float sum = dot(
                    step(
                        _Color.a,
                        float4(
                            tex2D(_SelfTexture2D, uv - d).a,
                            tex2D(_SelfTexture2D, float2(uv.x, uv.y - d.y)).a,
                            tex2D(_SelfTexture2D, float2(uv.x + d.x, uv.y - d.y)).a,
                            tex2D(_SelfTexture2D, float2(uv.x - d.x, uv.y)).a))
                    + step(
                        _Color.a,
                        float4(
                            tex2D(_SelfTexture2D, float2(uv.x + d.x, uv.y)).a,
                            tex2D(_SelfTexture2D, float2(uv.x - d.x, uv.y + d.y)).a,
                            tex2D(_SelfTexture2D, float2(uv.x, uv.y + d.y)).a,
                            tex2D(_SelfTexture2D, uv + d).a)),
                    ones4);
#endif  // _CUTOUTSIDE_ON

#if _COMPMETHOD_NORMAL
                const float2 result = step(abs(sum.xx - float2(2.0, 3.0)), eps);
#else
                const float2 result = (sum.xx == float2(2.0, 3.0));
#endif  // _COMPMETHOD_NORMAL
                const float a = _Color.a * (step(_Color.a, tex2D(_SelfTexture2D, uv).a) * result.x + result.y);

                return float4(_Color.rgb, a);
            }
            ENDCG
        }
    }

    CustomEditor "Koturn.GameOfLife.GameOfLifeGUI"
}

