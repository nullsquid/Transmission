// Copyright 2014-2017 Elringus (Artyom Sovetnikov). All Rights Reserved.

namespace DigitalGlitches
{
    using UnityEngine;
    using UnityEngine.UI;
    
    [RequireComponent(typeof(MaskableGraphic)), AddComponentMenu("UI/Effects/UI Glitch")]
    public class UIGlitch : MonoBehaviour
    {
        [Header("Textures")]
        [Tooltip("The texture to use for glitch pattern.\nIf non specified the default one will be used.\n\nApplied on scene start.")]
        public Texture GlitchTexture;
    
        [Header("Intensity")]
        [Range(.0f, 10f), Tooltip("General intensity of the effect.")]
        public float Intensity = 1.0f;
        [Tooltip("Whether to randomize glitch triggering.")]
        public bool RandomGlitchFrequency = true;
        [Range(.001f, 1f), Tooltip("Frequency of glitches.\n\nIgnored if RandomGlitchFrequency is enabled.")]
        public float GlitchFrequency = .5f;
    
        [Header("UV shifting")]
        [Tooltip("Whether to apply shifting to the UV coordinates of the final image.")]
        public bool PerformUVShifting = true;
        [Range(.001f, 10f), Tooltip("Controls amount of the UV shifting.\n\nHave no effect when PerformUVShifting is disabled.")]
        public float ShiftAmount = 1f;
        [Tooltip("Whether to apply shifting to the whole image.\n\nHave no effect when PerformUVShifting is disabled.")]
        public bool PerformImageShifting = true;
    
        [Header("Colors")]
        [Tooltip("Whether to apply color shifting to the image.")]
        public bool PerformColorShifting = true;
        [Tooltip("Glitches will be tinted with the specified color.\n\nHave no effect when PerformColorShifting is disabled.")]
        public Color TintColor = new Color(.2f, .2f, 0f, 0f);
        [Tooltip("Whether to perform an advanced color blending (color burn and divide) when shifting colors.\n\nHave no effect when PerformColorShifting is disabled.")]
        public bool BurnColors = false;
        [Tooltip("Whether to perform an advanced color blending (color dodge and difference) when shifting colors.\n\nHave no effect when PerformColorShifting is disabled.")]
        public bool DodgeColors = false;
    
        protected Shader Shader
        {
            get
            {
                if (_shader == null) _shader = Resources.Load("CameraGlitch/UIGlitch") as Shader;
                return _shader;
            }
        }
        protected Material Material
        {
            get
            {
                if (_material == null)
                {
                    _material = new Material(Shader);
                    _material.SetTexture("_GlitchTex", GlitchTexture ? GlitchTexture : Resources.Load("CameraGlitch/GlitchTexture") as Texture);
                    _material.SetTextureScale("_GlitchTex", new Vector2(Screen.width / (GlitchTexture ? (float)GlitchTexture.width : 512f),
                        Screen.height / (GlitchTexture ? (float)GlitchTexture.height : 512f)));
                    _material.hideFlags = HideFlags.HideAndDontSave;
                }
                return _material;
            }
        }
    
        private float glitchUp, glitchDown, flicker, glitchUpTime = .05f, glitchDownTime = .05f, flickerTime = .5f;
    
        private Shader _shader;
        private Material _material;
    
        private void OnEnable ()
        {
            _material = null; // force to reinit the material on scene start
    
            if (!Shader || !Shader.isSupported)
                enabled = false;
    
            flickerTime = RandomGlitchFrequency ? Random.value : 1f - GlitchFrequency;
            glitchUpTime = RandomGlitchFrequency ? Random.value : .1f - GlitchFrequency / 10f;
            glitchDownTime = RandomGlitchFrequency ? Random.value : .1f - GlitchFrequency / 10f;
    
            GetComponent<MaskableGraphic>().material = Material;
        }
    
        private void OnDisable ()
        {
            GetComponent<MaskableGraphic>().material = null;
        }
    
        private void Update ()
        {
            Material.SetFloat("_Intensity", Intensity);
            Material.SetColor("_ColorTint", TintColor);
            Material.SetFloat("_BurnColors", BurnColors ? 1 : 0);
            Material.SetFloat("_DodgeColors", DodgeColors ? 1 : 0);
            Material.SetFloat("_PerformUVShifting", PerformUVShifting ? 1 : 0);
            Material.SetFloat("_PerformColorShifting", PerformColorShifting ? 1 : 0);
            Material.SetFloat("_PerformScreenShifting", PerformImageShifting ? 1 : 0);
    
            if (Intensity == 0) Material.SetFloat("filterRadius", 0);
    
            glitchUp += Time.deltaTime * Intensity;
            glitchDown += Time.deltaTime * Intensity;
            flicker += Time.deltaTime * Intensity;
    
            if (flicker > flickerTime)
            {
                Material.SetFloat("filterRadius", Random.Range(-3f, 3f) * Intensity * ShiftAmount);
                Material.SetTextureOffset("_GlitchTex", new Vector2(Random.Range(-3f, 3f), Random.Range(-3f, 3f)));
                flicker = 0;
                flickerTime = RandomGlitchFrequency ? Random.value : 1f - GlitchFrequency;
            }
    
            if (glitchUp > glitchUpTime)
            {
                if (Random.Range(0f, 1f) < .1f * Intensity) Material.SetFloat("flipUp", Random.Range(0f, 1f) * Intensity);
                else Material.SetFloat("flipUp", 0);
    
                glitchUp = 0;
                glitchUpTime = RandomGlitchFrequency ? Random.value / 10f : .1f - GlitchFrequency / 10f;
            }
    
            if (glitchDown > glitchDownTime)
            {
                if (Random.Range(0f, 1f) < .1f * Intensity) Material.SetFloat("flipDown", 1f - Random.Range(0f, 1f) * Intensity);
                else Material.SetFloat("flipDown", 1f);
    
                glitchDown = 0;
                glitchDownTime = RandomGlitchFrequency ? Random.value / 10f : .1f - GlitchFrequency / 10f;
            }
    
            if (Random.Range(0f, 1f) < .1f * Intensity * (RandomGlitchFrequency ? 1 : GlitchFrequency))
                Material.SetFloat("displace", Random.value * Intensity);
            else Material.SetFloat("displace", 0);
        }
    }
    
}
