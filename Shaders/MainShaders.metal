#include "ShaderTypes.metal"
#include "ShaderFunctions.h"

// Implementation of random2 (used by all other files)
float2 random2(float2 p) {
    return fract(sin(float2(dot(p,float2(127.1,311.7)),
                           dot(p,float2(269.5,183.3))))*43758.5453);
}

//------------------------------------------------------------------------------
// Shader Entry Points
//------------------------------------------------------------------------------
// Vertex Shader: Processes vertex positions and calculates UV coordinates
vertex VertexOut waterVertexShader(VertexIn in [[stage_in]], constant TimeUniforms& timeUniforms [[buffer(1)]]) {
    VertexOut out;
    
    // Pass through the position
    out.position = float4(in.position.xy, 0.0, 1.0);
    
    // Calculate UV coordinates (will range from 0 to 1)
    out.uv = float2(
        (in.position.x + 1.0) * 0.5,  // Convert from [-1,1] to [0,1]
        (in.position.y + 1.0) * 0.5   // Convert from [-1,1] to [0,1]
    );
    
    return out;
}

// Fragment Shader: Renders water and sky with dynamic effects
fragment float4 waterFragmentShader(VertexOut in [[stage_in]], constant TimeUniforms& timeUniforms [[buffer(1)]]) {
    float2 uv = in.uv;
    float time = timeUniforms.time;
    float depth = timeUniforms.depth;
    
    // Create a wavy boundary line that moves with depth and swell
    float waterLine = 0.5 + depth +
        combinedWaves(uv, time, timeUniforms.swellDirection,
                     timeUniforms.swellHeight, timeUniforms.swellFrequency) * 0.2;
    
    // Calculate base color (sky or water)
    float3 finalColor;
    if (in.uv.y > waterLine) {  // Sky
        float skyGradient = (in.uv.y - waterLine) / (1.0 - waterLine);
        
        // Sky colors
        float3 skyColorTop = float3(0.5, 0.7, 1.0);
        float3 skyColorBottom = float3(0.7, 0.85, 1.0);
        float3 skyColor = mix(skyColorBottom, skyColorTop, skyGradient);
        
        float clouds = 0.0;
        float2 drift = float2(time * 0.01, sin(time * 0.005) * 0.005);
        
        // Calculate cloud height gradient
        float cloudGradient = (in.uv.y - waterLine) / (1.0 - waterLine);
        float cloudMask = smoothstep(0.3, 0.8, cloudGradient);  // Wider, softer transition
        
        // Position clouds in upper sky area with gradual fade
        clouds += cloudShape(uv, float2(0.5, 0.95) + drift, 2.2, time) * 0.9;
        clouds += cloudShape(uv, float2(0.45, 0.92) - drift * 1.1, 1.8, time + 2.5) * 0.8;
        clouds += cloudShape(uv, float2(0.55, 0.93) + drift * 0.8, 1.9, time + 5.0) * 0.85;
        
        // Add subtle variation
        float variation = cloudNoise(uv * 3.0 + drift, time * 0.5) * 0.15;
        clouds += variation;
        
        // Sharper separation between individual clouds
        clouds = smoothstep(0.3, 0.7, clouds);
        clouds = min(clouds, 0.9);
        
        // Apply smooth height-based fade
        clouds *= cloudMask * cloudMask;  // Square it for smoother falloff
        
        // Extra smooth transition at the bottom of clouds
        float fadeBottom = smoothstep(0.3, 0.6, cloudGradient);
        clouds *= fadeBottom;
        
        // Pure white clouds over light blue sky
        float3 cloudColor = float3(1.0, 1.0, 1.0);
        finalColor = mix(skyColor, cloudColor, clouds);
    } else {  // Water
        // Calculate darkness based on depth with transition to pitch black at 200m
        float normalizedDepth = depth * 200.0;  // Convert from 0-1 to 0-200m range
        
        // Create extremely gradual transition to darkness
        float depthDarkness;
        if (normalizedDepth < 40.0) {  // Very gradual darkening until 40m
            depthDarkness = 1.0 - (normalizedDepth / 40.0) * 0.05;  // Super slow initial darkening
        } else if (normalizedDepth < 150.0) {  // Gradual darkening from 40m to 150m
            float midTransition = (normalizedDepth - 40.0) / 110.0;
            depthDarkness = 0.95 - (midTransition * 0.25);  // Start from 95% light, go to 70%
        } else {  // Final transition to black in last 50m (150-200m)
            float transitionRange = (normalizedDepth - 150.0) / 50.0;
            depthDarkness = 0.7 * (1.0 - transitionRange);  // Final fade from 70% to black
        }
        
        float penetration = pow(cos(timeUniforms.sunAngle), 1.5);
        penetration *= depthDarkness;
        
        // Much more ambient light to maintain visibility
        float3 waterColorShallow = float3(0.1, 0.3, 0.5) * (depthDarkness + penetration * 0.8);
        
        // Calculate sun ray direction
        float2 sunDir = float2(sin(timeUniforms.sunAngle), -cos(timeUniforms.sunAngle));
        
        // Calculate caustics effect
        float2 causticUV = uv * 30.0 + sunDir * time * 0.5;
        float caustics = fbm(causticUV, time) * penetration * 0.4;
        
        // Update wave generation to use combined waves
        float combinedWaveEffect = combinedWaves(uv, time, timeUniforms.swellDirection,
                                               timeUniforms.swellHeight, timeUniforms.swellFrequency);
        
        // Use combined waves for water surface displacement
        float finalGradient = combinedWaveEffect;
        finalGradient = clamp(finalGradient, 0.0, 1.0);
        
        // Create sparkles on wave peaks (0.3 intensity for subtle effect)
        float2 sparkleUV = uv * 40.0;
        float sparkle = length(random2(sparkleUV)) * combinedWaveEffect;
        sparkle = pow(sparkle, 5.0) * 0.3;
        
        // Add caustics only near surface
        if (depth < 0.1) { // Only in first 400m
            waterColorShallow += float3(caustics * 0.2 * (1.0 - depth * 10.0)); // Reduced caustics intensity
        }
        
        // Create subtle highlight at water-sky boundary (0.1 intensity)
        float waterLineHighlight = smoothstep(0.0, 0.1, abs(in.uv.y - waterLine)) * 0.1;
        waterColorShallow += float3(waterLineHighlight);
        
        // Apply subtle cloud reflections (30% reduced intensity)
        float2 reflectedUV = float2(uv.x, waterLine - (uv.y - waterLine) * 0.3);
        reflectedUV.x += time * 0.02;  // Drift reflection horizontally
        float reflectedClouds = fbm(reflectedUV * float2(2.0, 1.0), time) * 0.1;
        waterColorShallow += float3(reflectedClouds);
        
        finalColor = waterColorShallow;
    }
    
    // Calculate ball position with wave motion near surface
    float2 ballPos = float2(0.5, 0.5);  // Base position at center
    
    // Add wave motion only when near surface
    if (timeUniforms.depth < 0.05) {
        float waveOffset = combinedWaves(ballPos, time, timeUniforms.swellDirection,
                                       timeUniforms.swellHeight, timeUniforms.swellFrequency);
        float waveInfluence = 1.0 - (timeUniforms.depth / 0.05);
        ballPos.y += waveOffset * 0.1 * waveInfluence;
    }

    // Pass the pressure value to drawColorBall
    finalColor = drawColorBall(uv, ballPos, finalColor, timeUniforms.depth, timeUniforms);
    
    return float4(finalColor, 1.0);
}

