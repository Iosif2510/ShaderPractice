using UnityEngine;

namespace _2510.SimpleMeshOutline
{
    public struct OutlineParam
    {
        public Color color;
        public float thickness;
        public int outlineLayer;
        public int stencilRef;
        
        /// <param name="color">Color of outline.</param>
        /// <param name="thickness">Thickness of outline.</param>
        /// <param name="outlineLayer">Layer of outline</param>
        /// <param name="stencilRef">Stencil Reference ID to Overwrite and Test</param>
        public OutlineParam(Color color, float thickness, int outlineLayer, int stencilRef)
        {
            this.color = color;
            this.thickness = thickness;
            this.outlineLayer = outlineLayer;
            this.stencilRef = stencilRef;
        }
    }
}