using UnityEditor;
using UnityEditor.UIElements;
using UnityEngine;
using UnityEngine.UIElements;

namespace _2510.SimpleMeshOutline.Editor
{
    [CustomPropertyDrawer(typeof(InlineToggleAttribute))]
    public class InlineToggleDrawer : PropertyDrawer
    {
        public override VisualElement CreatePropertyGUI(SerializedProperty property)
        {
            var attr = (InlineToggleAttribute)attribute;
            string path = property.propertyPath;
            int lastDot = path.LastIndexOf('.');
            string parentPath = lastDot != -1 ? path.Substring(0, lastDot + 1) : "";
            var toggleProp = property.serializedObject.FindProperty(parentPath + attr.ToggleFieldName);

            var container = new VisualElement { style = { flexDirection = FlexDirection.Row, marginBottom = 2 } };

            if (toggleProp != null && toggleProp.propertyType == SerializedPropertyType.Boolean)
            {
                // 1. 토글 생성
                var toggleField = new PropertyField(toggleProp, "");
                toggleField.style.width = 20;
                toggleField.style.marginRight = 5;

                // 2. 데이터 필드 생성 (Range 여부에 따라 분기)
                VisualElement dataField;
                if (attr.UseRange && property.propertyType == SerializedPropertyType.Float)
                {
                    // 슬라이더 생성 및 숫자 입력칸 활성화
                    var slider = new Slider(property.displayName, attr.Min, attr.Max)
                    {
                        bindingPath = property.propertyPath,
                        showInputField = true // 이 설정이 숫자 입력칸을 나타나게 합니다.
                    };
                    slider.labelElement.style.minWidth = 120; // 라벨 너비 확보
                    dataField = slider;
                }
                else
                {
                    dataField = new PropertyField(property, property.displayName);
                }
                
                dataField.style.flexGrow = 1;

                // 3. 활성화 상태 동기화
                void UpdateEnabled(bool val) => dataField.SetEnabled(val);
                UpdateEnabled(toggleProp.boolValue);
                toggleField.RegisterValueChangeCallback(evt => UpdateEnabled(evt.changedProperty.boolValue));

                container.Add(toggleField);
                container.Add(dataField);
            }
            return container;
        }
    }
}