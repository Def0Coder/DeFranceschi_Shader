Shader "DeFranceschi/Crystal"
{
    Properties
    {
        
        _MainTex("Texture", 2D) = "white" {}
        _ColorTint("Color Tint", Color) = (1,1,1,1)
        _RimColor("Rim Color", Color) = (1,1,1,1)
        _RimPower("Rim Power", Range(0.2, 10)) = 3.0
        _RefractionStrength("Refraction Strength", Range(0.0, 1.0)) = 0.5
        _NormalMap("Normal Map", 2D) = "bump" {}
    }
    SubShader
    {
     
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent" }
        LOD 100

        
        GrabPass { "_GrabTexture" }

        Pass
        {
            
            CGPROGRAM
           
            #pragma vertex vert
            #pragma fragment frag

         
            #include "UnityCG.cginc"

            // Dichiaro le texture e delle proprietà del materiale
            sampler2D _MainTex;
            sampler2D _NormalMap;
            sampler2D _GrabTexture;
            float4 _ColorTint;
            float4 _RimColor;
            float _RimPower;
            float _RefractionStrength;

            
            struct AppData
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float4 tangent : TANGENT;
            };

            // Struttura di output del vertice per il frammento shader
            struct VertexToFragment
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldNormal : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
                float4 screenPos : TEXCOORD3;
                float3 worldTangent : TEXCOORD4;
                float3 worldBinormal : TEXCOORD5;
            };

            // Funzione del vertice shader
            VertexToFragment vert(AppData v)
            {
                VertexToFragment o;
               
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;

            
                o.worldNormal = normalize(mul((float3x3)unity_WorldToObject, v.normal));

               
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.viewDir = normalize(_WorldSpaceCameraPos - worldPos);

                
                o.screenPos = ComputeScreenPos(o.vertex);

                
                o.worldTangent = normalize(mul((float3x3)unity_ObjectToWorld, v.tangent.xyz));
                o.worldBinormal = cross(o.worldNormal, o.worldTangent) * v.tangent.w;

                return o;
            }

        
            fixed4 frag(VertexToFragment i) : SV_Target
            {
                // Carica il colore della texture principale
                fixed4 baseColor = tex2D(_MainTex, i.uv);
                baseColor *= _ColorTint;

                
                float rimFactor = 1.0 - saturate(dot(normalize(i.viewDir), i.worldNormal));
                fixed4 rimColor = _RimColor * pow(rimFactor, _RimPower);
                baseColor.rgb += rimColor.rgb;

                // Calcola la matrice TBN (Tangente, Binormale, Normale)
                float3 worldNormal = normalize(i.worldNormal);
                float3 worldTangent = normalize(i.worldTangent);
                float3 worldBinormal = normalize(i.worldBinormal);
                float3x3 TBN = float3x3(worldTangent, worldBinormal, worldNormal);

      
                float3 normalMap = tex2D(_NormalMap, i.uv).rgb * 2.0 - 1.0;
                float3 normal = normalize(mul(normalMap, TBN));

               
                float2 refractionOffset = normal.xy * _RefractionStrength;
                float4 refractedColor = tex2Dproj(_GrabTexture, i.screenPos + float4(refractionOffset, 0, 0));

                
                baseColor.rgb = lerp(baseColor.rgb, refractedColor.rgb, _RefractionStrength);

                return baseColor;
            }
            
            ENDCG
        }
    }
    
    FallBack "Transparent/Diffuse"
}
