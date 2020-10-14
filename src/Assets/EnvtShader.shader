﻿Shader "Unlit/EnvtShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NormalMap ("NormalMap", 2D) = "white" {}

        _CubeTex("CubeMap", CUBE) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 tangent :TANGENT;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 tspace0 :TEXCOORD2;
                float3 tspace1 :TEXCOORD3;
                float3 tspace2 :TEXCOORD4;

                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            samplerCUBE _CubeTex;
            sampler2D _MainTex;
            sampler2D _NormalMap;

            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                float3 normal=UnityObjectToWorldNormal(v.normal);
                float3 tangent =UnityWorldToObjectDir(v.tangent);
                float3 bitangent = cross(normal,tangent)
                    *v.tangent.w*unity_WorldTransformParams.w;
                o.tspace0=float3(tangent.x,bitangent.x,normal.x);
                o.tspace1=float3(tangent.y,bitangent.y,normal.y);
                o.tspace2=float3(tangent.z,bitangent.z,normal.x);
                o.worldPos=mul(unity_ObjectToWorld,v.vertex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                fixed3 normalMap = UnpackNormal( tex2D(_NormalMap, i.uv));
                float3 normal;
                normal.x=dot(i.tspace0,normalMap);
                normal.y=dot(i.tspace1,normalMap);
                normal.z=dot(i.tspace2,normalMap);

                float3 viwe_dir=normalize(_WorldSpaceCameraPos-i.worldPos);
                float3 r= -viwe_dir+2*dot(normal,viwe_dir)*normal;
                fixed4 env = texCUBE(_CubeTex, r.zxy);
                col=env;
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
