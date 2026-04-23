using System.IO;
using System.Reflection;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.SceneManagement;
using WatercolorPond;

public static class WatercolorPondPrototypeBuilder
{
    private const string ScenePath = "Assets/Scenes/Week1_WatercolorPondPrototype.unity";
    private const string SettingsPath = "Assets/Settings/Week1_URP_Asset.asset";
    private const string RendererDataPath = "Assets/Settings/Week1_UniversalRenderer.asset";
    private const string MasterMaterialPath = "Assets/Materials/WatercolorPond_Master.mat";
    private const string FishMaterialPath = "Assets/Materials/Fish_Underwater.mat";
    private const string BottomMaterialPath = "Assets/Materials/PondBottom.mat";
    private const string PaperPath = "Assets/Textures/Water/Placeholder_PaperGrain.png";
    private const string LilyMaskPath = "Assets/Textures/LilyPads/Placeholder_LilyMask.png";
    private const string DepthPath = "Assets/Textures/Water/Placeholder_DepthGradient.png";
    private const string FishPath = "Assets/Textures/Fish/Placeholder_KoiAtlas.png";

    [MenuItem("Pond Prototype/Build Week 1 Prototype")]
    public static void BuildWeek1Prototype()
    {
        EnsureFolders();
        AssetDatabase.Refresh();

        CreateRenderPipelineAsset();
        CreateTextures();
        AssetDatabase.Refresh();

        Material masterMaterial = CreateMasterMaterial();
        Material fishMaterial = CreateFishMaterial();
        Material bottomMaterial = CreateBottomMaterial();

        Scene scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
        scene.name = "Week1_WatercolorPondPrototype";

        GameObject root = new GameObject("Week 1 Watercolor Pond Prototype");
        WatercolorPrototypeControls controls = root.AddComponent<WatercolorPrototypeControls>();
        SerializedObject controlsObject = new SerializedObject(controls);
        controlsObject.FindProperty("pondMaterial").objectReferenceValue = masterMaterial;
        controlsObject.ApplyModifiedPropertiesWithoutUndo();

        CreatePlane("Pond Bottom", root.transform, new Vector3(0f, 0f, 0f), new Vector3(1.25f, 1f, 0.82f), bottomMaterial);
        CreatePlane("Watercolor Composite Surface", root.transform, new Vector3(0f, 0.06f, 0f), new Vector3(1.25f, 1f, 0.82f), masterMaterial);

        CreateFish("Koi A", root.transform, fishMaterial, new Vector3(0f, 0.035f, 0f), new Vector2(2.35f, 1.15f), 0.35f, 0f, new Vector3(0.13f, 1f, 0.055f));
        CreateFish("Koi B", root.transform, fishMaterial, new Vector3(-0.25f, 0.032f, 0.15f), new Vector2(1.55f, 0.86f), -0.28f, 1.8f, new Vector3(0.1f, 1f, 0.045f));
        CreateFish("Koi C", root.transform, fishMaterial, new Vector3(0.35f, 0.03f, -0.12f), new Vector2(1.95f, 0.72f), 0.22f, 3.6f, new Vector3(0.085f, 1f, 0.038f));

        CreateCamera();
        CreateLight();

        RenderSettings.ambientLight = new Color(0.78f, 0.84f, 0.78f);
        RenderSettings.skybox = null;

        EditorSceneManager.SaveScene(scene, ScenePath);
        EditorBuildSettings.scenes = new[] { new EditorBuildSettingsScene(ScenePath, true) };
        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();

        Debug.Log($"Built Week 1 watercolor pond prototype at {ScenePath}");
    }

    private static void EnsureFolders()
    {
        string[] folders =
        {
            "Assets/Scenes",
            "Assets/Shaders",
            "Assets/Materials",
            "Assets/Textures",
            "Assets/Textures/Water",
            "Assets/Textures/LilyPads",
            "Assets/Textures/Fish",
            "Assets/Settings"
        };

        foreach (string folder in folders)
        {
            if (!AssetDatabase.IsValidFolder(folder))
            {
                Directory.CreateDirectory(folder);
            }
        }
    }

