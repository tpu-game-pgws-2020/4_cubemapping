Shader "Unlit/NewUnlitShader 3"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        AOTex("AOTex", 2D) = "white" {}
        _NormaleMap ("normal", 2D) = "white" {}
        CubeMap ("CubeMap", CUBE) = "white" {}
        Evedeffece ("Evedeffece", CUBE) = "white" {}
        metalTex("metalTex", 2D) = "white" {}
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
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
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
            sampler2D AOTex;
            sampler2D metalTex;
            samplerCUBE Evedeffece;
            sampler2D _NormaleMap;
            samplerCUBE CubeMap;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                float3 normal=UnityObjectToWorldNormal(v.normal);
                float3 tangent=UnityObjectToWorldDir(v.tangent);
                float3 bitangent=cross(normal,tangent)*v.tangent.w*unity_WorldTransformParams.w;
                o.worldPos=mul(unity_ObjectToWorld,v.vertex);
                o.tspace0=float3(tangent.x,bitangent.x,normal.x);
                o.tspace1=float3(tangent.y,bitangent.y,normal.y);
                o.tspace2=float3(tangent.z,bitangent.z,normal.z);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                
                fixed3 normal_map =UnpackNormal (tex2D(_NormaleMap, i.uv));

                float3 normal;
                normal.x=dot(i.tspace0,normal_map);
                 normal.y=dot(i.tspace1,normal_map);
                  normal.z=dot(i.tspace2,normal_map);
                float3 view_dir=normalize(_WorldSpaceCameraPos-i.worldPos);
                float3 r=-view_dir+2.0*normal*dot(normal,view_dir);
                fixed4 env = texCUBE(CubeMap,r.zxy);
            
                 float4 metal=tex2D(metalTex, i.uv).x;
                fixed4 col = tex2D(_MainTex, i.uv);
                fixed ao = tex2D(AOTex, i.uv.x);
                 fixed4 diffuse=texCUBE(Evedeffece,normal);
                // apply fog
                const float F0=0.8;
                float F=F0+(1.0-F0)*pow((1.0-dot(normal,view_dir)),5.0);
                col=(1.0-F)*(1-metal)*col*ao*diffuse+metal*F*env;
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
