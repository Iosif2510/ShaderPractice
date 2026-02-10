using _2510.SimpleMeshOutline.Editor;
using UnityEngine;
using UnityEngine.Serialization;

namespace _2510.SimpleMeshOutline
{
    /// /// <summary>
    /// High-level component for managing the outline of a single GameObject.
    /// Implements <see cref="IOutlineRenderer"/> and communicates with a single 
    /// <see cref="OutlineElement"/> to perform rendering.
    /// </summary>
    public class OutlineRenderer : MonoBehaviour, IOutlineRenderer
    {
        private static readonly int ThicknessProperty = Shader.PropertyToID("_Thickness");
        private static readonly int ColorProperty = Shader.PropertyToID("_BaseColor");
        private static readonly int StencilRef = Shader.PropertyToID("_StencilRef");

        [Header("Basic Settings")]
        [SerializeField] private bool isEnabled = false;
        [SerializeField] private OutlineElement outlineElement;
        [Header("Settings")]
        [SerializeField] private Material outlineMaterial;
        [SerializeField, InlineToggle(nameof(customizeThickness), 0f, 0.5f)] private float thickness = 0.05f;
        [SerializeField, InlineToggle(nameof(customizeColor))] private Color color = Color.white;
        [SerializeField, InlineToggle(nameof(overrideLayer))] private int outlineLayer;
        [SerializeField, InlineToggle(nameof(overrideStencil)), Tooltip("Does not change in runtime.")] private int outlineStencilRef = 4;
        [SerializeField, HideInInspector] private bool overrideLayer = false;
        [SerializeField, HideInInspector] private bool customizeThickness = false;
        [SerializeField, HideInInspector] private bool customizeColor = false;
        [SerializeField, HideInInspector] private bool overrideStencil = false;
        
        private Material _outlineMaterialInstance;
        
        public float Thickness => customizeThickness ? thickness : outlineMaterial.GetFloat(ThicknessProperty);
        public Color OutlineColor => customizeColor ? color : outlineMaterial.GetColor(ColorProperty);
        public int OutlineLayer => overrideLayer ? outlineLayer : gameObject.layer;
        public int OutlineStencilRef => overrideStencil ? outlineStencilRef : outlineMaterial.GetInt(StencilRef);

        private void Awake()
        {
            if (overrideStencil)
            {
                _outlineMaterialInstance = new Material(outlineMaterial);
                _outlineMaterialInstance.SetInt(StencilRef, outlineStencilRef);
            }
            else 
            {
                _outlineMaterialInstance = outlineMaterial;
            }
        }
        
        public void SetOutlineColor(Color color)
        {
            if (!customizeColor) customizeColor = true;
            this.color = color;
        }

        public void SetOutlineThickness(float thickness)
        {
            if (!customizeThickness) customizeThickness = true;
            this.thickness = thickness;
        }

        public void ToggleCustomizeColor(bool customize)
        {
            customizeColor = true;
        }

        public void ToggleCustomizeThickness(bool customize)
        {
            customizeThickness = true;
        }

        public void SetOutline(bool enable)
        {
            this.isEnabled = enable;
        }
        
        public void SetOutlineMesh(Mesh mesh)
        {
            outlineElement.SetOutlineMesh(mesh);
        }

        private void LateUpdate()
        {
            if (!isEnabled) return;
            Render();
        }

        private void Render()
        {
            if (outlineElement == null) outlineElement = GetComponent<OutlineElement>();
            if (overrideStencil) _outlineMaterialInstance.SetInt(StencilRef, outlineStencilRef);
            var param = new OutlineParam(OutlineColor, Thickness, OutlineLayer, OutlineStencilRef);
            outlineElement.Render(_outlineMaterialInstance, param);
        }
    }
}