    private static void CreateRenderPipelineAsset()
    {
        UniversalRendererData rendererData = LoadOrCreateRendererData();
        UniversalRenderPipelineAsset asset = AssetDatabase.LoadAssetAtPath<UniversalRenderPipelineAsset>(SettingsPath);
        if (asset == null)
        {
            asset = UniversalRenderPipelineAsset.Create(rendererData);
            AssetDatabase.CreateAsset(asset, SettingsPath);
        }

        SerializedObject serializedAsset = new SerializedObject(asset);
        SerializedProperty rendererList = serializedAsset.FindProperty("m_RendererDataList");
        rendererList.arraySize = 1;
        rendererList.GetArrayElementAtIndex(0).objectReferenceValue = rendererData;
        serializedAsset.FindProperty("m_DefaultRendererIndex").intValue = 0;
        serializedAsset.ApplyModifiedPropertiesWithoutUndo();

        asset.supportsCameraOpaqueTexture = true;
        asset.supportsCameraDepthTexture = true;
        asset.msaaSampleCount = 1;
        GraphicsSettings.defaultRenderPipeline = asset;
        QualitySettings.renderPipeline = asset;
        EditorUtility.SetDirty(asset);
    }

    private static UniversalRendererData LoadOrCreateRendererData()
    {
        UniversalRendererData rendererData = AssetDatabase.LoadAssetAtPath<UniversalRendererData>(RendererDataPath);
        if (rendererData != null)
        {
            return rendererData;
        }

        MethodInfo createRendererAsset = typeof(UniversalRenderPipelineAsset).GetMethod(
            "CreateRendererAsset",
            BindingFlags.Static | BindingFlags.NonPublic);

        if (createRendererAsset != null)
        {
            rendererData = createRendererAsset.Invoke(
                null,
                new object[] { RendererDataPath, RendererType.UniversalRenderer, false, "Renderer" }) as UniversalRendererData;
        }

        if (rendererData == null)
        {
            rendererData = ScriptableObject.CreateInstance<UniversalRendererData>();
            AssetDatabase.CreateAsset(rendererData, RendererDataPath);
        }

        EditorUtility.SetDirty(rendererData);
        return rendererData;
    }

    private static Material CreateMasterMaterial()
    {
        Shader shader = Shader.Find("Pond/WatercolorPondMaster");
        Material material = LoadOrCreateMaterial(MasterMaterialPath, shader);

        material.SetColor("_WaterColor", new Color(0.57f, 0.8f, 0.78f, 0.86f));
        material.SetColor("_PigmentColor", new Color(0.12f, 0.33f, 0.38f, 1f));
        material.SetColor("_DepthTint", new Color(0.19f, 0.43f, 0.47f, 1f));
        material.SetFloat("_WashScale", 5.8f);
        material.SetFloat("_DriftSpeed", 0.07f);
        material.SetFloat("_PaperStrength", 0.42f);
        material.SetFloat("_RevealAmount", 1f);
        material.SetFloat("_FishSpeed", 0.16f);
        material.SetFloat("_DistortionStrength", 0.24f);
        material.SetFloat("_SurfaceOpacity", 0.82f);
        material.SetTexture("_PaperGrainTexture", AssetDatabase.LoadAssetAtPath<Texture2D>(PaperPath));
        material.SetTexture("_LilyMask", AssetDatabase.LoadAssetAtPath<Texture2D>(LilyMaskPath));
        material.SetTexture("_DepthMap", AssetDatabase.LoadAssetAtPath<Texture2D>(DepthPath));
        material.SetTexture("_FishTexture", AssetDatabase.LoadAssetAtPath<Texture2D>(FishPath));

        EditorUtility.SetDirty(material);
        return material;
    }

    private static Material CreateFishMaterial()
    {
        Shader shader = Shader.Find("Pond/WatercolorFishUnderwater");
        Material material = LoadOrCreateMaterial(FishMaterialPath, shader);
        material.SetTexture("_FishTexture", AssetDatabase.LoadAssetAtPath<Texture2D>(FishPath));
        material.SetColor("_DepthTint", new Color(0.2f, 0.46f, 0.49f, 1f));
        material.SetFloat("_DistortionStrength", 0.2f);
        material.SetFloat("_FishOpacity", 0.72f);
        EditorUtility.SetDirty(material);
        return material;
    }

