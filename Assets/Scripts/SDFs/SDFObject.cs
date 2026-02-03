using UnityEngine;

namespace SDFs
{
    public abstract class SDFObject : MonoBehaviour
    {
        public abstract float SignedDistanceFunction(Vector3 point);
    }
}
