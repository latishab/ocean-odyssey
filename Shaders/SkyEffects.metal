#include "ShaderFunctions.h"

//------------------------------------------------------------------------------
// Noise Generation Functions
//------------------------------------------------------------------------------
// Basic noise for organic patterns
float noise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    
    float a = length(random2(i));
    float b = length(random2(i + float2(1.0, 0.0)));
    float c = length(random2(i + float2(0.0, 1.0)));
    float d = length(random2(i + float2(1.0, 1.0)));
    
    return mix(mix(a, b, f.x),
              mix(c, d, f.x),
              f.y);
}

// Create natural-looking cloud patterns
float fbm(float2 p, float time) {
    float value = 0.0;
    float amplitude = 0.5;
    float2 shift = float2(time * 0.01, time * 0.02);
    
    for (int i = 0; i < 4; i++) {
        value += amplitude * noise(p);
        p = p * 2.0 + shift;
        amplitude *= 0.5;
    }
    return value;
}

//------------------------------------------------------------------------------
// Cloud Details and Shapes
//------------------------------------------------------------------------------
float cloudDetailNoise(float2 uv, float time) {
    float noise = 0.0;
    
    // Layer multiple frequencies for natural detail
    noise += fbm(uv * 1.0, time) * 0.5;
    noise += fbm(uv * 2.0 + float2(0.5, 0.0), time * 0.8) * 0.25;
    noise += fbm(uv * 4.0 + float2(-0.3, 0.2), time * 0.6) * 0.125;
    
    return noise;
}

// Generate cloud shapes with natural edges
float cloudShape(float2 uv, float2 center, float scale, float time) {
    float2 cloudUV = (uv - center) * scale;
    
    // Create more irregular base shape using noise
    float baseNoise = cloudNoise(cloudUV + float2(time * 0.03, time * 0.01), time);
    float shapeNoise = cloudNoise(cloudUV * 2.0 - float2(time * 0.02, 0.0), time * 0.7);
    
    // Combine noises for irregular shape
    float shape = baseNoise * shapeNoise;
    shape = smoothstep(0.3, 0.7, shape);
    
    // Create softer, more natural edges
    float edge = length(cloudUV);
    float mask = 1.0 - smoothstep(0.2, 0.8, edge);
    
    return shape * mask;
}

float cloudNoise(float2 uv, float time) {
    float noise = 0.0;
    float2 movement = float2(time * 0.01, time * 0.005);
    
    // Layer multiple noise frequencies with different movements
    noise += fbm(uv + movement, time) * 0.5;
    noise += fbm((uv * 2.0 - movement * 1.2), time + 1.0) * 0.25;
    noise += fbm((uv * 4.0 + movement * 0.8), time + 2.0) * 0.125;
    noise += fbm((uv * 8.0 - movement * 0.6), time + 3.0) * 0.0625;
    
    return clamp(noise, 0.0, 1.0);
}

// Creates soft-edged noise for cloud boundaries
float softNoise(float2 uv, float time) {
    float noise = 0.0;
    float size = 1.0;
    float strength = 1.0;
    
    for(int i = 0; i < 3; i++) {
        noise += fbm(uv * size + time * 0.1, time) * strength;
        size *= 2.0;
        strength *= 0.5;
    }
    return noise;
}
