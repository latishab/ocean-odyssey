#ifndef ShaderFunctions_h
#define ShaderFunctions_h

#include "ShaderTypes.metal"

// Random and noise functions
float2 random2(float2 p);
float noise(float2 p);
float fbm(float2 p, float time);

// Water effects
float wave(float2 uv, float time, float frequency, float amplitude, float speed);
float swell(float2 position, float2 direction, float frequency, float amplitude, float time, float speed);
float combinedWaves(float2 position, float time, float2 swellDir, float swellHeight, float swellFreq);
float2 calculateBallPosition(float2 uv, float depth, float waterLine, float time, float2 swellDirection, float swellHeight, float swellFrequency);

// Sky effects
float cloudNoise(float2 uv, float time);
float cloudShape(float2 uv, float2 center, float scale, float time);
float cloudDetailNoise(float2 uv, float time);
float softNoise(float2 uv, float time);

// Color ball effects
float3 applyPressureDeformation(float3 position, float2 ballPos, float pressure, float colorBallDepth);
float3 calculateColorAtDepth(float3 originalColor, float depth);
float3 drawColorBall(float2 uv, float2 ballPos, float3 backgroundColor, float depth, constant TimeUniforms& uniforms);

#endif /* ShaderFunctions_h */ 