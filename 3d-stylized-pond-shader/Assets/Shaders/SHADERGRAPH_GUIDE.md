# Watercolor Water - Shader Graph Setup Guide

This document provides step-by-step instructions to recreate the watercolor water shader using Unity's Shader Graph visual editor. This is an alternative to the HLSL shader implementation.

## Prerequisites
- Shader Graph package installed (included in URP)
- Universal Render Pipeline project

## Node Structure (Simplified Overview)

### **Main Graph Hierarchy:**
```
Master Stack
├─ Base Color (input)
└─ Output (Fragment)
    ├─ Base Color Layer
    │   ├─ Base Color with Gradient
    │   ├─ + Pigment Noise
    │   ├─ + Paper Texture
    │   └─ Result → Color
    └─ Alpha
        └─ Edge Mask → Alpha
```

## Step-by-Step Shader Graph Recreation

### **1. Create Shader Graph Asset**
```
1. Right-click in Assets/Shaders/
2. Create → Shader Graph → URP/Lit (or Unlit for stylized look)
3. Name: "WatercolorWater.shadergraph"
4. Double-click to open Shader Graph editor
```

### **2. Create Input Properties**

Add these properties to the Blackboard (left panel):

| Property Name | Type | Default |
|---|---|---|
| Base Color | Color | (0.3, 0.7, 0.75, 1) |
| Base Color 2 | Color | (0.2, 0.6, 0.65, 1) |
| Noise Scale | Float | 2.0 |
| Noise Speed | Float | 0.3 |
| Noise Strength | Float | 0.05 |
| Distortion Strength | Float | 0.01 |
| Paper Texture Scale | Float | 8.0 |
| Paper Texture Strength | Float | 0.08 |
| Edge Softness | Float | 0.5 |

### **3. Procedural Noise Node (Main Challenge)**

Since Shader Graph doesn't include Perlin noise by default, use one of these approaches:

#### **Option A: Use Sample Texture 2D with Noise Texture**
1. Create a simple noise texture (white noise 256×256)
2. Add **Sample Texture 2D** node
3. Multiply UV by `Noise Scale`
4. Add `Time` × `Noise Speed` to UV for animation

```
[UV (0-1)] → × [Noise Scale] → + [Time × Noise Speed] → [Sample Texture 2D] → Output
```

#### **Option B: Use Custom Node with Procedural Noise**
Create a Sub-graph for noise:

```
Node Name: "ProceduralNoise"

Inputs:
  - UV (Vector2)
  - Scale (Float)
  - Time (Float)
  - Speed (Float)

Processing:
  1. Multiply UV by Scale
  2. Add Time × Speed for animation
  3. Use Frac node to create repeating pattern
  4. Use Sin/Cos combinations for smooth variation
  
Output: Noise (Float 0-1)
```

**Simple replacement logic:**
```
UV × Scale + Time × Speed 
→ Frac()
→ Sin() × Cos()
→ Abs() × oscillation factor
→ Normalize to 0-1
```

### **4. Build the Shader Network**

#### **Section A: Base Color with Gradient**
```
Inputs: Base Color, Base Color 2

1. Create UV node
2. Position Vector → Get (X, Y)
3. Subtract (0.5, 0.5) to center
4. Length node → distance from center
5. Smoothstep (0, 1.5, distance)
6. Lerp(Base Color, Base Color 2, result)
→ [Base Color Output]
```

#### **Section B: Pigment Noise Layer**
```
Inputs: Noise Scale, Noise Speed, Noise Strength

1. Create Procedural Noise (from UV, Scale, Time, Speed)
2. Remap from (0, 1) to (-1, 1):
   - Multiply by 2.0
   - Subtract 1.0
3. Multiply by Noise Strength
4. Add to Base Color RGB
5. Saturate to clamp values
→ [Water Color]
```

