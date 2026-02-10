# Changelog
All notable changes to this package will be documented in this file.

## [0.2.1] - 2026-02-10
- Fixed inspector UI on OutlineRenderer, CompositeOutlineRenderer.

## [0.2.0] - 2026-02-08

### Added
- **Transparent Material Support**: Integrated a two-pass rendering approach (Stencil Overwrite + Outline Draw) to prevent the outline from being visible through transparent bodies.
- **Scale-Independent Thickness**: Updated the shader vertex transformation to world space, ensuring the outline thickness remains consistent even if the object is scaled.
- **Customizable Rendering Targets**: Added an explicit `OutlineElement` field to `OutlineRenderer` for better control over which part of a GameObject receives the outline.
- **OutlineParam Struct**: Introduced a dedicated struct to clean up the data flow between renderers and rendering elements.

### Improved
- **Material Management**: Implemented a static material pool (`_outlineMaskPool`) in `OutlineElement` to minimize memory overhead for stencil operations.
- **Code Structure**: Refactored rendering logic to use `OutlineParam` for improved maintainability.

---

## [0.1.0] - 2026-02-03
### Added
- Initial release with basic Inverted Hull rendering and Smooth Normal Baking.