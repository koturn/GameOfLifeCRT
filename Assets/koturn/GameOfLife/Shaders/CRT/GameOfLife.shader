Shader "koturn/GameOfLife/CRT/GameOfLife"
{
    /*
     * The Game of Life, also known simply as Life, is a cellular automaton
     * devised by the British mathematician John Horton Conway in 1970.
     *
     * Rules:
     * The universe of the Game of Life is an infinite, two-dimensional
     * orthogonal grid of square cells, each of which is in one of two possible
     * states, live or dead, (or populated and unpopulated, respectively).
     * Every cell interacts with its eight neighbours, which are the cells that
     * are horizontally, vertically, or diagonally adjacent. At each step in
     * time, the following transitions occur:
     *
     * - Any live cell with fewer than two live neighbours dies, as if by
     *   underpopulation.
     * - Any live cell with two or three live neighbours lives on to the next
     *   generation.
     * - Any live cell with more than three live neighbours dies, as if by
     *   overpopulation.
     * - Any dead cell with exactly three live neighbours becomes a live cell,
     *   as if by reproduction.
     *
     * These rules, which compare the behavior of the automaton to real life,
     * can be condensed into the following:
     *
     * - Any live cell with two or three live neighbours survives.
     * - Any dead cell with three live neighbours becomes a live cell.
     * - All other live cells die in the next generation. Similarly, all other
     *   dead cells stay dead.
     *
     * The initial pattern constitutes the seed of the system. The first
     * generation is created by applying the above rules simultaneously to
     * every cell in the seed, live or dead; births and deaths occur
     * simultaneously, and the discrete moment at which this happens is
     * sometimes called a tick. Each generation is a pure function of the
     * preceding one. The rules continue to be applied repeatedly to create
     * further generations.
     */
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
            inline float tex2DCutOutsideA(sampler2D tex, float2 uv)
            {
                return all(saturate(uv) == uv) ? tex2D(tex, uv).a : 0.0;
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
                const float4 d2 = float4(d.xy, -d.y, 0.0);
                const float2 uv = i.globalTexcoord;

#ifdef _CUTOUTSIDE_ON
                const float sum = dot(
                    step(
                        _Color.a,
                        float4(
                            tex2DCutOutsideA(_SelfTexture2D, uv - d2.xy),
                            tex2DCutOutsideA(_SelfTexture2D, uv - d2.wy),
                            tex2DCutOutsideA(_SelfTexture2D, uv + d2.xz),
                            tex2DCutOutsideA(_SelfTexture2D, uv - d2.xw)))
                    + step(
                        _Color.a,
                        float4(
                            tex2DCutOutsideA(_SelfTexture2D, uv + d2.xw),
                            tex2DCutOutsideA(_SelfTexture2D, uv - d2.xz),
                            tex2DCutOutsideA(_SelfTexture2D, uv + d2.wy),
                            tex2DCutOutsideA(_SelfTexture2D, uv + d2.xy))),
                    ones4);
#else
                const float sum = dot(
                    step(
                        _Color.a,
                        float4(
                            tex2D(_SelfTexture2D, uv - d2.xy).a,
                            tex2D(_SelfTexture2D, uv - d2.wy).a,
                            tex2D(_SelfTexture2D, uv + d2.xz).a,
                            tex2D(_SelfTexture2D, uv - d2.xw).a))
                    + step(
                        _Color.a,
                        float4(
                            tex2D(_SelfTexture2D, uv + d2.xw).a,
                            tex2D(_SelfTexture2D, uv - d2.xz).a,
                            tex2D(_SelfTexture2D, uv + d2.wy).a,
                            tex2D(_SelfTexture2D, uv + d2.xy).a)),
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

