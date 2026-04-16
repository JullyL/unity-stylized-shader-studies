using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.RenderGraphModule.Util;
using UnityEngine.Rendering.Universal;

public class MoebiusThreePassFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class Settings
    {
        public Material material;
        public RenderPassEvent passEvent = RenderPassEvent.AfterRenderingTransparents;
    }

    public Settings settings = new Settings();

    private MoebiusThreePassRenderPass pass;

    public override void Create()
    {
        pass = new MoebiusThreePassRenderPass();
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (settings.material == null)
            return;

        pass.Setup(settings.material, settings.passEvent);
        renderer.EnqueuePass(pass);
    }

    private sealed class MoebiusThreePassRenderPass : ScriptableRenderPass
    {
        private const string FixedPassName = "Moebius Fixed Composite";
        private const string Pass1Name = "Moebius Pass 1 - Color Depth";
        private const string Pass2Name = "Moebius Pass 2 - Normal Spec";
        private const string Pass3Name = "Moebius Pass 3 - Composite";

        private static readonly int ColorDepthTexId = Shader.PropertyToID("_ColorDepthTex");
        private static readonly int NormalSpecTexId = Shader.PropertyToID("_NormalSpecTex");

        private Material material;

        private class BlitPassData
        {
            public Material material;
            public TextureHandle source;
        }

        private class CompositePassData
        {
            public Material material;
            public TextureHandle source;
        }

        public MoebiusThreePassRenderPass()
        {
            requiresIntermediateTexture = true;
            ConfigureInput(ScriptableRenderPassInput.Depth | ScriptableRenderPassInput.Normal);
        }

        public void Setup(Material material, RenderPassEvent passEvent)
        {
            this.material = material;
            renderPassEvent = passEvent;
        }

        public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
        {
            if (material == null)
                return;

            var resourceData = frameData.Get<UniversalResourceData>();

            if (resourceData.isActiveTargetBackBuffer)
            {
                Debug.LogWarning("Skipping MoebiusThreePassFeature because the active target is the backbuffer.");
                return;
            }

            var source = resourceData.activeColorTexture;
            if (!source.IsValid())
                return;

            if (material.shader != null && material.shader.name == "Custom/Moebius3Pass_Fixed")
            {
                var fixedDesc = renderGraph.GetTextureDesc(source);
                fixedDesc.name = "_MoebiusFixedCompositeTex";
                fixedDesc.clearBuffer = false;
                fixedDesc.depthBufferBits = DepthBits.None;
                fixedDesc.msaaSamples = MSAASamples.None;

                var destination = renderGraph.CreateTexture(fixedDesc);
                var blitParams = new RenderGraphUtils.BlitMaterialParameters(source, destination, material, 2);
                renderGraph.AddBlitPass(blitParams, FixedPassName);
                resourceData.cameraColor = destination;
                return;
            }

            var desc = renderGraph.GetTextureDesc(source);
            desc.clearBuffer = false;
            desc.depthBufferBits = DepthBits.None;
            desc.msaaSamples = MSAASamples.None;

            desc.name = "_ColorDepthTex";
            var colorDepth = renderGraph.CreateTexture(desc);

            desc.name = "_NormalSpecTex";
            var normalSpec = renderGraph.CreateTexture(desc);

            desc.name = "_MoebiusCompositeTex";
            var composite = renderGraph.CreateTexture(desc);

            using (var builder = renderGraph.AddRasterRenderPass<BlitPassData>(Pass1Name, out var passData))
            {
                passData.material = material;
                passData.source = source;

                builder.UseTexture(source, AccessFlags.Read);
                builder.SetRenderAttachment(colorDepth, 0, AccessFlags.Write);
                builder.SetGlobalTextureAfterPass(colorDepth, ColorDepthTexId);

                builder.SetRenderFunc((BlitPassData data, RasterGraphContext ctx) =>
                {
                    Blitter.BlitTexture(ctx.cmd, data.source, Vector4.one, data.material, 0);
                });
            }

            using (var builder = renderGraph.AddRasterRenderPass<BlitPassData>(Pass2Name, out var passData))
            {
                passData.material = material;
                passData.source = source;

                builder.UseTexture(source, AccessFlags.Read);
                builder.SetRenderAttachment(normalSpec, 0, AccessFlags.Write);
                builder.SetGlobalTextureAfterPass(normalSpec, NormalSpecTexId);

                builder.SetRenderFunc((BlitPassData data, RasterGraphContext ctx) =>
                {
                    Blitter.BlitTexture(ctx.cmd, data.source, Vector4.one, data.material, 1);
                });
            }

            using (var builder = renderGraph.AddRasterRenderPass<CompositePassData>(Pass3Name, out var passData))
            {
                passData.material = material;
                passData.source = source;

                builder.UseTexture(source, AccessFlags.Read);
                builder.UseGlobalTexture(ColorDepthTexId, AccessFlags.Read);
                builder.UseGlobalTexture(NormalSpecTexId, AccessFlags.Read);
                builder.SetRenderAttachment(composite, 0, AccessFlags.Write);

                builder.SetRenderFunc((CompositePassData data, RasterGraphContext ctx) =>
                {
                    Blitter.BlitTexture(ctx.cmd, data.source, Vector4.one, data.material, 2);
                });
            }

            resourceData.cameraColor = composite;
        }
    }
}
