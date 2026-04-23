# Stylized Watercolor Water Shader Documentation

## Overview
This shader creates a soft, painterly watercolor appearance for water in top-down or orthographic scenes. It mimics the organic, diffuse nature of watercolor pigments without any physically-based rendering, reflections, or specular highlights.

---

## Shader Architecture

### 1. **Base Color Layer**
```hlsl
float2 center = float2(0.5, 0.5);
float distFromCenter = length(uv - center);
float gradientMask = smoothstep(0.0, 1.0, distFromCenter * 1.5);
float4 baseColor = lerp(_BaseColor, _BaseColor2, gradientMask);
```

**Purpose:** Adds subtle depth by creating a radial gradient from center to edges.

**How it works:**
- Calculates distance from center (0.5, 0.5)
- Uses `smoothstep` to create soft transition
- Blends between two base colors based on distance

**Parameters:**
- `_BaseColor`: Primary water color (default: teal `0.3, 0.7, 0.75`)
- `_BaseColor2`: Edge/gradient color (default: darker teal `0.2, 0.6, 0.65`)

---

### 2. **Watercolor Pigment Noise**
```hlsl
float pigmentNoise = FractalNoise(uv, _NoiseScale, time * _NoiseSpeed);
pigmentNoise = pigmentNoise * 2.0 - 1.0;
waterColor.rgb += pigmentNoise * _NoiseStrength;
```

**Purpose:** Creates organic color variation that mimics pigment drift and bleeding in watercolor.

**How it works:**
- Uses multi-octave fractal noise (Perlin-like)
- Smoothly interpolates between grid points using Hermite curves
- Animates over time by offset UV coordinates with a time factor
- Remaps noise from [0, 1] to [-1, 1] for bidirectional color shift
- Adds small intensity to final color

**Key Functions:**
- `Hash()`: Pseudorandom function that maps 2D coordinates to deterministic values
- `SmoothNoise()`: Single octave with smooth Hermite interpolation
- `FractalNoise()`: Combines 3 octaves with decreasing amplitude (adds organic detail)

**Parameters:**
- `_NoiseScale`: Frequency of noise (larger = bigger pigment patches). Default: `2.0`
  - Lower values (1.0–2.0): Large, soft color transitions
  - Higher values (3.0–5.0): More frequent variation
- `_NoiseSpeed`: Animation speed. Default: `0.3` (subtle, slow drift)
- `_NoiseStrength`: Intensity of color variation. Default: `0.05` (5%)
  - Range: 0.03–0.08 for watercolor look
  - Higher values = more saturated color shifts

---

### 3. **UV Distortion (Motion Effect)**
```hlsl
float2 distortionNoise = float2(
    FractalNoise(uv + float2(12.5, 43.2), _NoiseScale, time * _NoiseSpeed),
    FractalNoise(uv + float2(78.9, 21.4), _NoiseScale, time * _NoiseSpeed)
);
float2 uvDistorted = uv + distortionNoise * _DistortionStrength;
```

**Purpose:** Creates subtle warping that looks like floating pigment and liquid motion.

**How it works:**
- Generates two independent noise fields (X and Y offset)
- Uses offset seed values (12.5, 43.2, etc.) to decorrelate X and Y distortion
- Applies distortion to UVs for sampling future textures/elements
- Very subtle to maintain readability

**Parameters:**
- `_DistortionStrength`: Magnitude of displacement. Default: `0.01` (1%)
  - Range: 0.005–0.02 recommended
  - Too high (>0.03): Creates unrealistic warping
  - Too low (<0.005): Motion barely visible

---

### 4. **Paper Texture Overlay**
```hlsl
float paperTexture = PaperNoise(uvDistorted, _PaperTextureScale);
float paperModulation = lerp(0.95, 1.05, paperTexture);
waterColor.rgb *= mix(1.0, paperModulation, _PaperTextureStrength);
```

**Purpose:** Adds subtle paper grain to simulate absorption into paper fibers.

**How it works:**
- Uses high-frequency noise (scaled by `_PaperTextureScale * 2`)
- Creates modulation factor between 0.95 and 1.05 (±5% brightness)
- Blends this effect based on `_PaperTextureStrength`
- Applied after pigment noise (distorted UVs) for authentic fiber interaction

**Parameters:**
- `_PaperTextureScale`: Grain frequency. Default: `8.0`
  - Lower values (4.0–6.0): Coarse, visible grain
  - Higher values (8.0–12.0): Fine, subtle texture
- `_PaperTextureStrength`: Texture intensity. Default: `0.08` (8%)
  - Range: 0.05–0.15 for watercolor
  - Higher values = rougher, more textured appearance

---

### 5. **Soft Edge Blending**
```hlsl
float edgeMask = smoothstep(0.0, _EdgeSoftness, uv.x) 
               * smoothstep(0.0, _EdgeSoftness, uv.y)
               * smoothstep(1.0, 1.0 - _EdgeSoftness, uv.x)
               * smoothstep(1.0, 1.0 - _EdgeSoftness, uv.y);
finalColor.a = edgeMask;
```

**Purpose:** Creates smooth falloff at quad/plane edges for seamless blending.

**How it works:**
- Creates a rectangular mask that's soft at all four edges
- Four `smoothstep` calls fade in from all sides
- Output as alpha channel for blending with background or other geometry
- `_EdgeSoftness` controls transition width

