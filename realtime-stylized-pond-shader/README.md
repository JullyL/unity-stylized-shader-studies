# Real-Time Stylized Pond Shader with Mask-Based Animation

## Project Overview
This project explores a real-time stylized pond shader system in Unity (URP), inspired by the visual harmony of koi fish and lily pads in traditional Chinese aesthetics.  
The core idea is to create rich layered motion and appearance effects through shader logic and texture-driven data, instead of complex geometry or expensive simulation.

## Objectives
- Simulate layered water, lily pads, and animated koi fish in a single pond scene.
- Use mask maps and depth maps to control visibility, reveal order, and timing.
- Use custom UV mapping for fish movement paths.
- Achieve visually compelling animation with minimal geometry and strong runtime performance.

## Core Technical Approach

### 1) Texture Design (Substance Designer)
**Water Environment**
- Water albedo with soft painterly color variation.

**Lily Pad System**
- Plant albedo (lily pads composited with water style).
- Plant normal map (leaf detail + subtle ripple distortion support).
- Binary mask map (defines lily pad regions for blending and control).
- Grayscale depth map (defines ordered reveal timing per lily pad).

**Fish**
- Transparent koi PNG textures for compositing.

### 2) UV Mapping Strategy (Blender + Unity)
- **UV1**: Standard base texture mapping for water and lily pad layers.
- **UV2**: Encoded fish path layout used for time-driven movement in shader.

### 3) Shader Implementation (Shader Graph or HLSL)
**Water Layer**
- Base texture sampling.
- Normal-map-based UV distortion to simulate gentle refraction.

**Lily Pad Layer**
- Mask-based blending between water and plant textures.
- Depth-driven reveal using `smoothstep` for ordered, soft animation.

**Fish Layer**
- UV2-based sampling for fish path control.
- Time-driven UV offset for movement.
- Alpha blending for clean compositing over water.

**Final Composition**
- Layered blending and interpolation controlled by maps and timing parameters.

## Expected Results
- A visually rich animated pond scene.
- Smooth and ordered appearance of lily pads.
- Living fish motion along predefined paths.
- Full effect achieved on a single plane mesh via shader logic.

## Toolchain
- Unity (URP)
- Shader Graph and/or HLSL
- Adobe Substance 3D Designer
- Blender (UV2 layout)

## Suggested Folder Structure
```text
realtime-stylized-pond-shader/
  README.md
  Docs/
    Proposal/
    FinalReport/
  Textures/
    Water/
    LilyPads/
    Fish/
  Materials/
  Shaders/
  Scenes/
  References/
```

## Milestone Plan
1. **Texture Authoring**: Create water, lily pad, mask, depth, and fish textures.
2. **UV Setup**: Build UV1/UV2 layouts and validate path readability.
3. **Shader Layering**: Implement water + lily pad blending.
4. **Animation Logic**: Add depth-driven reveal and fish UV animation.
5. **Polish & Optimization**: Tune visual style, performance, and exposed controls.

## 2-Week Completion Plan

### Week 1 - Build Core Assets and Shader Foundation (Apr 15-Apr 21)
**Day 1 (Wed, Apr 15): Project setup + references**
- Organize folders (`Textures`, `Shaders`, `Materials`, `Scenes`, `Docs`).
- Collect visual references and lock style targets (watercolor + stylized pond mood).
- Create a test scene with a single plane and basic lighting.

**Day 2 (Thu, Apr 16): Water texture authoring**
- Create and export water albedo.
- Build first-pass normal map for subtle distortion and ripple direction.
- Import textures into Unity and verify color space/settings.

**Day 3 (Fri, Apr 17): Lily pad texture set**
- Author lily pad albedo and normal map.
- Create binary mask map for lily pad regions.
- Validate edge quality and alpha cleanliness.

**Day 4 (Sat, Apr 18): Depth map logic**
- Author grayscale depth map with varied values per lily pad.
- Check value distribution to support ordered reveal.
- Prepare quick debug material to visualize depth values in Unity.

**Day 5 (Sun, Apr 19): UV pipeline**
- Build UV1 base mapping.
- Create UV2 fish-path layout in Blender.
- Import and verify UV2 channels are preserved in Unity mesh data.

**Day 6 (Mon, Apr 20): Water + lily pad shader integration**
- Implement water base sampling and normal-driven UV distortion.
- Add mask-based blending for lily pads.
- Expose parameters for blend strength and distortion intensity.

**Day 7 (Tue, Apr 21): Lily pad reveal animation**
- Add depth-driven reveal using `smoothstep`.
- Tune reveal thresholds/speed and test different timing curves.
- Capture first video/gif test for progress tracking.

### Week 2 - Add Fish Animation, Polish, and Final Delivery (Apr 22-Apr 28)
**Day 8 (Wed, Apr 22): Fish texture + compositing setup**
- Import koi PNG textures.
- Add fish layer sampling and alpha blending in shader graph/HLSL.
- Confirm sorting/compositing order against water and lily pads.

**Day 9 (Thu, Apr 23): UV2 fish movement**
- Implement time-based UV2 offset for movement paths.
- Add speed, offset, and phase controls.
- Test multiple fish variants or repeated sampling for richer motion.

**Day 10 (Fri, Apr 24): Final layered composition**
- Integrate water, lily, and fish into a single master material.
- Normalize parameter ranges for artist-friendly controls.
- Check for artifacts at mask edges and texture seams.

**Day 11 (Sat, Apr 25): Artistic polish**
- Fine-tune color grading, contrast, and painterly style consistency.
- Improve ripple/refraction subtlety to avoid noisy visuals.
- Match overall pacing between fish motion and lily reveal.

**Day 12 (Sun, Apr 26): Optimization + profiling**
- Profile performance in Unity (frame timing, overdraw, shader cost).
- Reduce unnecessary texture samples where possible.
- Finalize shader keywords/toggles and clean unused nodes.

**Day 13 (Mon, Apr 27): Documentation + report assets**
- Capture screenshots and short clips of final effect.
- Document node logic / HLSL sections and parameter descriptions.
- Draft final report sections (method, implementation, results).

**Day 14 (Tue, Apr 28): Final QA + submission prep**
- Run a final pass for bugs, import settings, and scene cleanliness.
- Package project artifacts (scene, shader, textures, docs).
- Complete final report and submission checklist.

### Review Week Buffer (Apr 29-Apr 30)
**Wed, Apr 29: Contingency + rehearsal**
- Reserve time for unexpected fixes, shader regressions, or visual tuning.
- Rehearse final review demo flow and verify scene load reliability.
- Prepare backup media (video capture + screenshots) in case of runtime issues.

**Thu, Apr 30: Final Review**
- Deliver final review presentation and live/demo walkthrough.
- Submit final report and project package (if submission is same day).

### Final Deliverables Checklist
- Stylized pond shader scene running in Unity URP.
- Master shader/material with exposed controls.
- Texture set (water, lily pads, mask, depth, fish).
- Documentation (proposal, final report, implementation notes, media captures).

## Significance
This project demonstrates how texture maps and UV channels can encode spatial and temporal logic for lightweight real-time animation.  
Beyond technical efficiency, it also bridges cultural visual language and computational art practice by reinterpreting traditional pond aesthetics in interactive digital form.
