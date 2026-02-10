# Simple Mesh Outline

The **Simple Mesh Outline** package is a tool designed to efficiently implement high-quality outline effects in Unity projects. It utilizes the **Inverted Hull** technique and includes a built-in **Smooth Normal Baking** tool to resolve the issue of split edges often seen when applying outlines to hard-edge models.

This package leverages the `Graphics.RenderMesh` API to render outlines directly, eliminating the need for creating additional `MeshRenderer` components or GameObjects, ensuring optimal performance.

## Key Features

* **Transparent Object Support**: (New in v0.2.0) Uses a custom stencil masking pass to support outlines for transparent materials without self-intersection artifacts.
* **Scale-Independent Thickness**: (New in v0.2.0) Outline thickness is calculated in world space, ensuring a consistent visual appearance regardless of the object's scale.
* **Flexible Target Assignment**: (New in v0.2.0) `OutlineRenderer` now allows explicit assignment of target `OutlineElement` components via the Inspector.
* **Smooth Normal Baking**: Generates and saves a dedicated mesh with averaged normals to ensure continuous outlines even on angular models.
* **Memory Optimization**: Uses a material pooling system for stencil masks and provides options to reuse original meshes when appropriate.
* **Optimized Rendering**: Leverages `Graphics.RenderMesh` to draw outlines without the overhead of extra GameObjects or MeshRenderer components.

# Installing Simple Mesh Outline

To install this package, follow the standard procedure for loading packages via the Unity Package Manager.

> **Note**: To render the outline properly, you must provide a **Shader** that implements the Inverted Hull technique. The scripts in this package control the outline properties via `_Thickness` and `_BaseColor`. Please ensure your Shader/Material exposes these properties.

<a name="UsingSimpleMeshOutline"></a>

# Using Simple Mesh Outline

Simple Mesh Outline offers two main workflows: **Single Object** and **Composite Object**. Additionally, you must prepare the mesh data (either by baking or reusing) to achieve high-quality results.

## 1. Preparing Outline Mesh

Standard models (especially low-poly or hard-edge models) may appear split at the edges when extruded for outlines. You have two options to prepare the mesh depending on your model's geometry.

### Option A: Baking Outline Mesh (Recommended for Hard Edges)

If your model has hard edges (e.g., cubes, low-poly props), use this method to bake a dedicated mesh with smoothed normals.

1. Select the target GameObject in the **Hierarchy** window.
2. Navigate to **GameObject > Outline** in the top menu.
* **Create Single Outline**: Bakes the mesh for the selected object and sets up the `OutlineElement`.
* **Create Outline for Children**: Finds all MeshFilters under the selected object, bakes outlines for each, and sets them up automatically.


3. When the save dialog appears, choose a path to save the generated mesh asset (`_Outline.asset`).

> **Tip**: You can also right-click the `OutlineElement` component title to open the Context Menu and select **Bake Outline Mesh** to re-bake the asset.

### Option B: Reusing Existing Mesh (Memory Efficient)

If your model already has smooth normals (e.g., spheres, capsules, or high-poly organic shapes), baking a new mesh is redundant. You can reuse the original mesh to save memory and storage.

1. Ensure an `OutlineElement` is attached to your GameObject.
2. Right-click the `OutlineElement` component title in the Inspector.
3. Select **Reuse Mesh from MeshFilter**.
4. The component will directly reference the original `sharedMesh` from the MeshFilter.

## 2. Single Object Setup

Use this workflow for a GameObject containing a single Mesh.

1. Add the `OutlineRenderer` component to the GameObject. (The `OutlineElement` component will be added automatically).
2. Assign your outline material to the **Outline Material** field. Outline material **must cull front faces** to work correctly.
3. **Prepare the mesh** using either **Option A (Bake)** or **Option B (Reuse)** described above.
4. Check **IsEnabled** to activate the outline.
5. Adjust **Thickness** and **Color** under the **Settings** section. Enabling the checkboxes allows you to override the material's default values.

## 3. Composite Object Setup

Use this workflow for complex objects (e.g., characters or props) consisting of multiple mesh parts.

1. Add the `CompositeMeshOutlineRenderer` component to the parent GameObject.
2. Right-click the component title in the Inspector to use the helper Context Menus:
* **Add Outline Elements for Every MeshFilter in Children**: Automatically iterates through child objects and adds the necessary components.
* **Find Outline Elements from Children**: Populates the list with existing `OutlineElement` components found in the hierarchy.


3. Prepare meshes for all children:
* **To Bake**: Go to **GameObject > Outline > Create Outline for Children**.
* **To Reuse**: Use the context menu on individual `OutlineElement` components if specific parts are already smooth.


4. Adjusting **Thickness** or **Color** on the `CompositeMeshOutlineRenderer` will apply the settings to all linked child parts simultaneously.

## 4. Scripting

You can control the outline via code using the `IOutlineRenderer` interface.

```csharp
IOutlineRenderer outline = GetComponent<IOutlineRenderer>();

// Enable the outline
outline.SetOutline(true);

// Change color (Enables customization mode)
outline.SetOutlineColor(Color.red);

// Change thickness (Enables customization mode)
outline.SetOutlineThickness(0.1f);

```

# Technical details

## Requirements

This package utilizes the `Graphics.RenderMesh` and `RenderParams` APIs.

* **Unity Version**: 2021.2 or higher

Your outline shader must use the following property names to be compatible with the script controls:

* Thickness (Float): `_Thickness`
* Color (Color): `_BaseColor`

## Known limitations

* **Skinned Mesh Renderer Support**: The current version is optimized for static mesh structures using `MeshFilter` and `MeshRenderer`. Outlines on rigged characters (`SkinnedMeshRenderer`) may not update correctly with animations.
* **Memory Usage**: Baking duplicates the mesh to store smoothed normal data, which increases memory usage relative to the original model size.
  * **Solution**: Use the **Reuse Mesh from MeshFilter** feature if the model already possesses smooth normals to avoid this overhead.



## Package contents

The following table describes the key files included in this package:

| File | Description |
| --- | --- |
| `OutlineRenderer.cs` | High-level component for single object outline control. |
| `CompositeOutlineRenderer.cs` | Component for unified outline control across hierarchies. |
| `OutlineElement.cs` | Core rendering unit performing stencil-masked draw calls. |
| `OutlineParam.cs` | Data structure for passing rendering parameters. |
| `StencilOverwrite.shader` | Shader for generating the stencil mask for the object body. |
| `SimpleInvertedHull.shader` | The primary inverted hull outline shader with stencil testing. |
| `OutlineMeshBaker.cs` | Editor-only script for smooth normal generation. |
| `IOutlineRenderer.cs` | Common interface for outline control components. |

## Document revision history

| Date | Reason |
| --- | --- |
| Feb 04, 2026 | Created documentation for Simple Mesh Outline package. |
| Feb 08, 2026 | Added new features in v0.2.0 and updated usage instructions. |