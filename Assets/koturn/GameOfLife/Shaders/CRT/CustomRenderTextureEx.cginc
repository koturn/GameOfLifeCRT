#ifndef CUSTOM_TEXTURE_EX_INCLUDED
#define CUSTOM_TEXTURE_EX_INCLUDED

#include "UnityCustomRenderTexture.cginc"


float3 CustomRenderTextureComputeCubeDirectionEx(float2 globalTexcoord)
{
    const float2 xy = globalTexcoord * 2.0 - 1.0;
    return normalize(_CustomRenderTextureCubeFace == 0.0 ? float3(1.0, -xy.y, -xy.x)
        : _CustomRenderTextureCubeFace == 1.0 ? float3(-1.0, -xy.y, xy.x)
        : _CustomRenderTextureCubeFace == 2.0 ? float3(xy.x, 1.0, xy.y)
        : _CustomRenderTextureCubeFace == 3.0 ? float3(xy.x, -1.0, -xy.y)
        : _CustomRenderTextureCubeFace == 4.0 ? float3(xy.x, -xy.y, 1.0)
        : float3(-xy.x, -xy.y, -1.0));
}


// standard custom texture vertex shader that should always be used
v2f_customrendertexture CustomRenderTextureVertexShaderEx(appdata_customrendertexture IN)
{
    v2f_customrendertexture OUT;

#if UNITY_UV_STARTS_AT_TOP
    static const float2 vertexPositions[6] =
    {
        { -1.0f,  1.0f },
        { -1.0f, -1.0f },
        {  1.0f, -1.0f },
        {  1.0f,  1.0f },
        { -1.0f,  1.0f },
        {  1.0f, -1.0f }
    };

    static const float2 texCoords[6] =
    {
        { 0.0f, 0.0f },
        { 0.0f, 1.0f },
        { 1.0f, 1.0f },
        { 1.0f, 0.0f },
        { 0.0f, 0.0f },
        { 1.0f, 1.0f }
    };
#else
    static const float2 vertexPositions[6] =
    {
        {  1.0f,  1.0f },
        { -1.0f, -1.0f },
        { -1.0f,  1.0f },
        { -1.0f, -1.0f },
        {  1.0f,  1.0f },
        {  1.0f, -1.0f }
    };

    static const float2 texCoords[6] =
    {
        { 1.0f, 1.0f },
        { 0.0f, 0.0f },
        { 0.0f, 1.0f },
        { 0.0f, 0.0f },
        { 1.0f, 1.0f },
        { 1.0f, 0.0f }
    };
#endif

    const uint primitiveID = IN.vertexID / 6;
    const uint vertexID = IN.vertexID % 6;

    float rotation = radians(CustomRenderTextureSizesAndRotations[primitiveID].w);
#if !UNITY_UV_STARTS_AT_TOP
    rotation = -rotation;
#endif

    float3 updateZoneCenter = CustomRenderTextureCenters[primitiveID].xyz;
    float3 updateZoneSize = CustomRenderTextureSizesAndRotations[primitiveID].xyz;
    // Normalize rect if needed
    if (CustomRenderTextureUpdateSpace > 0.0) // Pixel space
    {
        // Normalize xy because we need it in clip space.
        updateZoneCenter.xy /= _CustomRenderTextureInfo.xy;
        updateZoneSize.xy /= _CustomRenderTextureInfo.xy;
    }
    else // normalized space
    {
        // Un-normalize depth because we need actual slice index for culling
        updateZoneCenter.z *= _CustomRenderTextureInfo.z;
        updateZoneSize.z *= _CustomRenderTextureInfo.z;
    }

    // Compute rotation

    // Compute quad vertex position
    const float2 clipSpaceCenter = updateZoneCenter.xy * 2.0 - 1.0;
    float2 pos = CustomRenderTextureRotate2D(vertexPositions[vertexID] * updateZoneSize.xy, rotation);
#if UNITY_UV_STARTS_AT_TOP
    pos += clipSpaceCenter.xy;
#else
    pos += float2(clipSpaceCenter.x, -clipSpaceCenter.y);
#endif

    // For 3D texture, cull quads outside of the update zone
    // This is neeeded in additional to the preliminary minSlice/maxSlice done on the CPU because update zones can be disjointed.
    // ie: slices [1..5] and [10..15] for two differents zones so we need to cull out slices 0 and [6..9]
    if (CustomRenderTextureIs3D > 0.0)
    {
        const int minSlice = (int)(updateZoneCenter.z - updateZoneSize.z * 0.5);
        const int maxSlice = minSlice + (int)updateZoneSize.z;
        if (_CustomRenderTexture3DSlice < minSlice || _CustomRenderTexture3DSlice >= maxSlice)
        {
            pos = float2(1000.0, 1000.0); // Vertex outside of ncs
        }
    }

    OUT.vertex = float4(pos, 0.0, 1.0);
    OUT.primitiveID = asuint(CustomRenderTexturePrimitiveIDs[primitiveID]);
    OUT.localTexcoord = float3(texCoords[vertexID], CustomRenderTexture3DTexcoordW);
    OUT.globalTexcoord = float3(pos.xy * 0.5 + 0.5, CustomRenderTexture3DTexcoordW);
#if UNITY_UV_STARTS_AT_TOP
    OUT.globalTexcoord.y = 1.0 - OUT.globalTexcoord.y;
#endif
    OUT.direction = CustomRenderTextureComputeCubeDirectionEx(OUT.globalTexcoord.xy);

    return OUT;
}


#endif  // CUSTOM_TEXTURE_EX_INCLUDED