// Vertex Shader: Renders boat
vertex VertexOut boatVertexShader(VertexIn in [[stage_in]],
                                 constant BoatUniforms& boat [[buffer(1)]],
                                 constant TimeUniforms& timeUniforms [[buffer(2)]]) {
    VertexOut out;
    
    // Calculate wave height at boat position
    float2 boatUV = boat.position;
    float waveHeight = combinedWaves(boatUV, timeUniforms.time,
                                   timeUniforms.swellDirection,
                                   timeUniforms.swellHeight,
                                   timeUniforms.swellFrequency);
    
    // Calculate rotation based on wave slope
    float2 sampleOffset = float2(0.01, 0.0);
    float waveRight = combinedWaves(boatUV + sampleOffset, timeUniforms.time,
                                  timeUniforms.swellDirection,
                                  timeUniforms.swellHeight,
                                  timeUniforms.swellFrequency);
    float waveLeft = combinedWaves(boatUV - sampleOffset, timeUniforms.time,
                                 timeUniforms.swellDirection,
                                 timeUniforms.swellHeight,
                                 timeUniforms.swellFrequency);
    float slope = (waveRight - waveLeft) / (2.0 * sampleOffset.x);
    float rotation = atan(slope) + boat.rotation;
    
    // Transform vertex position
    float2 rotated = float2(
        in.position.x * cos(rotation) - in.position.y * sin(rotation),
        in.position.x * sin(rotation) + in.position.y * cos(rotation)
    );
    
    float2 scaled = rotated * boat.size;
    float2 positioned = scaled + float2(0.9, boat.position.y);
    
    // Adjust boat height to match water line with a slight upward offset
    float waterLine = 0.5 + timeUniforms.depth +
        waveHeight * 0.2; // Match the water line calculation from water shader
    positioned.y = waterLine + (positioned.y - boat.position.y) + 0.05; // Add 0.02 offset to lift the boat
    
    out.position = float4(positioned * 2.0 - 1.0, 0.0, 1.0);
    
    // Flip the UV coordinates vertically
    out.uv = float2(1.0 - (in.position.x + 1.0) * 0.5,  // Flip X coordinate
                    1.0 - (in.position.y + 1.0) * 0.5);  // Flip Y coordinate
    
    return out;
}

// Fragment Shader: Renders boat
fragment float4 boatFragmentShader(VertexOut in [[stage_in]],
                                 texture2d<float> boatTexture [[texture(0)]]) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    float4 color = boatTexture.sample(textureSampler, in.uv);
    return color;
}