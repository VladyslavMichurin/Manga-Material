Shader "_MyShaders/Manga Shader"
{
    Properties
    {
        
        _HighlightColor ("Highlight Color", Color) = (1, 1, 1, 1)
        _HighlightPercent ("Highlight Persent", range(0, 1)) = 0.1

        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)

        _ShadowColor ("Shadow Color", Color) = (0, 0, 0, 1)
        _ShadowTex ("Shadow Texture", 2D) = "white" {}
        _ShadowPercent ("Shadow Persent", range(0, 1)) = 0.1

        _ShadowTexAngleAgj ("Shadow Texture Angle Adjustment", range(0, 360)) = 0

        [NoScaleOffset] _NormalMap ("Normals", 2D) = "bump" {}

        _OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
        _OutlineThickness ("Outline Thickness", Range(0, 10)) = 1
        _OutlineNoiseTex ("Outline Noise Texture", 2D) = "white" {}
        _OutlineNoiseAmmount ("Outline Noise Ammount", Range(0, 1)) = 1
    }
    SubShader
    {
        Tags 
        { 
            "RenderType"="Opaque"
        }

        Pass
        {
            Name "Base Color"

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityPBSLighting.cginc"

            // FullShadowsRotation FullClampedShadowsRotation SimplifiedClampedShadows

            #define FullClampedShadowsRotation;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;

                float3 normal : NORMAL;
                float4 tangent : TEXCOORD2;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 uv : TEXCOORD0;

                float3 normal : TEXCOORD1;
                float4 tangent : TEXCOORD2;

            };

            float4 _BaseColor, _ShadowColor, _HighlightColor;

            float _ShadowPercent, _HighlightPercent;

            float _ShadowTexAngleAgj;

            sampler2D _NormalMap, _ShadowTex;
            float4 _NormalMap_ST, _ShadowTex_ST;

            v2f vert (appdata v)
            {
                v2f o;

                o.uv.xy = v.uv;
                o.uv.zw = TRANSFORM_TEX(v.uv, _ShadowTex);
                o.vertex = UnityObjectToClipPos(v.vertex);

                o.normal = UnityObjectToWorldNormal(v.normal);
                o.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);

                return o;
            }

            float3 CreateBinormal(float3 _normal, float3 _tangent, float _binormalSign)
            {
                return cross(_normal, _tangent) * _binormalSign * unity_WorldTransformParams.w;
            }

            void InitializeFragmentNormal(inout v2f i)
            {
                float3 normalMap = UnpackScaleNormal(tex2D(_NormalMap, i.uv.xy), 1);
                float binormal = CreateBinormal(i.normal, i.tangent, i.tangent.w);

                i.normal = normalize(
                    normalMap.x * i.tangent +
                    normalMap.y * binormal +
                    normalMap.z * i.normal
                    );
            }

            float2 RotateUV(float2 _uv, float _angle_deg)
            {
                float degToRad = _angle_deg * UNITY_PI / 180;

                float2 toReturn = _uv;
                toReturn -= 0.5;

                float s = sin(degToRad);
                float c = cos(degToRad);

                float2x2 rotMatrix = float2x2(c,-s,
                                              s,c);
                
                toReturn = float2(mul(rotMatrix, toReturn));
                toReturn += 0.5;

                return toReturn;
            }
            float ManageAngle(float _angle, bool _isNegative)
            {
                float toReturn = 0;

                float absAngle = abs(_angle);
                float negative = _isNegative ? -1 : 1;

                #if defined(FullShadowsRotation)

                    toReturn = _angle;

                #elif defined(FullClampedShadowsRotation)

                    if(absAngle <= 22.5)
                    {
                        toReturn = 0;
                    }
                    else if(absAngle >= 22.5 && absAngle < 90)
                    {
                        toReturn = 45 * negative;
                    }
                    else if(absAngle >= 90 && absAngle < 157.5)
                    {
                        toReturn = 135 * negative;
                    }
                    else
                    {
                        toReturn = 180 * negative;
                    }

                #elif defined(SimplifiedClampedShadows)

                    toReturn = 45 * negative;

                #else
                
                    if(absAngle <= 22.5)
                    {
                        toReturn = 0;
                    }
                    else if(absAngle >= 22.5 && absAngle < 180)
                    {
                        toReturn = 45 * negative;
                    }

                #endif

                return toReturn;

            }
            float4 ManageShadowColor(v2f i)
            {
                float angleRad = atan2(_WorldSpaceLightPos0.x, _WorldSpaceLightPos0.y);

                float angle = angleRad * 180/UNITY_PI;

                if(angle >= 0)
                {
                    angle = ManageAngle(angle, false);
                }

                else
                {
                    angle = ManageAngle(angle, true);
                }

                return tex2D(_ShadowTex, RotateUV(i.uv.zw, angle + _ShadowTexAngleAgj)) * _ShadowColor;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                InitializeFragmentNormal(i);
                
                float NdotL = dot(i.normal, _WorldSpaceLightPos0);
                float remapedNdotL = (NdotL + 1) / 2;

                float shadowAmmount = smoothstep(0, _ShadowPercent / 2, remapedNdotL);
                float shadowIntensity = smoothstep(0.999, 1, shadowAmmount);
                float4 litColor = lerp(ManageShadowColor(i), _BaseColor, shadowIntensity);

                float highlightAmmount = smoothstep(1 - _HighlightPercent, 1, NdotL);
                float highlightIntensity = smoothstep(0, 0.001, highlightAmmount);
                float4 finalColor = lerp(litColor, _HighlightColor, highlightIntensity);

                return finalColor;
            }
            ENDCG
        }

        Pass
        {
            Name "Outline"

            ZWrite Off
            Cull Front
            

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

             #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;

                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;

                float3 normal : TEXCOORD1;
            };

            sampler2D _OutlineNoiseTex;
            float4 _OutlineNoiseTex_ST, _OutlineColor;
            float _OutlineThickness, _OutlineNoiseAmmount, _test;


            v2f vert (appdata v)
            {
                v2f o;

                o.uv =  TRANSFORM_TEX(v.uv, _OutlineNoiseTex);
                o.normal = UnityObjectToWorldNormal(v.normal);

                float3 noiseTex = tex2Dlod(_OutlineNoiseTex, float4(o.uv, 0,0));
                float3 modifiedNormals = v.normal + v.normal * noiseTex;

                float3 modifiedVertex = v.vertex + v.normal * _OutlineThickness / 10;
                float3 modifiedVertex2 = v.vertex + modifiedNormals * _OutlineThickness / 10;

                float3 finalVert = lerp(modifiedVertex, modifiedVertex2, _OutlineNoiseAmmount);

                o.vertex = UnityObjectToClipPos(finalVert);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return _OutlineColor;
            }
            ENDCG
        }
    }
}
