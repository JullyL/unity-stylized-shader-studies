# Week 1 Prototype Notes

## Scene
- Open `Assets/Scenes/Week1_WatercolorPondPrototype.unity`.
- The camera is orthographic and top-down, matching the planned 2.5D pond composition.
- The scene uses a pond bottom plane, transparent watercolor composite surface, and three fish planes with simple path motion.

## Shader Controls
- `WatercolorPond_Master.mat` exposes the Week 1 controls: water/pigment colors, wash scale, drift speed, paper strength, reveal amount, bleed strength, edge darkening, fish speed, distortion strength, and depth tint.
- The runtime prototype uses URP HLSL shaders for reliability in source control. The shader properties map directly to the Shader Graph nodes planned for Week 1, so the material can be rebuilt as a graph later without changing the scene layout.
- `WatercolorPrototypeControls` animates `RevealAmount` with a slow ping-pong loop for quick Play Mode verification. Disable `Animate Reveal` to scrub the material property manually.

## Placeholder Data
- `Placeholder_PaperGrain.png`: procedural grayscale paper/fiber modulation.
- `Placeholder_LilyMask.png`: soft lily-pad mask with noisy shader bleeding.
- `Placeholder_DepthGradient.png`: reveal/depth control signal.
- `Placeholder_KoiAtlas.png`: transparent koi atlas for underwater compositing and fish planes.

## Week 2 Polish Targets
- Replace placeholder masks and koi atlas with authored art.
- Convert the HLSL master into Shader Graph/custom-function nodes if visual graph presentation is required.
- Add a global stylization pass or post-process for final palette/contrast unification.
