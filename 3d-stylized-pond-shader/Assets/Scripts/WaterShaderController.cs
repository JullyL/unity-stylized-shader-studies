using UnityEngine;

/// <summary>
/// WaterShaderController - Provides runtime control and animation for the watercolor water shader.
/// Allows dynamic adjustment of shader parameters and synchronized animation across multiple water instances.
/// </summary>
public class WaterShaderController : MonoBehaviour
{
    [SerializeField] private Material waterMaterial;
    
    [Header("Color Animation")]
    [SerializeField] private Color baseColor = new Color(0.3f, 0.7f, 0.75f, 1f);
    [SerializeField] private Color baseColor2 = new Color(0.2f, 0.6f, 0.65f, 1f);
    [SerializeField] private bool animateColors = false;
    [SerializeField] private float colorAnimationSpeed = 0.5f;
    
    [Header("Noise Parameters")]
    [SerializeField] private float noiseScale = 2.0f;
    [SerializeField] private float noiseSpeed = 0.3f;
    [SerializeField] private float noiseStrength = 0.05f;
    [SerializeField] private float distortionStrength = 0.01f;
    
    [Header("Texture Parameters")]
    [SerializeField] private float paperTextureScale = 8.0f;
    [SerializeField] private float paperTextureStrength = 0.08f;
    [SerializeField] private float edgeSoftness = 0.5f;
    
    // Shader property IDs (cached for performance)
    private int baseColorId;
    private int baseColor2Id;
    private int noiseScaleId;
    private int noiseSpeedId;
    private int noiseStrengthId;
    private int distortionStrengthId;
    private int paperTextureScaleId;
    private int paperTextureStrengthId;
    private int edgeSoftnessId;

    private void OnEnable()
    {
        // Cache shader property IDs for better performance
        baseColorId = Shader.PropertyToID("_BaseColor");
        baseColor2Id = Shader.PropertyToID("_BaseColor2");
        noiseScaleId = Shader.PropertyToID("_NoiseScale");
        noiseSpeedId = Shader.PropertyToID("_NoiseSpeed");
        noiseStrengthId = Shader.PropertyToID("_NoiseStrength");
        distortionStrengthId = Shader.PropertyToID("_DistortionStrength");
        paperTextureScaleId = Shader.PropertyToID("_PaperTextureScale");
        paperTextureStrengthId = Shader.PropertyToID("_PaperTextureStrength");
        edgeSoftnessId = Shader.PropertyToID("_EdgeSoftness");
        
        // Ensure we have a material instance
        if (waterMaterial == null)
        {
            Renderer renderer = GetComponent<Renderer>();
            if (renderer != null)
            {
                waterMaterial = renderer.material; // Creates instance automatically
            }
        }
        
        UpdateAllParameters();
    }

    private void Update()
    {
        if (waterMaterial == null) return;
        
        // Optional: Animate colors over time for dynamic mood changes
        if (animateColors)
        {
            float hueShift = Mathf.Sin(Time.time * colorAnimationSpeed) * 0.1f;
            Color animatedColor = Color.Lerp(baseColor, baseColor2, (Mathf.Sin(Time.time * colorAnimationSpeed) + 1f) / 2f);
            waterMaterial.SetColor(baseColorId, animatedColor);
        }
    }

    /// <summary>
    /// Updates all shader parameters at once (useful for preset application)
    /// </summary>
    public void UpdateAllParameters()
    {
        if (waterMaterial == null) return;
        
        waterMaterial.SetColor(baseColorId, baseColor);
        waterMaterial.SetColor(baseColor2Id, baseColor2);
        waterMaterial.SetFloat(noiseScaleId, noiseScale);
        waterMaterial.SetFloat(noiseSpeedId, noiseSpeed);
        waterMaterial.SetFloat(noiseStrengthId, noiseStrength);
        waterMaterial.SetFloat(distortionStrengthId, distortionStrength);
        waterMaterial.SetFloat(paperTextureScaleId, paperTextureScale);
        waterMaterial.SetFloat(paperTextureStrengthId, paperTextureStrength);
        waterMaterial.SetFloat(edgeSoftnessId, edgeSoftness);
    }

    /// <summary>
    /// Apply a preset configuration to the water
    /// </summary>
    public enum WaterPreset
    {
        CalmLake,
        LivingPond,
        TurbulentRapids,
        TropicalPool
    }

