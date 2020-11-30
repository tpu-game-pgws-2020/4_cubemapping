Shader "Unlit/EnvS"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NormalMap("NormalMap", 2D) = "white" {}
        _CubeMap ("CubeMap", CUBE) = "white" {}
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
                float3 normal : NORMAL;
                float4 tan : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 tspace0 : TEXCOORD2;
                float3 tspace1 : TEXCOORD3;
                float3 tspace2 : TEXCOORD4;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _NormalMap;
            samplerCUBE _CubeMap;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);

                float3 normal = UnityObjectToWorldNormal(v.normal);
                float3 tan = UnityObjectToWorldDir(v.tan);
                float3 bitan = cross(normal, tan) * v.tan.w * unity_WorldTransformParams.w;
                
                o.tspace0 = float3(tan.x, bitan.x, normal.x);
                o.tspace1 = float3(tan.y, bitan.y, normal.y);
                o.tspace2 = float3(tan.z, bitan.z, normal.z);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                fixed3 map = UnpackNormal(tex2D(_NormalMap, i.uv));
                float3 normal;
                normal.x = dot(i.tspace0, map);
                normal.y = dot(i.tspace1, map);
                normal.z = dot(i.tspace2, map);

                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                float3 ref = -viewDir + 2.0 * dot(normal, viewDir) * normal;
                fixed4 cube = texCUBE(_CubeMap, ref.zxy);
                col = cube;
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
