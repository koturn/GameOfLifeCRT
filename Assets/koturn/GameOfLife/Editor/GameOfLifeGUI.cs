using System;
using UnityEditor;
using UnityEngine;


namespace Koturn.GameOfLife
{
    /// <summary
    /// <see cref="ShaderGUI"/> for GameOfLife.shader.
    /// </summary>
    public class GameOfLifeGUI : ShaderGUI
    {
        /// <summary>
        /// Draw common items.
        /// </summary>
        /// <param name="me">The <see cref="MaterialEditor"/> that are calling this <see cref="OnGUI(MaterialEditor, MaterialProperty[])"/> (the 'owner')</param>
        /// <param name="mps">Material properties of the current selected shader</param>
        public override void OnGUI(MaterialEditor me, MaterialProperty[] mps)
        {
            ShaderProperty(me, mps, "_Color");
            ShaderProperty(me, mps, "_CutOutside");
            ShaderProperty(me, mps, "_UseOptimizedVertexShader");
            ShaderProperty(me, mps, "_CompMethod");

            EditorGUILayout.Space();

            GUILayout.Label("Advanced Options", EditorStyles.boldLabel);
            using (new EditorGUILayout.VerticalScope(GUI.skin.box))
            {
                me.RenderQueueField();
#if UNITY_5_6_OR_NEWER
                // me.EnableInstancingField();
                me.DoubleSidedGIField();
#endif  // UNITY_5_6_OR_NEWER
            }
        }

        /// <summary>
        /// Draw default item of specified shader property.
        /// </summary>
        /// <param name="me">A <see cref="MaterialEditor"/></param>
        /// <param name="mps"><see cref="MaterialProperty"/> array</param>
        /// <param name="propName">Name of shader property</param>
        private static void ShaderProperty(MaterialEditor me, MaterialProperty[] mps, string propName)
        {
            ShaderProperty(me, FindProperty(propName, mps));
        }

        /// <summary>
        /// Draw default item of specified shader property.
        /// </summary>
        /// <param name="me">A <see cref="MaterialEditor"/></param>
        /// <param name="mp">Target <see cref="MaterialProperty"/></param>
        private static void ShaderProperty(MaterialEditor me, MaterialProperty mp)
        {
            me.ShaderProperty(mp, mp.displayName);
        }
    }
}
