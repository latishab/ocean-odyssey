#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float3 position [[attribute(0)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

struct TimeUniforms {
    float time;
    float depth;
    float2 swellDirection;
    float swellHeight;
    float swellFrequency;
    float sunAngle;
    float colorBallDepth;
    float pressure;
};

struct BoatUniforms {
    float2 position;
    float2 size;
    float rotation;
};

#endif /* ShaderTypes_h */ 