using System;
using System.Runtime.InteropServices;
using UnityEngine;

namespace Blackboard 
{
    public enum VariantType : byte
    {
        None,
        Int,
        Float,
        Bool,
        String,
        Object
    }
    
    [StructLayout(LayoutKind.Explicit)]
    public struct Variant : IEquatable<Variant>
    {
        [FieldOffset(0)] private VariantType type;
        [FieldOffset(8)] private long intValue;
        [FieldOffset(8)] private double floatValue;
        [FieldOffset(8)] private bool boolValue;
        
        [FieldOffset(16)] private object objValue;
        
        public bool IsEmpty => type == VariantType.None;
        public VariantType Type => type;
        
        public Variant(int value) : this() // this()를 호출해 모든 필드 초기화
        {
            type = VariantType.Int;
            intValue = value;
        }

        public Variant(float value) : this()
        {
            type = VariantType.Float;
            floatValue = value;
        }

        public Variant(bool value) : this()
        {
            type = VariantType.Bool;
            boolValue = value;
        }

        public Variant(string value) : this()
        {
            type = VariantType.String;
            objValue = value;
        }
        
        public Variant(object value) : this()
        {
            type = VariantType.Object;
            objValue = value;
        }

        public bool TryGetValue<T>(out T value)
        {
            if (typeof(T) == typeof(int) && type == VariantType.Int)
            {
                value = (T)(object)(int)intValue;
                return true;
            }
            
            if (typeof(T) == typeof(float) && type == VariantType.Float)
            {
                value = (T)(object)(float)floatValue;
                return true;
            }
            
            if (typeof(T) == typeof(bool) && type == VariantType.Bool)
            {
                value = (T)(object)(bool)boolValue;
                return true;
            }
    
            if (typeof(T) == typeof(string) && type == VariantType.String || typeof(T) == typeof(object) && type == VariantType.Object)
            {
                value = (T)objValue;
                return true;
            }

            value = default;
            return false;
        }
        
        public static implicit operator Variant(int value) => new(value);
        public static implicit operator Variant(float value) => new(value);
        public static implicit operator Variant(bool value) => new(value);
        public static implicit operator Variant(string value) => new(value);
        public static Variant FromObject(object value) => new(value);

        public static explicit operator int(Variant v) => v.TryGetValue<int>(out var value) ? value : 0;
        public static explicit operator float(Variant v) => v.TryGetValue<float>(out var value) ? value : 0;
        public static explicit operator bool(Variant v) => v.TryGetValue<bool>(out var value) && value;
        public static explicit operator string(Variant v) => v.TryGetValue<string>(out var value) ? value : null;
        public static object ToObject(Variant v) => v.TryGetValue<object>(out var value) ? value : null;

        public bool Equals(Variant other)
        {
            if (type != other.type) return false;
            switch (type) 
            {
                case VariantType.None:
                    return true;
                case VariantType.Int:
                    return intValue == other.intValue;
                case VariantType.Float:
                    return floatValue == other.floatValue;
                case VariantType.Bool:
                    return boolValue == other.boolValue;
                case VariantType.String:
                    return (string)objValue == (string)other;
                case VariantType.Object:
                    return objValue == other.objValue;
                    break;
                default:
                    throw new ArgumentOutOfRangeException();
            }
        }

        public override bool Equals(object obj)
        {
            return obj is Variant other && Equals(other);
        }

        public override int GetHashCode()
        {
            return HashCode.Combine((int)type, intValue, floatValue, boolValue, objValue);
        }
    }
}
