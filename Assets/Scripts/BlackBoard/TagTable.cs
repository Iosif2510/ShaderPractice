using System.Collections.Generic;

namespace Blackboard
{
    public class TagTable
    {
        private Dictionary<string, Variant> _table;

        public Variant this[string tag]
        {
            get => _table[tag];
            set => _table[tag] = value;
        }

        public TagTable(int capacity = 0)
        {
            _table = new Dictionary<string, Variant>(capacity);
        }
        
        public void AddTag(string tag, int value) => _table.Add(tag, value);
        public void AddTag(string tag, float value) => _table.Add(tag, value);
        public void AddTag(string tag, bool value) => _table.Add(tag, value);
        public void AddTag(string tag, string value) => _table.Add(tag, value);
        public void AddTag(string tag, object value) => _table.Add(tag, Variant.FromObject(value));
        public void AddTag<T>(string tag, T value) where T : class => _table.Add(tag, Variant.FromObject(value));

        public bool TryGetValue<T>(string tag, out T value)
        {
            value = default;
            return _table.TryGetValue(tag, out var variant) && variant.TryGetValue(out value);
        }
        
        public void RemoveTag(string tag) => _table.Remove(tag);
    }
}