using UnityEngine;

namespace WatercolorPond
{
    public sealed class WatercolorPrototypeControls : MonoBehaviour
    {
        [SerializeField] private Material pondMaterial;
        [SerializeField] private bool animateReveal = true;
        [SerializeField] private float revealCycleSeconds = 10f;

        private static readonly int RevealAmountId = Shader.PropertyToID("_RevealAmount");

        private void Update()
        {
            if (!animateReveal || pondMaterial == null || revealCycleSeconds <= 0.01f)
            {
                return;
            }

            float reveal = Mathf.PingPong(Time.time / revealCycleSeconds, 1f);
            pondMaterial.SetFloat(RevealAmountId, Mathf.SmoothStep(0.25f, 1f, reveal));
        }
    }
}
