
Shader "UI/Glitch"
{
    Properties
    {
        [PerRendererData] _MainTex("Sprite Texture", 2D) = "white" {}
        _Color("Tint", Color) = (1,1,1,1)
        _StencilComp("Stencil Comparison", Float) = 8
        _Stencil("Stencil ID", Float) = 0
        _StencilOp("Stencil Operation", Float) = 0
        _StencilWriteMask("Stencil Write Mask", Float) = 255
        _StencilReadMask("Stencil Read Mask", Float) = 255
        _ColorMask("Color Mask", Float) = 15
        [Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip("Use Alpha Clip", Float) = 0

        _GlitchTex("Glitch Texture", 2D) = "white" {}
        _Intensity("Glitch Intensity", Range(0.5, 2)) = 1.0
        _ColorTint("Color Tint", Color) = (0.2, 0.2, 0.0, 0.0)
        _BurnColors("Burn Colors", Range(0, 1)) = 1
        _DodgeColors("Dodge Colors", Range(0, 1)) = 0
        _PerformUVShifting("Perform UV Shifting", Range(0, 1)) = 1
        _PerformColorShifting("Perform Color Shifting", Range(0, 1)) = 1
        _PerformScreenShifting("Perform Screen Shifting", Range(0, 1)) = 1
    }

    SubShader
    {
        Tags
        {
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
            "RenderType" = "Transparent"
            "PreviewType" = "Plane"
            "CanUseSpriteAtlas" = "True"
        }

        Stencil
        {
            Ref[_Stencil]
            Comp[_StencilComp]
            Pass[_StencilOp]
            ReadMask[_StencilReadMask]
            WriteMask[_StencilWriteMask]
        }

        Cull Off
        Lighting Off
        ZWrite Off
        ZTest[unity_GUIZTestMode]
        Blend SrcAlpha OneMinusSrcAlpha
        ColorMask[_ColorMask]

        Pass
        {
            Name "Default"

            CGPROGRAM

            #include "UnityCG.cginc"
            #include "UnityUI.cginc"

            #pragma vertex ComputeVertex
            #pragma fragment ComputeFragment
            #pragma target 3.0
            #pragma multi_compile __ UNITY_UI_ALPHACLIP

            sampler2D _MainTex;
            fixed4 _Color;
            fixed4 _TextureSampleAdd;
            float4 _ClipRect;

            sampler2D _GlitchTex;
            half4 _GlitchTex_ST;
            float _Intensity;
            fixed4 _ColorTint;
            fixed _BurnColors;
            fixed _DodgeColors;
            fixed _PerformUVShifting;
            fixed _PerformColorShifting;
            fixed _PerformScreenShifting;
            float filterRadius;
            float flipUp, flipDown;
            float displace;

            struct appdata_t
            {
                float4 vertex : POSITION;
                float4 color : COLOR;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                fixed4 color : COLOR;
                float2 texcoord : TEXCOORD0;
                float4 worldPosition : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            fixed4 ColorBurn(fixed4 a, fixed4 b)
            {
                fixed4 r = 1.0 - (1.0 - a) / b;
                r.a = a.a;
                return r;
            }

            fixed4 Divide(fixed4 a, fixed4 b)
            {
                fixed4 r = a / b;
                r.a = a.a;
                return r;
            }

            fixed4 Subtract(fixed4 a, fixed4 b)
            {
                fixed4 r = a - b;
                r.a = a.a;
                return r;
            }

            fixed4 Difference(fixed4 a, fixed4 b)
            {
                fixed4 r = abs(a - b);
                r.a = a.a;
                return r;
            }

            v2f ComputeVertex (appdata_t IN)
            {
                v2f OUT;
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                OUT.worldPosition = IN.vertex;
                OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);

                OUT.texcoord = IN.texcoord;

                OUT.color = IN.color * _Color;
                return OUT;
            }

            fixed4 ComputeFragment (v2f IN) : SV_Target
            {
                half4 mainColor = (tex2D(_MainTex, IN.texcoord) + _TextureSampleAdd) * IN.color;
                mainColor.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
                #ifdef UNITY_UI_ALPHACLIP
                clip(mainColor.a - 0.001);
                #endif

                fixed4 glitchColor = tex2D(_GlitchTex, IN.texcoord.xy * _GlitchTex_ST.xy + _GlitchTex_ST.zw);

                float sinTime = abs(sin(_Time.y * _Intensity));
                float cosTime = abs(cos(_Time.z * _Intensity));

                if ((IN.texcoord.y < sinTime + filterRadius / 10.0 && IN.texcoord.y > sinTime - filterRadius / 10.0) ||
                    (IN.texcoord.y < cosTime + filterRadius / 10.0 && IN.texcoord.y > cosTime - filterRadius / 10.0))
                {
                    if (IN.texcoord.y < flipUp)
                        IN.texcoord.y = 1.0 - (IN.texcoord.y + flipUp);

                    if (IN.texcoord.y > flipDown)
                        IN.texcoord.y = 1.0 - (IN.texcoord.y - flipDown);

                    IN.texcoord.xy += displace * _Intensity;
                }

                fixed4 shiftedSample = tex2D(_MainTex, lerp(IN.texcoord.xy, IN.texcoord.xy + 0.01 * filterRadius * _Intensity, _PerformScreenShifting)) * IN.color;
                mainColor = lerp(mainColor, shiftedSample, _PerformUVShifting);

                mainColor = lerp(mainColor, mainColor * (1.0 + _ColorTint), _PerformColorShifting);
                fixed4 burnedGlitch = lerp(ColorBurn(mainColor, glitchColor), Divide(mainColor, glitchColor), floor(abs(filterRadius)));
                fixed4 finalGlitch = lerp(mainColor * glitchColor, burnedGlitch, _BurnColors);
                fixed4 dodgedGlitch = lerp(Subtract(finalGlitch, glitchColor), Difference(finalGlitch, glitchColor), floor(abs(filterRadius)));
                finalGlitch = lerp(finalGlitch, dodgedGlitch, _DodgeColors);
                mainColor = lerp(mainColor, finalGlitch, _PerformColorShifting);

                return mainColor;
            }

            ENDCG
        }
    }
}