    public void ApplyPreset(WaterPreset preset)
    {
        switch (preset)
        {
            case WaterPreset.CalmLake:
                noiseScale = 1.5f;
                noiseSpeed = 0.15f;
                noiseStrength = 0.03f;
                distortionStrength = 0.005f;
                paperTextureStrength = 0.05f;
                edgeSoftness = 0.4f;
                break;
                
            case WaterPreset.LivingPond:
                noiseScale = 2.0f;
                noiseSpeed = 0.3f;
                noiseStrength = 0.05f;
                distortionStrength = 0.01f;
                paperTextureStrength = 0.08f;
                edgeSoftness = 0.5f;
                break;
                
            case WaterPreset.TurbulentRapids:
                noiseScale = 3.0f;
                noiseSpeed = 0.6f;
                noiseStrength = 0.1f;
                distortionStrength = 0.02f;
                paperTextureScale = 6.0f;
                paperTextureStrength = 0.12f;
                edgeSoftness = 0.6f;
                break;
                
            case WaterPreset.TropicalPool:
                baseColor = new Color(0.4f, 0.85f, 0.8f, 1f);
                baseColor2 = new Color(0.2f, 0.7f, 0.7f, 1f);
                noiseScale = 1.8f;
                noiseSpeed = 0.25f;
                noiseStrength = 0.04f;
                distortionStrength = 0.008f;
                paperTextureScale = 10.0f;
                paperTextureStrength = 0.06f;
                edgeSoftness = 0.45f;
                break;
        }
        
        UpdateAllParameters();
    }

    /// <summary>
    /// Smoothly transition to a new noise speed (for dynamic intensity changes)
    /// </summary>
    public void TransitionNoiseSpeed(float targetSpeed, float duration)
    {
        StartCoroutine(SmoothTransition(
            targetSpeed: targetSpeed,
            duration: duration,
            parameterType: TransitionType.NoiseSpeed
        ));
    }

    /// <summary>
    /// Smoothly transition to a new color
    /// </summary>
    public void TransitionColor(Color targetColor, float duration, bool isBaseColor = true)
    {
        StartCoroutine(SmoothTransition(
            targetValue: targetColor,
            duration: duration,
            parameterType: isBaseColor ? TransitionType.BaseColor : TransitionType.BaseColor2
        ));
    }

    private enum TransitionType
    {
        NoiseSpeed,
        NoiseStrength,
        DistortionStrength,
        BaseColor,
        BaseColor2
    }

    private System.Collections.IEnumerator SmoothTransition(
        float targetSpeed = 0f,
        Color targetValue = default,
        float duration = 1f,
        TransitionType parameterType = TransitionType.NoiseSpeed)
    {
        float elapsedTime = 0f;
        
        float startSpeed = noiseSpeed;
        Color startColor = (parameterType == TransitionType.BaseColor) ? baseColor : baseColor2;

        while (elapsedTime < duration)
        {
            elapsedTime += Time.deltaTime;
            float t = Mathf.Clamp01(elapsedTime / duration);

            switch (parameterType)
            {
                case TransitionType.NoiseSpeed:
                    noiseSpeed = Mathf.Lerp(startSpeed, targetSpeed, t);
                    waterMaterial.SetFloat(noiseSpeedId, noiseSpeed);
                    break;
                    
                case TransitionType.BaseColor:
                    baseColor = Color.Lerp(startColor, targetValue, t);
                    waterMaterial.SetColor(baseColorId, baseColor);
                    break;
                    
                case TransitionType.BaseColor2:
                    baseColor2 = Color.Lerp(startColor, targetValue, t);
                    waterMaterial.SetColor(baseColor2Id, baseColor2);
                    break;
            }

            yield return null;
        }
    }

    /// <summary>
    /// Pause/resume animation (sets noise speed to 0)
    /// </summary>
    public void SetAnimationActive(bool isActive)
    {
        noiseSpeed = isActive ? 0.3f : 0f;
        waterMaterial.SetFloat(noiseSpeedId, noiseSpeed);
    }

    /// <summary>
    /// Get current material for advanced customization
    /// </summary>
    public Material GetWaterMaterial()
    {
        return waterMaterial;
    }
}
