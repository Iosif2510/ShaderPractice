using UnityEngine;

namespace SDFs
{
    public class SDFSphere : SDFObject
    {
        [SerializeField] private float radius = 1f;
        
        public override float SignedDistanceFunction(Vector3 point)
        {
            var origin = transform.position;
            return Vector3.Distance(origin, point) - radius;
        }
    }
}