#ifndef INCLUDE_SNOW_GROUND_HLSL
#define INCLUDE_SNOW_GROUND_HLSL

#include "FbmNoise.hlsl"

struct SnowData {
    float fp;
    float3 normalWS; 
    float3 noise;
    float3 albedo;
    float smoothness;
    half3 emission;
    half occlusion;
};

float3 _SnowDirection;
float _NoisePositionScale;
float _SnowAmount;
float4 _SnowDotNormalRemap;
float _NoiseInclinationScale;   //倾斜贡献值
float _NormalNoiseScale; //雪噪声扰动法线强度

float _SnowNoiseFadeStart;
float _SnowNoiseFadeEnd;
half3 _SnowColor;
half _SnowSmoothness;
half3 _SnowSpecularColor;
half3 _SnowEmission;
half _SnowHeightStart;
half _SnowHeightEnd;

//将值从 range.xy 范围映射到 range.zw 中
float remap(float value, float4 range)
{
    return (value - range.x) * (range.w - range.z) / (range.y - range.x) + range.z;
}

void InitializeSnowData(float3 origColor,half origSmoothness,half origOcclusion, float3 positionWS,float3 bumpMapedNormalWS, float3 vertexNormalWS,  out SnowData snowData) {

    float3 snowDir = normalize(_SnowDirection); 
     
    
    half3 viewVector =  _WorldSpaceCameraPos.xyz-positionWS;
    half dist = length(viewVector);
    half distLerpT = saturate((dist - _SnowNoiseFadeStart) / (_SnowNoiseFadeEnd - _SnowNoiseFadeStart));
    half heightLerpT = saturate((positionWS.y - _SnowHeightStart) / (_SnowHeightEnd - _SnowHeightStart));
    half3 viewDir = normalize(viewVector);
    
    half3 noise = fbm(positionWS.xyz * _NoisePositionScale);   

    snowData.noise = noise;
    
    float nDotS = dot(vertexNormalWS, snowDir); // 噪声对法线方向进行扰动 
    nDotS = remap(nDotS, _SnowDotNormalRemap);
    float finc = nDotS + _NoiseInclinationScale * length(lerp(noise,0,distLerpT));
    snowData.fp = saturate(lerp(0, _SnowAmount * finc,heightLerpT));
    
    snowData.albedo = lerp(origColor,_SnowColor,snowData.fp);
    
    snowData.smoothness = lerp(origSmoothness,_SnowSmoothness,snowData.fp);
    
    // 用于雪照明计算的法线 
    noise = half3(noise.x,0,noise.z);    
    snowData.normalWS = normalize(vertexNormalWS + lerp( (noise * 2.0 - 1.0 ) * _NormalNoiseScale , 0, distLerpT)); 
    snowData.normalWS = lerp(bumpMapedNormalWS,snowData.normalWS,snowData.fp);
    snowData.occlusion = lerp(origOcclusion,1,snowData.fp);
    snowData.emission = _SnowEmission * snowData.fp;
}

half3 ApplySnowEmission(half3 origColor ,SnowData snowData){
    return origColor += snowData.emission;
}



#endif


