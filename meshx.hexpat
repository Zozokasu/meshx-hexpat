#pragma base_address 0x00
#include <std/string.pat>
#include <std/mem.pat>
#include <std/core.pat>
//SBE = SevenBitEncoded
fn calcSBElen(u128 addr)
{
    u8 i = 1;
    while (std::mem::read_unsigned(addr+i-1,1)&128 > 0)
    {
        i += 1;
    }
    return i;
};

fn calcSBE(u8 len, auto tmp){
    
    u64 result = 0;
    u32 num = 0;
    for (u8 i=0, i<len, i=i+1)
    {
        result |= (tmp[i] & 127 ) << num;
        num = num + 7;
    }
    return result;
};

struct SBE
{
    u128 addr = $;
    u8 len = calcSBElen(addr);
    u8 tmp[len];
    u32 var = calcSBE(len,tmp);
} [[format_read("SBEformat")]];


fn SBEformat(SBE sbe)
{
    u8 l = sbe.len;
    u32 num = 0;
    u64 result = 0;
    for (u8 i=0, i<l, i=i+1)
    {
        result |= (sbe.tmp[i] & 127 )<< num;
        num = num + 7;
    }
    return result;
};

struct ReadString{
    SBE StrLen;
    char Str[StrLen.var];
};

struct EnumStr
{
    u8 EnumStrLen;
    char Enum[EnumStrLen];
};

enum MeshXEncode: u8
{
    Plain,
    LZ4,
    LZMA,
};

bitfield MeshXFlags {
    hasNormals: 1;
    hasTangents: 1;
    hasColors: 1;
    hasBoneBindings: 1;
    Preserved: 28;
    
};


struct float2
{
    float x [[color("FF0000")]];
    float y [[color("00FF00")]];
};

struct float3
{
    float x [[color("FF0000")]];
    float y [[color("00FF00")]];
    float z [[color("0000FF")]];
};

struct float4
{
    float x [[color("FF0000")]];
    float y [[color("00FF00")]];
    float z [[color("0000FF")]];
    float w [[color("FF00FF")]];
};

struct color{
    float r [[color("FF0000")]];
    float g [[color("00FF00")]];
    float b [[color("0000FF")]];
    float a [[color("AAAAAA")]];
}[[color(std::format("{:02X}{:02X}{:02X}", r, g, b))]];

struct BoneBinding{
    SBE boneIndex0;
    SBE boneIndex1;
    SBE boneIndex2;
    SBE boneIndex3;
    float weight0;
    float weight1;
    float weight2;
    float weight3;
    
};

struct SubMesh{
    EnumStr MeshTopology;
    SBE count;
    if(MeshTopology.Enum == "Triangles"){
        s32 indicies[count.var*3];
    }else if(MeshTopology.Enum == "Points"){
        s32 indicies[count.var];
    }
    
    
};

struct float4x4{
    float m00;
    float m01;
    float m02;
    float m03;
    float m10;
    float m11;
    float m12;
    float m13;
    float m20;
    float m21;
    float m22;
    float m23;
    float m30;
    float m31;
    float m32;
    float m33;
};

struct Bone{
    ReadString Name;
    float4x4 bindpose;
    
};

struct BlendShapeData{
    SBE data;
    bool hasNormals = data.var&0b1 > 0;
    bool hasTangents = data.var&0b10 >0;
};
struct BlendShapeFrame{
    float weight;
    float3 positions[parent.parent.vertexes];
    if (parent.data.hasNormals){
    float3 normals[parent.parent.vertexes];
    }
    if(parent.data.hasTangents){
    float3 tangents[parent.parent.vertexes];
    }
    
};
struct BlendShape{
    ReadString Name;
    BlendShapeData data;
    SBE length;
    BlendShapeFrame blendShapeFrames[length.var];
    
};

struct MeshX
{
    char magic[6];
    s32 Version;
    MeshXFlags FLAGS;
    SBE vertexCount;
    u32 vertexes = std::string::parse_int(std::core::formatted_value(vertexCount), 10);
    SBE submeshCount;
    SBE boneCount;
    SBE blendShapeCount;
    SBE UVChannelCount;
    u8 UVDimention[UVChannelCount.tmp[0]];
    EnumStr ColorProfile;
    MeshXEncode meshxEncode;
    if(meshxEncode == 0){
        float3 vertexPositions[vertexes];
        if(FLAGS.hasNormals == 1){
        float3 Normals[vertexes];
        }
        
        if(FLAGS.hasTangents == 1){
        float4 Tangents[vertexes];
        }
        
        if(FLAGS.hasColors == 1){
        color Colors[vertexes];
        }
        
        if(FLAGS.hasBoneBindings == 1){
            BoneBinding boneBindings[vertexes];
        }
        if(UVChannelCount.var>=1){
            match (UVDimention[0]){
                (2): float2 UV[s32(vertexes)];
                (3): float3 UV[s32(vertexes)];
                (4): float4 UV[s32(vertexes)];
            }
        }
        if(UVChannelCount.var>=2){
            match (UVDimention[1]){
                (2): float2 UV[s32(vertexes)];
                (3): float3 UV[s32(vertexes)];
                (4): float4 UV[s32(vertexes)];
            }
        }
        if(UVChannelCount.var>=3){
            match (UVDimention[2]){
                (2): float2 UV[s32(vertexes)];
                (3): float3 UV[s32(vertexes)];
                (4): float4 UV[s32(vertexes)];
            }
        }
        
        SubMesh submeshes[submeshCount.var];
        Bone bones[boneCount.var];
        BlendShape blendShapes[blendShapeCount.var];
    
    }
};

MeshX meshx @0x00;