    private static Material CreateBottomMaterial()
    {
        Shader shader = Shader.Find("Universal Render Pipeline/Unlit") ?? Shader.Find("Unlit/Color");
        Material material = LoadOrCreateMaterial(BottomMaterialPath, shader);
        material.SetColor("_BaseColor", new Color(0.78f, 0.75f, 0.62f, 1f));
        material.SetColor("_Color", new Color(0.78f, 0.75f, 0.62f, 1f));
        EditorUtility.SetDirty(material);
        return material;
    }

    private static Material LoadOrCreateMaterial(string path, Shader shader)
    {
        Material material = AssetDatabase.LoadAssetAtPath<Material>(path);
        if (material == null)
        {
            material = new Material(shader);
            AssetDatabase.CreateAsset(material, path);
        }
        else if (shader != null)
        {
            material.shader = shader;
        }

        return material;
    }

    private static GameObject CreatePlane(string name, Transform parent, Vector3 position, Vector3 scale, Material material)
    {
        GameObject plane = GameObject.CreatePrimitive(PrimitiveType.Plane);
        plane.name = name;
        plane.transform.SetParent(parent);
        plane.transform.position = position;
        plane.transform.localScale = scale;

        Renderer renderer = plane.GetComponent<Renderer>();
        renderer.sharedMaterial = material;

        Object.DestroyImmediate(plane.GetComponent<Collider>());
        return plane;
    }

    private static void CreateFish(string name, Transform parent, Material material, Vector3 center, Vector2 radius, float speed, float phase, Vector3 scale)
    {
        GameObject fish = CreatePlane(name, parent, center + new Vector3(radius.x, 0f, 0f), scale, material);
        WatercolorFishSwimmer swimmer = fish.AddComponent<WatercolorFishSwimmer>();
        swimmer.Configure(center, radius, speed, phase);
    }

    private static void CreateCamera()
    {
        GameObject cameraObject = new GameObject("Main Camera");
        cameraObject.tag = "MainCamera";
        cameraObject.transform.position = new Vector3(0f, 7.4f, 0f);
        cameraObject.transform.rotation = Quaternion.Euler(90f, 0f, 0f);

        Camera camera = cameraObject.AddComponent<Camera>();
        camera.clearFlags = CameraClearFlags.SolidColor;
        camera.backgroundColor = new Color(0.9f, 0.91f, 0.82f, 1f);
        camera.orthographic = true;
        camera.orthographicSize = 4.05f;
        camera.nearClipPlane = 0.05f;
        camera.farClipPlane = 20f;

        UniversalAdditionalCameraData data = cameraObject.AddComponent<UniversalAdditionalCameraData>();
        data.renderPostProcessing = false;
    }

    private static void CreateLight()
    {
        GameObject lightObject = new GameObject("Soft Directional Light");
        lightObject.transform.rotation = Quaternion.Euler(55f, -30f, 0f);
        Light light = lightObject.AddComponent<Light>();
        light.type = LightType.Directional;
        light.color = new Color(1f, 0.96f, 0.85f, 1f);
        light.intensity = 0.6f;
    }

    private static void CreateTextures()
    {
        WriteTexture(PaperPath, GeneratePaperGrain(512), TextureWrapMode.Repeat, false);
        WriteTexture(LilyMaskPath, GenerateLilyMask(512), TextureWrapMode.Clamp, false);
        WriteTexture(DepthPath, GenerateDepthGradient(512), TextureWrapMode.Clamp, false);
        WriteTexture(FishPath, GenerateFishAtlas(512), TextureWrapMode.Clamp, true);
    }

    private static void WriteTexture(string path, Texture2D texture, TextureWrapMode wrapMode, bool alphaTransparency)
    {
        File.WriteAllBytes(path, texture.EncodeToPNG());
        Object.DestroyImmediate(texture);
        AssetDatabase.ImportAsset(path, ImportAssetOptions.ForceUpdate);

        TextureImporter importer = AssetImporter.GetAtPath(path) as TextureImporter;
        if (importer == null)
        {
            return;
        }

        importer.textureType = TextureImporterType.Default;
        importer.wrapMode = wrapMode;
        importer.filterMode = FilterMode.Bilinear;
        importer.mipmapEnabled = false;
        importer.alphaIsTransparency = alphaTransparency;
        importer.sRGBTexture = alphaTransparency;
        importer.SaveAndReimport();
    }