#### **Section C: UV Distortion**
```
Inputs: Noise Scale, Noise Speed, Distortion Strength

1. Create 2 Procedural Noise nodes (offset differently):
   - Noise 1: UV + offset (12.5, 43.2)
   - Noise 2: UV + offset (78.9, 21.4)
2. Remap both to (-1, 1)
3. Construct vector from both: Vector2(noise1, noise2)
4. Multiply by Distortion Strength
5. Add to original UV
→ [Distorted UV]
```

#### **Section D: Paper Texture Overlay**
```
Inputs: Distorted UV, Paper Texture Scale, Paper Texture Strength

1. Create Procedural Noise:
   - Input: Distorted UV × (Paper Texture Scale × 2)
2. Remap to (0.95, 1.05):
   - Multiply by 0.1
   - Add 0.95
3. Multiply with Water Color
4. Lerp(1.0, result, Paper Texture Strength)
→ [Final Color]
```

#### **Section E: Edge Softness Mask (Alpha)**
```
Inputs: Edge Softness

1. Create UV node
2. 4× Smoothstep nodes:
   - Smoothstep(0, Edge Softness, UV.x)
   - Smoothstep(0, Edge Softness, UV.y)
   - Smoothstep(1, 1 - Edge Softness, UV.x)
   - Smoothstep(1, 1 - Edge Softness, UV.y)
3. Multiply all 4 results together
→ [Alpha Output]
```

### **5. Connect to Master Stack**

- **Base Color** → Master Base Color input
- **Alpha** → Master Alpha input

### **6. Export Shader**

```
1. In Shader Graph window: File → Save
2. Right-click graph → Select All
3. The .shadergraph file is now usable in materials
```

## Alternative: Using Voronoi Pattern (Simplified)

If procedural noise is too complex, use **Voronoi** node as approximation:

```
1. Voronoi node (may be in community packages)
2. Add animation via Time offset
3. Use as pigment variation directly
4. Less organic but faster to set up
```

## Performance in Shader Graph

- **Procedural noise:** High cost (avoid multiple samples)
- **Texture-based noise:** Cheaper, use if available
- **Voronoi pattern:** Medium cost, good visual result
- **Recommendation:** Use one noise source, reuse for distortion

## Common Issues & Solutions

| Issue | Solution |
|---|---|
| Noise looks blocky | Use Smoothstep instead of Frac; increase octaves |
| Colors too saturated | Reduce Noise Strength parameter |
| Motion is jittery | Use Time.y instead of raw time; lower Noise Speed |
| Alpha not blending | Ensure Transparent queue in material settings |
| Shader compilation errors | Check Shader Graph version compatibility |

## Recommended Noise Implementation for Shader Graph

If you want proper Perlin-like noise, consider:

1. **Use OpenFBM or similar community subgraph**
2. **Download noise texture (512×512 seamless Perlin)**
3. **Implement simple hash function using Voronoi**

Here's a minimal noise function in Shader Graph:

```
Inputs: UV (0-1), Scale, Time, Speed

Steps:
1. Multiply: UV * Scale + Time * Speed
2. Frac node → repeating pattern
3. Smoothstep(0, 1, frac(uv.x)) * Smoothstep(0, 1, frac(uv.y))
4. Output: Float (0-1)

Result: Tile-based noise (less smooth but functional)
```

## Final Material Settings

Once shader is created:

```
Material Settings:
├─ Shader: WatercolorWater (your new graph)
├─ Surface Type: Opaque
├─ Blend Mode: Alpha (if using transparency)
├─ Cast Shadows: Off (stylized, no shadows)
└─ Properties: (See recommended values in main README.md)
```

---

## Why HLSL Over Shader Graph for This Project

The HLSL shader implementation is recommended because:
- ✓ Procedural noise is complex to express visually
- ✓ Multiple noise octaves require repeating node graphs
- ✓ Performance is better (direct code vs node compilation)
- ✓ Easier to iterate and tweak

However, **Shader Graph is great for:**
- ✓ Visual learning and experimentation
- ✓ Non-programmers wanting to understand the effect
- ✓ Quick prototyping of color values
