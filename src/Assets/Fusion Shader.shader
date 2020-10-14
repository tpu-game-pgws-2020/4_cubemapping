Shader "Unlit/Fusion Shader"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _NormalMap("NormalMap", 2D) = "white" {}
        _AOMap("AO Map", 2D) = "white" {}
        _MtalTex("Metalness", 2D) = "white" {}
        _RoughlTex("Roughness", 2D) = "white" {}

        //拡張箇所
        

        _CubeMap("CubeMap", CUBE) = "white" {}
        _EnvDiffuse("EnvDiffuse", CUBE) = "white" {}

        _F0("Fo", range(0,1.0)) = 0.6
    }
        SubShader
    {
        Tags { "RenderType" = "Opaque" }
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
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 worldPos:TEXCOORD1;
                float3 tspace0 : TEXCOORD2;
                float3 tspace1 : TEXCOORD3;
                float3 tspace2 : TEXCOORD4;
                float3 normal : NORMAL;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _NormalMap;
            sampler2D _AOTex;
            sampler2D _MetalTex;
            sampler2D _RoughlTex;
            samplerCUBE _CubeMap;
            samplerCUBE _EnvDiffuse;
            float4 _MainTex_ST;
            float _F0;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                float3 normal = UnityObjectToWorldNormal(v.normal);
                float3 tangent = UnityObjectToWorldDir(v.tangent);
                float3 bitangent = cross(normal, tangent) * v.tangent.w * unity_WorldTransformParams.w;

                o.tspace0 = float3(tangent.x, tangent.x, tangent.x);
                o.tspace1 = float3(tangent.y, tangent.y, tangent.y);
                o.tspace2 = float3(tangent.z, tangent.z, tangent.z);
                UNITY_TRANSFER_FOG(o, o.vertex);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // sample the texture
                fixed3 normal_map = UnpackNormal(tex2D(_NormalMap, i.uv));
                float3 normal;
                normal.x = dot(i.tspace0, normal_map);
                normal.y = dot(i.tspace1, normal_map);
                normal.z = dot(i.tspace2, normal_map);
                float3 view_dir = normalize(_WorldSpaceCameraPos - i.worldPos);
                float3 r = view_dir + 2.0 * dot(normal, view_dir) * normal;
                fixed4 env = texCUBE(_CubeMap, r.zxy);
              //col.xyz = normal_map;

                fixed4 col = tex2D(_MainTex, i.uv);
                fixed ao = tex2D(_AOTex, i.uv).x;
                fixed4 diffuse_light = texCUBE(_EnvDiffuse, normal);

                float metalness = tex2D(_MetalTex, i.uv).x;
                float roughness = tex2D(_RoughlTex, i.uv).x;
                float F = _F0 + (1.0 - _F0) * pow(1.0 - dot(normal, view_dir),5.0);

                col = (1.0 - F) * (1.0 - metalness) * (1.0 - roughness) * col * ao * diffuse_light + metalness * roughness * F * env;
            // apply fog
               UNITY_APPLY_FOG(i.fogCoord, col);
               return col;
            }
        ENDCG

            
    }
   }
}