    private static Texture2D GeneratePaperGrain(int size)
    {
        Texture2D texture = new Texture2D(size, size, TextureFormat.RGBA32, false);
        for (int y = 0; y < size; y++)
        {
            for (int x = 0; x < size; x++)
            {
                float uvx = x / (float)(size - 1);
                float uvy = y / (float)(size - 1);
                float fiber = Mathf.PerlinNoise(uvx * 34f, uvy * 7f) * 0.55f + Mathf.PerlinNoise(uvx * 82f + 11f, uvy * 59f) * 0.45f;
                float grain = Mathf.Clamp01(0.42f + fiber * 0.46f + RandomHash(x, y) * 0.12f);
                texture.SetPixel(x, y, new Color(grain, grain, grain, 1f));
            }
        }
        texture.Apply();
        return texture;
    }

    private static Texture2D GenerateDepthGradient(int size)
    {
        Texture2D texture = new Texture2D(size, size, TextureFormat.RGBA32, false);
        for (int y = 0; y < size; y++)
        {
            for (int x = 0; x < size; x++)
            {
                float uvx = x / (float)(size - 1);
                float uvy = y / (float)(size - 1);
                float dx = uvx - 0.52f;
                float dy = uvy - 0.48f;
                float radial = Mathf.Clamp01(Mathf.Sqrt(dx * dx + dy * dy) * 1.35f);
                float value = Mathf.Clamp01(uvy * 0.58f + radial * 0.42f);
                texture.SetPixel(x, y, new Color(value, value, value, 1f));
            }
        }
        texture.Apply();
        return texture;
    }

    private static Texture2D GenerateLilyMask(int size)
    {
        Texture2D texture = new Texture2D(size, size, TextureFormat.RGBA32, false);
        Vector4[] pads =
        {
            new Vector4(0.22f, 0.72f, 0.12f, 0.08f),
            new Vector4(0.44f, 0.64f, 0.15f, 0.1f),
            new Vector4(0.67f, 0.68f, 0.11f, 0.085f),
            new Vector4(0.32f, 0.38f, 0.16f, 0.11f),
            new Vector4(0.62f, 0.35f, 0.13f, 0.095f),
            new Vector4(0.79f, 0.48f, 0.1f, 0.075f)
        };

        for (int y = 0; y < size; y++)
        {
            for (int x = 0; x < size; x++)
            {
                float uvx = x / (float)(size - 1);
                float uvy = y / (float)(size - 1);
                float value = 0f;

                foreach (Vector4 pad in pads)
                {
                    float dx = (uvx - pad.x) / pad.z;
                    float dy = (uvy - pad.y) / pad.w;
                    float ellipse = Mathf.Sqrt(dx * dx + dy * dy);
                    float shape = Smooth01(1.12f, 0.82f, ellipse);
                    float notch = Mathf.Atan2(dy, dx);
                    if (Mathf.Abs(notch - 0.7f) < 0.28f && ellipse < 0.96f)
                    {
                        shape *= 0.25f;
                    }
                    value = Mathf.Max(value, shape);
                }

                texture.SetPixel(x, y, new Color(value, value, value, 1f));
            }
        }
        texture.Apply();
        return texture;
    }

    private static Texture2D GenerateFishAtlas(int size)
    {
        Texture2D texture = new Texture2D(size, size, TextureFormat.RGBA32, false);
        Color clear = new Color(0f, 0f, 0f, 0f);
        for (int y = 0; y < size; y++)
        {
            for (int x = 0; x < size; x++)
            {
                texture.SetPixel(x, y, clear);
            }
        }

        DrawFish(texture, new Vector2(0.34f, 0.5f), 0.0f, new Color(0.96f, 0.46f, 0.22f, 1f), new Color(1f, 0.88f, 0.66f, 1f));
        DrawFish(texture, new Vector2(0.7f, 0.52f), Mathf.PI, new Color(0.94f, 0.78f, 0.38f, 1f), new Color(0.86f, 0.28f, 0.2f, 1f));

        texture.Apply();
        return texture;
    }

