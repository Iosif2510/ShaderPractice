using UnityEngine;

namespace _2510.SimpleMeshOutline
{
    /// <summary>
    /// Defines the common contract for outline rendering components.
    /// Provides methods and properties to control visibility, thickness, and color customization.
    /// </summary>
    public interface IOutlineRenderer
    {
        /// <summary>
        /// Enable or disable outline rendering.
        /// </summary>
        /// <param name="enable">The active state to set, where true sets the outline to active and false sets it to inactive.</param>
        public void SetOutline(bool enable);
        
        /// <summary>
        /// Color of outline.
        /// </summary>
        public Color OutlineColor { get; }
        /// <summary>
        /// Thickness of outline.
        /// </summary>
        public float Thickness { get; }

        /// <summary>
        /// Set color of outline. Enables color customization if not already enabled.
        /// </summary>
        /// <param name="color">Color of outline.</param>
        public void SetOutlineColor(Color color);
        /// <summary>
        /// Set thickness of outline. Enables thickness customization if not already enabled.
        /// </summary>
        /// <param name="thickness">Thickness of outline.</param>
        public void SetOutlineThickness(float thickness);
        /// <summary>
        /// Enable or disable outline color customization.
        /// </summary>
        public void ToggleCustomizeColor(bool customize);
        /// <summary>
        /// Enable or disable outline thickness customization.
        /// </summary>
        public void ToggleCustomizeThickness(bool customize);
    }
}