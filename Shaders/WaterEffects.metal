#include "ShaderFunctions.h"

// Generate basic wave patterns
float wave(float2 uv, float time, float frequency, float amplitude, float speed) {
    return sin(uv.x * frequency + time * speed) *
           cos(uv.y * frequency * 0.5 + time * speed * 0.7) * (amplitude * 2.0);
}

// Generate ocean swells with directional movement
float swell(float2 position, float2 direction, float frequency, float amplitude, float time, float speed) {
    float2 normalizedDir = normalize(direction);
    float projected = dot(position, normalizedDir);
    
    float wave = sin(projected * frequency + time * speed);
    wave = wave * (1.0 + wave * 0.5);
    wave *= amplitude * 1.5;
    
    float secondary = sin(projected * frequency * 0.7 + time * speed * 0.8) * (amplitude * 0.8);
    float crossSwell = sin(dot(position, float2(-normalizedDir.y, normalizedDir.x)) *
                          frequency * 0.3 + time * speed * 0.5) * (amplitude * 0.6);
    
    return wave + secondary + crossSwell;
}

// Combine waves and swells for realistic water movement
float combinedWaves(float2 position, float time, float2 swellDir, float swellHeight, float swellFreq) {
    float wave1 = wave(position, time, 4.0, 0.08, 2.0);
    float wave2 = wave(position, time, 8.0, 0.05, 3.0);
    float wave3 = wave(position, time, 16.0, 0.03, 4.0);
    
    // Create more natural swell patterns
    float primarySwell = swell(position, swellDir, swellFreq, swellHeight, time, 0.3);
    
    // Add crossing swell with reduced intensity
    float2 crossSwellDir = float2(-swellDir.y, swellDir.x);
    float crossingSwell = swell(position, crossSwellDir, swellFreq * 0.5, swellHeight * 0.4, time, 0.25);
    
    // Adjust weights to emphasize wave heights over swell movement
    return primarySwell * 0.4 + crossingSwell * 0.2 + wave1 * 0.8 + wave2 * 0.5 + wave3 * 0.3;
}

float2 calculateBallPosition(float2 uv, float depth, float waterLine, float time, float2 swellDirection, float swellHeight, float swellFrequency) {
    // Keep ball centered horizontally
    float2 basePos = float2(0.5, 0.0);
    
    // Calculate screen-space position for the ball
    // waterLine moves up as we go deeper (0.5 + depth)
    // ball should be proportionally below the water line based on depth
    float screenSpaceDepth = depth;  // This is already normalized 0-1
    float targetY = waterLine - screenSpaceDepth;  // Position relative to moving water line
    
    // Only add wave motion when very close to surface
    if (depth < 0.001) { 
        float waveOffset = combinedWaves(basePos, time, swellDirection, swellHeight, swellFrequency);
        targetY += waveOffset * 0.1;
    }
    
    basePos.y = targetY;
    return basePos;
}

float mod(float x, float y) {
    return x - y * floor(x/y);
}
