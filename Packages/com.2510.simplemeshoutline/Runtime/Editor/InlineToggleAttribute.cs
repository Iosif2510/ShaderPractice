using UnityEngine;

namespace _2510.SimpleMeshOutline.Editor
{
    public class InlineToggleAttribute : PropertyAttribute
    {
        public readonly string ToggleFieldName;
        public readonly float Min;
        public readonly float Max;
        public readonly bool UseRange;
        
        public InlineToggleAttribute(string toggleFieldName)
        {
            ToggleFieldName = toggleFieldName;
            UseRange = false;
        }
        
        public InlineToggleAttribute(string toggleFieldName, float min, float max)
        {
            ToggleFieldName = toggleFieldName;
            Min = min;
            Max = max;
            UseRange = true;
        }
    }
}