**Parameters:**
- `_EdgeSoftness`: Feathering width. Default: `0.5`
  - Lower values (0.1–0.3): Sharp, narrow transition
  - Higher values (0.5–0.8): Softer, wider fade

---

## Noise Algorithm Details

### Perlin-like Procedural Noise
The shader uses a custom noise implementation without texture lookups:

1. **Hashing:** Converts 2D coordinates to pseudo-random values
2. **Grid Interpolation:** Divides space into cells
3. **Hermite Smoothing:** Smooth `(3t² - 2t³)` curve instead of linear
4. **Bilinear Interpolation:** Smoothly blends between 4 corner values

**Advantages:**
- No texture memory required
- Tileable and deterministic
- Smooth gradients (perfect for watercolor)

---

## Recommended Settings for Watercolor Look

### **Subtle, Calm Water**
```
Base Color:            RGB(76, 179, 191) / HEX #4CB3BF (light teal)
Base Color 2:          RGB(51, 153, 166) / HEX #3399A6 (darker teal)
Noise Scale:           1.5 (large patches)
Noise Speed:           0.2 (slow drift)
Noise Strength:        0.04 (subtle variation)
Distortion Strength:   0.008 (minimal warping)
Paper Texture Scale:   8.0
Paper Texture Strength: 0.07
Edge Softness:         0.4
```

### **Medium Activity (Default)**
```
Base Color:            RGB(77, 179, 192) / HEX #4DB3C0
Base Color 2:          RGB(51, 153, 166) / HEX #3399A6
Noise Scale:           2.0
Noise Speed:           0.3
Noise Strength:        0.05
Distortion Strength:   0.01
Paper Texture Scale:   8.0
Paper Texture Strength: 0.08
Edge Softness:         0.5
```

### **More Expressive (Active Water)**
```
Base Color:            RGB(102, 204, 204) / HEX #66CCCC (lighter cyan)
Base Color 2:          RGB(51, 153, 166) / HEX #3399A6
Noise Scale:           2.5 (more frequent variation)
Noise Speed:           0.5 (faster animation)
Noise Strength:        0.08 (more obvious color shifts)
Distortion Strength:   0.015 (more visible motion)
Paper Texture Scale:   6.0 (coarser grain)
Paper Texture Strength: 0.1
Edge Softness:         0.6
```

---

## Usage in Unity

### Setup Steps:
1. **Place shader** in `Assets/Shaders/WatercolorWater.shader`
2. **Create material:** Right-click → Create → Material
3. **Assign shader:** Drag shader into material's shader slot
4. **Apply to geometry:** 
   - Create a plane or quad
   - Assign material to renderer
   - Ensure **Normal Mapping** is disabled (not used in shader)

### For Top-Down Scene:
- Use **orthographic camera** for best 2D appearance
- Place water plane below other elements (lily pads, rocks)
- Scale plane to fill view
- Optionally add a Canvas with RawImage for true 2D UI style

### Blending with Other Elements:
The shader outputs alpha based on `_EdgeSoftness`. To blend water with lily pads:
- Use `lerp()` in a second pass or shader
- Example: `finalColor = lerp(waterColor, lilyPadColor, lilyPadMask)`

---

## Animation Behavior

The shader animates based on `_Time.y` (global shader time):
- **Pigment drift:** Slowly shifts color patches across the surface
- **Distortion motion:** Creates gentle wavering effect
- **Interaction:** UVs are continuously warped, creating living appearance

**Note:** All motion is continuous and loops seamlessly due to noise properties.

---

## Performance Considerations

- **Noise computation:** 3 octaves × 2 channels (distortion) = 6 noise samples per frame
- **GPU cost:** ~1-2ms on modern hardware per fullscreen quad
- **Memory:** Minimal (no textures; uses procedural generation)
- **Optimization:** Can reduce to 2 octaves if needed (change loop count in `FractalNoise()`)

---

## Common Customizations

### Change Base Colors
Modify `_BaseColor` and `_BaseColor2` in material inspector. Good color combinations:
- Soft mint: `(0.4, 0.8, 0.75)` → `(0.2, 0.6, 0.65)`
- Pale blue: `(0.5, 0.75, 0.8)` → `(0.3, 0.6, 0.75)`
- Warm green: `(0.5, 0.7, 0.5)` → `(0.3, 0.5, 0.4)`

### Animated Lily Pads
Use `uvDistorted` from the shader to offset floating lily pad textures, creating synchronized motion.

### Add Flowing Fish
Sample a fish texture using `uvDistorted` and blend opacity based on distance from camera.

---

## Stylization Principles Applied

✓ **No specular highlights** – Watercolor doesn't have shiny spots  
✓ **No reflections** – Painterly effect prevents mirror-like surfaces  
✓ **Soft gradients** – Uses smoothstep and Hermite curves exclusively  
✓ **Organic noise** – Multi-octave fractal mimics natural pigment distribution  
✓ **Subtle motion** – Slow animation for meditative, calm feel  
✓ **Paper texture** – Adds tactile quality of watercolor medium  

---

## References
- **Watercolor reference:** Provided image shows soft color blending, organic shapes, minimal contrast
- **Noise generation:** Perlin-like algorithm without texture dependency
- **URP compatibility:** Uses Universal Render Pipeline shaders and conventions
