using System;
using System.Collections.Generic;
using System.Linq;
using _2510.SimpleMeshOutline.Editor;
using UnityEngine;

namespace _2510.SimpleMeshOutline
{
    /// <summary>
    /// Management component for applying unified outline settings to multiple objects or complex hierarchies.
    /// Coordinates a collection of <see cref="OutlineElement"/> components to ensure visual consistency 
    /// across composite models.
    /// </summary>
    public class CompositeOutlineRenderer : MonoBehaviour, IOutlineRenderer
    {
        private static readonly int ThicknessProperty = Shader.PropertyToID("_Thickness");
        private static readonly int ColorProperty = Shader.PropertyToID("_BaseColor");

        [SerializeField] private bool isEnabled = false;
        [Header("Sources")]
        [SerializeField] private List<OutlineElement> outlineElements;
        [SerializeField] private Material outlineMaterial;
        [Header("Settings")]
        [SerializeField, InlineToggle(nameof(customizeThickness), 0f, 0.5f)] private float thickness = 0.05f;
        [SerializeField, InlineToggle(nameof(customizeColor))] private Color color = Color.white;
        [SerializeField, InlineToggle(nameof(overrideLayer))] private int outlineLayer;
        [SerializeField, InlineToggle(nameof(overrideStencil))] private int outlineStencilRef = 4;
        [SerializeField, HideInInspector] private bool overrideLayer = false;
        [SerializeField, HideInInspector] private bool customizeThickness = false;
        [SerializeField, HideInInspector] private bool customizeColor = false;
        [SerializeField, HideInInspector] private bool overrideStencil = false;
        
        public float Thickness => customizeThickness ? thickness : outlineMaterial.GetFloat(ThicknessProperty);

        public Color OutlineColor => customizeColor ? color : outlineMaterial.GetColor(ColorProperty);
        public int OutlineLayer => overrideLayer ? outlineLayer : gameObject.layer;
        public int OutlineStencilRef => overrideStencil ? outlineStencilRef : 4;
        
        
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

        private void LateUpdate()
        {
            if (!isEnabled) return;
            Render();
        }
        
        public void SetOutline(bool isOutlined)
        {
            this.isEnabled = isOutlined;
        }
        
        private void Render()
        {
            if (outlineElements.Count == 0) return;

            var param = new OutlineParam(OutlineColor, Thickness, OutlineLayer, OutlineStencilRef);
            foreach (var element in outlineElements)
            {
                element.Render(outlineMaterial, param);
            }
        }

        #if UNITY_EDITOR
        
        [ContextMenu("Find Outline Elements from Children")]
        private void FindElementsFromChildren()
        {
            var elements = GetComponentsInChildren<OutlineElement>(true);
            outlineElements ??= new List<OutlineElement>(elements.Length);
            outlineElements.Clear();
            outlineElements.AddRange(elements);
        }
        
        [ContextMenu("Add Outline Elements for Every MeshFilter in Children")]
        private void SetupElementsInChildren()
        {
            var meshFilters = GetComponentsInChildren<MeshFilter>(true);
            if (outlineElements == null) outlineElements = new List<OutlineElement>(meshFilters.Length);
            outlineElements.Clear();
            foreach (var meshFilter in meshFilters)
            {
                if (!meshFilter.TryGetComponent<OutlineElement>(out var element))
                {
                    element = meshFilter.gameObject.AddComponent<OutlineElement>();
                }
                outlineElements.Add(element);
            }
        }
        #endif
    }
}