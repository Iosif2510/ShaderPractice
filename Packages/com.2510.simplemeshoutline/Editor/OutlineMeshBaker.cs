using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

namespace _2510.SimpleMeshOutline.Editor
{
    /// <summary>
    /// Editor utility for generating and managing outline-specific mesh assets.
    /// Includes logic for baking "Smooth Normals" to prevent outline gaps on hard-edged geometry 
    /// and provides context menu integration for the Unity Hierarchy and Inspector.
    /// </summary>
    public class OutlineMeshBaker : EditorWindow
    {
        private static string _lastSavePath = "Assets";

        /// <summary>
        /// Create outline mesh with smooth normals from selected object's MeshFilter and save as asset.
        /// </summary>
        [MenuItem("GameObject/Outline/Create Single Outline", false, 3)]
        public static void CreateOutline(MenuCommand menuCommand)
        {
            var go = (GameObject)menuCommand.context;
            var sourceMesh = go.GetComponent<MeshFilter>().sharedMesh;
            var outlineMesh = BakeOutlineMesh(sourceMesh);
            if (outlineMesh != null && SaveMeshAsset(ref outlineMesh, sourceMesh.name))
            {
                if (!go.TryGetComponent(out OutlineElement outline)) outline = go.AddComponent<OutlineElement>();
                outline.SetOutlineMesh(outlineMesh);
            }
        }

        /// <summary>
        /// Create outline meshes with smooth normals from all children's MeshFilters and save as assets.
        /// </summary>
        [MenuItem("GameObject/Outline/Create Outline for Children", false, 3)]
        public static void CreateOutlineForChildren(MenuCommand menuCommand)
        {
            var go = (GameObject)menuCommand.context;
            var meshFilters = go.GetComponentsInChildren<MeshFilter>();
            foreach (var meshFilter in meshFilters)
            {
                var sourceMesh = meshFilter.sharedMesh;
                var outlineMesh = BakeOutlineMesh(sourceMesh);
                if (outlineMesh != null && SaveMeshAsset(ref outlineMesh, sourceMesh.name))
                {
                    if (!meshFilter.TryGetComponent(out OutlineElement outline)) outline = meshFilter.gameObject.AddComponent<OutlineElement>();
                    outline.SetOutlineMesh(outlineMesh);
                }
            }
        }
        
        [MenuItem("GameObject/Outline/Create Single Outline", true, 3)]
        public static bool ValidateCreateOutline()
        {
            var go = Selection.activeGameObject;
            if (go == null) return false;
            return go.TryGetComponent<MeshFilter>(out _);
        }
        
        /// <summary>
        /// Create outline mesh with smooth normals from selected OutlineElement's MeshFilter and save as asset.
        /// </summary>
        [MenuItem("CONTEXT/OutlineElement/Bake Outline Mesh", false)]
        public static void BakeSingleOutlineMesh(MenuCommand menuCommand)
        {
            var meshOutline = menuCommand.context as OutlineElement;
            if (meshOutline == null)
            {
                EditorUtility.DisplayDialog("Bake Error", "Select an object with OutlineElement", "Ok");
                return;
            }
            var sourceMeshFilter = meshOutline.GetComponent<MeshFilter>();
            if (sourceMeshFilter == null)
            {
                EditorUtility.DisplayDialog("Bake Error", "Select an object with MeshFilter", "Ok");
                return;
            }
            var sourceMesh = sourceMeshFilter.sharedMesh;
            if (sourceMesh == null) return;

            var outlineMesh = BakeOutlineMesh(sourceMesh);
            
            if (outlineMesh != null && SaveMeshAsset(ref outlineMesh, sourceMesh.name))
            {
                meshOutline.SetOutlineMesh(outlineMesh);
            }
        }
        
        private static bool SaveMeshAsset(ref Mesh mesh, string sourceName)
        {
            // 에셋 저장창 열기
            var path = EditorUtility.SaveFilePanelInProject("Save Outline Mesh",
                sourceName + "_Outline", "asset", "Select a path to save the mesh."
                , _lastSavePath);

            if (!string.IsNullOrEmpty(path))
            {
                AssetDatabase.CreateAsset(mesh, path);
                AssetDatabase.SaveAssets();
                AssetDatabase.Refresh();
                
                EditorUtility.DisplayDialog("Bake Complete", "Outline Mesh is successfully saved", "Ok");
                _lastSavePath = path;
                return true;
            }
            return false;
        }
        
        private static Mesh BakeOutlineMesh(Mesh sourceMesh)
        {
            if (sourceMesh == null) return null;

            // --- 베이킹 로직 (이전과 동일) ---
            Mesh outlineMesh = Instantiate(sourceMesh);
            Vector3[] vertices = outlineMesh.vertices;
            Vector3[] normals = outlineMesh.normals;
            Vector3[] smoothNormals = new Vector3[normals.Length];

            var normalDict = new Dictionary<Vector3, Vector3>();

            for (int i = 0; i < vertices.Length; i++)
            {
                if (!normalDict.ContainsKey(vertices[i]))
                    normalDict[vertices[i]] = Vector3.zero;
                normalDict[vertices[i]] += normals[i];
            }

            for (int i = 0; i < vertices.Length; i++)
            {
                smoothNormals[i] = normalDict[vertices[i]].normalized;
            }

            outlineMesh.normals = smoothNormals;

            // 에셋 저장창 열기
            return outlineMesh;
        }
    }
}