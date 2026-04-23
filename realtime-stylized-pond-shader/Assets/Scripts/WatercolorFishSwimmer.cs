using UnityEngine;

namespace WatercolorPond
{
    public sealed class WatercolorFishSwimmer : MonoBehaviour
    {
        [SerializeField] private Vector3 center = Vector3.zero;
        [SerializeField] private Vector2 radius = new Vector2(2.4f, 1.2f);
        [SerializeField] private float speed = 0.25f;
        [SerializeField] private float phase;
        [SerializeField] private float verticalWobble = 0.015f;

        private float baseY;

        private void Awake()
        {
            baseY = transform.position.y;
        }

        private void Update()
        {
            float t = Time.time * speed + phase;
            Vector3 position = center + new Vector3(Mathf.Cos(t) * radius.x, baseY, Mathf.Sin(t) * radius.y);
            position.y += Mathf.Sin(t * 1.7f) * verticalWobble;
            transform.position = position;

            Vector3 tangent = new Vector3(-Mathf.Sin(t) * radius.x, 0f, Mathf.Cos(t) * radius.y);
            if (tangent.sqrMagnitude > 0.0001f)
            {
                transform.rotation = Quaternion.LookRotation(tangent.normalized, Vector3.up);
            }
        }

        public void Configure(Vector3 pathCenter, Vector2 pathRadius, float pathSpeed, float pathPhase)
        {
            center = pathCenter;
            radius = pathRadius;
            speed = pathSpeed;
            phase = pathPhase;
        }
    }
}
