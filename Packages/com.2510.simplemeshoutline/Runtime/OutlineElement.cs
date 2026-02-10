using System;
using System.Collections.Generic;
using _2510.SimpleMeshOutline.Editor;
using UnityEngine;

namespace _2510.SimpleMeshOutline
{
    /// <summary>
    /// The core rendering unit of the Simple Mesh Outline system.
    /// Performs actual draw calls using <see cref="UnityEngine.Graphics.RenderMesh"/> and 
    /// manages shader properties via <see cref="UnityEngine.MaterialPropertyBlock"/>.
    /// </summary>
    [RequireComponent(typeof(MeshFilter)), Serializable]
    public class OutlineElement : MonoBehaviour
    {
        private static readonly int ThicknessProperty = Shader.PropertyToID("_Thickness");
        private static readonly int ColorProperty = Shader.PropertyToID("_BaseColor");
        private static readonly int StencilRef = Shader.PropertyToID("_StencilRef");
        
        private static string _stencilOverwriteShader = "_2510/SimpleMeshOutline/StencilOverwrite";
        private static Dictionary<int, Material> _outlineMaskPool = new ();

        [SerializeField] private Mesh outlineMesh;
        private Matrix4x4? previousLocalToWorld = null;
        private RenderParams renderParams;
        private MaterialPropertyBlock propertyBlock;
        private MeshRenderer meshRenderer;
        
        private void Awake()
        {
            propertyBlock = new MaterialPropertyBlock();
            renderParams = new RenderParams();
            meshRenderer = GetComponent<MeshRenderer>();
        }
        
        private Material GetMaskMaterial(int refId)
        {
            if (!_outlineMaskPool.TryGetValue(refId, out var mat))
            {
                mat = new Material(Shader.Find(_stencilOverwriteShader));
                mat.SetInt(StencilRef, refId);
                _outlineMaskPool[refId] = mat;
            }
            return mat;
        }
        
        /// <summary>
        /// Set the outline mesh to be used for rendering.
        /// It is recommended to use a mesh with smooth normals.
        /// Mesh for outline can be baked by outline context menu.
        /// </summary>
        /// <param name="mesh">Outline mesh.</param>
        public void SetOutlineMesh(Mesh mesh)
        {
            this.outlineMesh = mesh;
        }

        /// <summary>
        /// Render the outline with given parameters.
        /// </summary>
        /// <param name="sharedMaterial">Material of outline.</param>
        /// <param name="param">Outline parameters.</param>
        public void Render(Material sharedMaterial, OutlineParam param)
        {
            var color = param.color;
            var thickness = param.thickness;
            var outlineLayer = param.outlineLayer;
            var stencilRef = param.stencilRef;
            
            if (!gameObject.activeInHierarchy || !enabled) return;
            
            if (!gameObject.activeInHierarchy || !enabled) return;
            
            renderParams.renderingLayerMask = meshRenderer.renderingLayerMask;
            
            var bounds = outlineMesh.bounds;
            bounds.Expand(thickness * 2f);
            var worldBounds = new Bounds(transform.TransformPoint(bounds.center), Vector3.Scale(bounds.size, transform.lossyScale));
            
            renderParams.worldBounds = worldBounds;
            propertyBlock.SetInt(StencilRef, stencilRef);
            
            var localToWorld = transform.localToWorldMatrix;
            
            renderParams.layer = gameObject.layer;

            renderParams.material = GetMaskMaterial(stencilRef);
            Graphics.RenderMesh(renderParams, outlineMesh, 0, localToWorld, previousLocalToWorld);
            
            renderParams.matProps = propertyBlock;
            propertyBlock.SetColor(ColorProperty, color);
            propertyBlock.SetFloat(ThicknessProperty, thickness);
            
            renderParams.layer = outlineLayer;

            renderParams.material = sharedMaterial;
            Graphics.RenderMesh(renderParams, outlineMesh, 0, localToWorld, previousLocalToWorld);
            previousLocalToWorld = localToWorld;
        }
        
        #if UNITY_EDITOR

        /// <summary>
        /// Reuses the existing mesh from the attached MeshFilter as the outline mesh.
        /// Use this for organic or high-poly models that already have smooth normals 
        /// to save memory and avoid asset duplication.
        /// </summary>
        [ContextMenu("Reuse Mesh from MeshFilter")]
        public void ReuseMesh()
        {
            var meshFilter = GetComponent<MeshFilter>();
            outlineMesh = meshFilter.sharedMesh;
        }
        #endif
    }
}