    private static void DrawFish(Texture2D texture, Vector2 center, float angle, Color body, Color accent)
    {
        int size = texture.width;
        float cos = Mathf.Cos(angle);
        float sin = Mathf.Sin(angle);

        for (int y = 0; y < size; y++)
        {
            for (int x = 0; x < size; x++)
            {
                Vector2 uv = new Vector2(x / (float)(size - 1), y / (float)(size - 1)) - center;
                Vector2 local = new Vector2(uv.x * cos + uv.y * sin, -uv.x * sin + uv.y * cos);

                float bodyShape = Smooth01(1.0f, 0.78f, Mathf.Sqrt(Mathf.Pow(local.x / 0.12f, 2f) + Mathf.Pow(local.y / 0.045f, 2f)));
                float headShape = Smooth01(1.0f, 0.72f, Mathf.Sqrt(Mathf.Pow((local.x - 0.09f) / 0.052f, 2f) + Mathf.Pow(local.y / 0.038f, 2f)));
                float tailShape = Smooth01(0.06f, 0.0f, DistanceToTriangle(local, new Vector2(-0.12f, 0f), new Vector2(-0.2f, 0.07f), new Vector2(-0.2f, -0.07f)));
                float finA = Smooth01(0.035f, 0.0f, DistanceToTriangle(local, new Vector2(0.0f, 0.02f), new Vector2(-0.05f, 0.095f), new Vector2(0.05f, 0.04f)));
                float finB = Smooth01(0.035f, 0.0f, DistanceToTriangle(local, new Vector2(0.0f, -0.02f), new Vector2(-0.05f, -0.095f), new Vector2(0.05f, -0.04f)));

                float alpha = Mathf.Clamp01(Mathf.Max(Mathf.Max(bodyShape, headShape), Mathf.Max(tailShape, Mathf.Max(finA, finB))));
                if (alpha <= 0.01f)
                {
                    continue;
                }

                float stripe = Mathf.SmoothStep(0.03f, 0.0f, Mathf.Abs(Mathf.Sin((local.x + 0.08f) * 46f) * 0.02f + local.y));
                Color color = Color.Lerp(body, accent, Mathf.Clamp01(stripe * bodyShape + tailShape * 0.8f + finA * 0.45f + finB * 0.45f));
                color.a = alpha;
                texture.SetPixel(x, y, AlphaBlend(texture.GetPixel(x, y), color));
            }
        }
    }

    private static float DistanceToTriangle(Vector2 p, Vector2 a, Vector2 b, Vector2 c)
    {
        float edge0 = SignedEdge(p, a, b);
        float edge1 = SignedEdge(p, b, c);
        float edge2 = SignedEdge(p, c, a);
        bool inside = (edge0 >= 0f && edge1 >= 0f && edge2 >= 0f) || (edge0 <= 0f && edge1 <= 0f && edge2 <= 0f);
        if (inside)
        {
            return 0f;
        }

        return Mathf.Min(DistanceToSegment(p, a, b), Mathf.Min(DistanceToSegment(p, b, c), DistanceToSegment(p, c, a)));
    }

    private static float SignedEdge(Vector2 p, Vector2 a, Vector2 b)
    {
        return (p.x - a.x) * (b.y - a.y) - (p.y - a.y) * (b.x - a.x);
    }

    private static float DistanceToSegment(Vector2 p, Vector2 a, Vector2 b)
    {
        Vector2 ab = b - a;
        float t = Mathf.Clamp01(Vector2.Dot(p - a, ab) / Vector2.Dot(ab, ab));
        return Vector2.Distance(p, a + ab * t);
    }

    private static Color AlphaBlend(Color below, Color above)
    {
        float alpha = above.a + below.a * (1f - above.a);
        if (alpha <= 0.001f)
        {
            return Color.clear;
        }

        Color color = (above * above.a + below * below.a * (1f - above.a)) / alpha;
        color.a = alpha;
        return color;
    }

    private static float RandomHash(int x, int y)
    {
        uint n = (uint)(x * 1973 + y * 9277 + 89173);
        n = (n << 13) ^ n;
        return 1f - ((n * (n * n * 15731u + 789221u) + 1376312589u) & 0x7fffffffu) / 1073741824f;
    }

    private static float Smooth01(float edge0, float edge1, float value)
    {
        float t = Mathf.Clamp01((value - edge0) / (edge1 - edge0));
        return t * t * (3f - 2f * t);
    }
}
