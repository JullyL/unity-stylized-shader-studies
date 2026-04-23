# Quick Start Guide: Watercolor Water Shader

## 5-Minute Setup

### Step 1: Verify Shader in Project
✓ Check that `Assets/Shaders/WatercolorWater.shader` exists
✓ Unity should automatically compile it (check Console for errors)

### Step 2: Create a Material
```
1. Right-click in Assets/ → Create → Material
2. Name it "WaterMaterial"
3. In Inspector, set Shader dropdown to: "Stylized/WatercolorWater"
```

### Step 3: Create Water Geometry
```
1. Right-click in Hierarchy → 3D Object → Plane
2. Scale it to cover your scene (e.g., Scale: 10, 1, 10)
3. Assign the material to the plane's Mesh Renderer
```

### Step 4: Test and Adjust
```
Play the game → You should see animated teal water with soft motion
Adjust sliders in the material Inspector in real-time
Changes appear instantly in scene and Game views
```

---

## Inspector Parameters Explained

### **Color Parameters**
| Parameter | Current Default | Adjustment |
|---|---|---|
| **Base Color** | Teal (0.3, 0.7, 0.75) | Click color box to change water main hue |
| **Base Color 2** | Dark Teal (0.2, 0.6, 0.65) | Adjust edge/shadow color |

**Tip:** For warmer water, shift both toward yellow. For cooler, shift toward blue.

### **Animation Parameters**
| Parameter | Current Default | What It Controls |
|---|---|---|
| **Noise Scale** | 2.0 | Size of color patches (1-5) |
| **Noise Speed** | 0.3 | How fast pigment drifts (0.1-1.0) |
| **Noise Strength** | 0.05 | How much color varies (0.02-0.15) |
| **Distortion Strength** | 0.01 | How much UVs warp (0.005-0.03) |

### **Texture Parameters**
| Parameter | Current Default | What It Controls |
|---|---|---|
| **Paper Texture Scale** | 8.0 | Grain size (4-12) |
| **Paper Texture Strength** | 0.08 | How visible is grain (0.0-0.2) |

### **Edge Parameters**
| Parameter | Current Default | What It Controls |
|---|---|---|
| **Edge Softness** | 0.5 | Alpha fade at quad edges (0.0-1.0) |

---

## Preset Configurations

### **Calm Lake**
```
Base Color:           (0.3, 0.7, 0.75)
Base Color 2:         (0.2, 0.6, 0.65)
Noise Scale:          1.5
Noise Speed:          0.15
Noise Strength:       0.03
Distortion Strength:  0.005
Paper Texture Scale:  8.0
Paper Texture Strength: 0.05
Edge Softness:        0.4
→ Result: Very subtle, meditative water
```

### **Living Pond (Default)**
```
Base Color:           (0.3, 0.7, 0.75)
Base Color 2:         (0.2, 0.6, 0.65)
Noise Scale:          2.0
Noise Speed:          0.3
Noise Strength:       0.05
Distortion Strength:  0.01
Paper Texture Scale:  8.0
Paper Texture Strength: 0.08
Edge Softness:        0.5
→ Result: Balanced, visible but not chaotic
```

### **Turbulent Rapids**
```
Base Color:           (0.4, 0.7, 0.8)
Base Color 2:         (0.1, 0.5, 0.6)
Noise Scale:          3.0
Noise Speed:          0.6
Noise Strength:       0.1
Distortion Strength:  0.02
Paper Texture Scale:  6.0
Paper Texture Strength: 0.12
Edge Softness:        0.6
→ Result: More chaotic, visible motion
```

### **Tropical Pool**
```
Base Color:           (0.4, 0.85, 0.8)
Base Color 2:         (0.2, 0.7, 0.7)
Noise Scale:          1.8
Noise Speed:          0.25
Noise Strength:       0.04
Distortion Strength:  0.008
Paper Texture Scale:  10.0
Paper Texture Strength: 0.06
Edge Softness:        0.45
→ Result: Brighter, clearer water
```

---

## Integration with Your Scene

### **For Lily Pads:**
1. Create lily pad geometry (leaf planes or models)
2. Position above water plane (Y = 0.01)
3. Use shader's exported `uvDistorted` to add subtle sway:
   - Create second material with lily texture
   - Offset UV by sampled water distortion for animation

### **For Koi/Fish:**
1. Create fish mesh or sprite
2. Sample water shader's distorted UV for swimming path
3. Add opacity based on water color values for blending

### **For Top-Down Camera:**
```
Camera Settings:
├─ Projection: Orthographic (for flat appearance)
├─ Position: Above center (Y = 5)
├─ Rotation: (90, 0, 0) looking straight down
└─ Orthographic Size: Adjust to scene scale
```

---

## Troubleshooting

### **Shader not appearing in dropdown**
```
Solution: 
1. Check Assets/Shaders/ folder exists
2. Verify WatercolorWater.shader file is there
3. Restart Unity (Editor may need to recompile)
4. Check Console for compilation errors
```

### **Water looks flat/no animation**
```
Solution:
1. Increase Noise Speed to 0.5 (default is subtle)
2. Increase Noise Strength to 0.08
3. Ensure Game view is running (not just Scene view)
```

### **Color looks too saturated**
```
Solution:
1. Reduce Noise Strength to 0.03
2. Choose less vibrant Base Colors
3. Increase Base Color 2 darkness for better contrast
```

### **Paper texture too visible**
```
Solution:
1. Reduce Paper Texture Strength to 0.05
2. Increase Paper Texture Scale to 12 (finer grain)
```

### **Alpha/transparency not working**
```
Solution:
1. Check material Render Type is "Opaque"
2. Ensure Camera has "Depth Texture" enabled
3. If blending with background: Set Blend to Alpha
4. Check Canvas/UI rendering order if using UI
```

---

## Performance Tips

- **Mobile optimization:** Reduce Noise Speed, set Noise Strength to 0.02
- **Heavy scenes:** Disable animation by setting Noise Speed to 0
- **Desktop:** Can safely use default settings

---

## Customization Ideas

### **Make it Flow Like a River**
```
Modify shader to apply UV offset based on direction:
- Add flow direction parameter
- Offset noise sampling by world position
```

### **Add Depth Gradient**
```
Darken water further from camera:
- Use depth texture to fade toward darker color
```

### **Seasonal Variations**
```
Create three color presets:
- Spring: Bright, fresh green-blue
- Summer: Light, clear cyan
- Autumn: Warm amber-brown
```

---

## Next Steps

1. **Test the default shader** in your scene
2. **Adjust color values** to match your art style
3. **Tune animation speeds** for desired feel
4. **Reference the full README.md** for technical details
5. **Experiment with presets** to find your preferred look

---

## Reference Files

- `WatercolorWater.shader` — Main HLSL implementation
- `README.md` — Full technical documentation
- `SHADERGRAPH_GUIDE.md` — Visual node-based alternative
- `SETUP_NOTES.md` — This quick reference

Enjoy your stylized watercolor pond! 🎨
