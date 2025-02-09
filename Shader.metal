#include <metal_stdlib>
using namespace metal;

//------------------------------------------------------------------------------
// Data Structures
//------------------------------------------------------------------------------
struct VertexIn {
    float3 position [[attribute(0)]];
};

struct VertexOut {
    float4 position [[position]];  // Clip-space position
    float2 uv;                    // UV coordinates for easier position calculation
};

struct TimeUniforms {
    float time;                   // Time for wave animation
    float depth;                  // Depth for water animation
    float2 swellDirection;        // Direction of the primary swell
    float swellHeight;           // Height of the swell waves
    float swellFrequency;        // Frequency of the swell pattern
    float sunAngle;               // Sun angle for lighting
    float colorBallDepth;
};

struct BoatUniforms {
    float2 position;
    float2 size;
    float rotation;
};

//------------------------------------------------------------------------------
// Utility Functions
//------------------------------------------------------------------------------
// Generates a random 2D vector based on input coordinates
float2 random2(float2 p) {
    return fract(sin(float2(dot(p,float2(127.1,311.7)),
                           dot(p,float2(269.5,183.3))))*43758.5453);
}

// Generates a single wave based on parameters
float wave(float2 uv, float time, float frequency, float amplitude, float speed) {
    // Increase base amplitude for more height variation
    return sin(uv.x * frequency + time * speed) *
           cos(uv.y * frequency * 0.5 + time * speed * 0.7) * (amplitude * 2.0); // Doubled amplitude
}

// Update swell function for more dramatic waves
float swell(float2 position, float2 direction, float frequency, float amplitude, float time, float speed) {
    float2 normalizedDir = normalize(direction);
    float projected = dot(position, normalizedDir);
    
    // Create more dramatic primary swell wave
    float wave = sin(projected * frequency + time * speed);
    // Increase wave asymmetry for steeper faces
    wave = wave * (1.0 + wave * 0.5);  // Increased from 0.3 to 0.5
    wave *= amplitude * 1.5;  // Amplify the overall wave height
    
    // Add stronger secondary swell components
    float secondary = sin(projected * frequency * 0.7 + time * speed * 0.8) * (amplitude * 0.8);  // Increased from 0.4 to 0.8
    
    // Add stronger cross-swell variation
    float crossSwell = sin(dot(position, float2(-normalizedDir.y, normalizedDir.x)) * frequency * 0.3 +
                          time * speed * 0.5) * (amplitude * 0.6);  // Increased from 0.3 to 0.6
    
    return wave + secondary + crossSwell;
}

// Update combinedWaves function for better wave heights
float combinedWaves(float2 position, float time, float2 swellDir, float swellHeight, float swellFreq) {
    // Increase wave heights but keep frequencies more natural
    float wave1 = wave(position, time, 4.0, 0.08, 2.0);     // Larger waves with more height
    float wave2 = wave(position, time, 8.0, 0.05, 3.0);     // Medium waves with more height
    float wave3 = wave(position, time, 16.0, 0.03, 4.0);    // Small waves with more height
    
    // Create more natural swell patterns
    float primarySwell = swell(position, swellDir, swellFreq, swellHeight, time, 0.3);
    
    // Add crossing swell with reduced intensity
    float2 crossSwellDir = float2(-swellDir.y, swellDir.x);
    float crossingSwell = swell(position, crossSwellDir, swellFreq * 0.5, swellHeight * 0.4, time, 0.25);
    
    // Adjust weights to emphasize wave heights over swell movement
    return primarySwell * 0.4 + crossingSwell * 0.2 + wave1 * 0.8 + wave2 * 0.5 + wave3 * 0.3;
}

// Add this helper function at the top with other utility functions
float2 calculateBallPosition(float2 uv, float depth, float waterLine, float time, float2 swellDirection, float swellHeight, float swellFrequency) {
    // Keep ball at a fixed screen position (center)
    float2 basePos = float2(0.5, 0.5);  // Center of screen
    
    // Apply wave effect at surface (when depth is 0)
    if (depth <= 0.001) {  // Changed from 0.01 to 0.001 for more precise surface detection
        // Start at water line and add wave motion
        basePos.y = waterLine;  // Set initial position to water line
        float waveOffset = combinedWaves(basePos, time, swellDirection, swellHeight, swellFrequency);
        basePos.y += waveOffset * 0.1;  // Add wave motion
    }
    
    return basePos;
}

// Add this at the top with other utility functions
float mod(float x, float y) {
    return x - y * floor(x/y);
}

//------------------------------------------------------------------------------
// Noise Generation Functions
//------------------------------------------------------------------------------
// Basic noise function for creating organic patterns
float noise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    
    // Smoothstep for softer clouds
    f = f * f * (3.0 - 2.0 * f);
    
    float a = length(random2(i));
    float b = length(random2(i + float2(1.0, 0.0)));
    float c = length(random2(i + float2(0.0, 1.0)));
    float d = length(random2(i + float2(1.0, 1.0)));
    
    return mix(mix(a, b, f.x),
              mix(c, d, f.x),
              f.y);
}

// Fractal Brownian Motion - creates natural-looking noise patterns
float fbm(float2 p, float time) {
    float value = 0.0;
    float amplitude = 0.5;
    float2 shift = float2(time * 0.01, time * 0.02);
    
    // Add multiple layers of noise for cloud-like patterns
    for (int i = 0; i < 4; i++) {
        value += amplitude * noise(p);
        p = p * 2.0 + shift;
        amplitude *= 0.5;
    }
    return value;
}

//------------------------------------------------------------------------------
// Cloud Generation Functions
//------------------------------------------------------------------------------
// Multi-layered noise for realistic cloud patterns
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

// Generates detailed cloud patterns with multiple layers
float cloudDetailNoise(float2 uv, float time) {
    float noise = 0.0;
    
    // Layer multiple frequencies for natural detail
    noise += fbm(uv * 1.0, time) * 0.5;
    noise += fbm(uv * 2.0 + float2(0.5, 0.0), time * 0.8) * 0.25;
    noise += fbm(uv * 4.0 + float2(-0.3, 0.2), time * 0.6) * 0.125;
    
    return noise;
}

// Creates complete cloud shapes with natural edges and variation
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

// First, make the color absorption much more gradual
float3 calculateColorAtDepth(float3 originalColor, float depth) {
    // Scale depth to 200m range for full sunlight zone
    float scaledDepth = depth * 200.0;  // 200m range
    
    // Even more gradual color absorption rates
    float redLoss = exp(-scaledDepth * 0.02);    // Red disappears ~50m
    float greenLoss = exp(-scaledDepth * 0.01);   // Green persists to ~100m
    float blueLoss = exp(-scaledDepth * 0.005);   // Blue persists to ~150m
    
    return originalColor * float3(redLoss, greenLoss, blueLoss);
}

// Add this function to draw a dashed line
float drawDashedLine(float2 uv, float2 linePos, float dashLength, float gapLength) {
    float distanceToLine = abs(uv.x - linePos.x);
    float dashPattern = mod(uv.y, dashLength + gapLength);
    return step(distanceToLine, 0.005) * step(dashPattern, dashLength);
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
        float3 finalColor = mix(skyColor, cloudColor, clouds);
        
        // MARK: - Color Ball Demo
        float2 ballPos = calculateBallPosition(uv, timeUniforms.colorBallDepth, waterLine,
                                             time, timeUniforms.swellDirection,
                                             timeUniforms.swellHeight, timeUniforms.swellFrequency);
        
        // First draw the ball
        if (length(uv - ballPos) < 0.05) {
            // Create a striped ball with red, green, and blue
            float3 color;
            float stripe = fract((uv.x - ballPos.x) * 20.0);  // Create vertical stripes
            
            if (stripe < 0.33) {
                color = float3(1.0, 0.2, 0.2);  // Red stripe
            } else if (stripe < 0.66) {
                color = float3(0.2, 1.0, 0.2);  // Green stripe
            } else {
                color = float3(0.2, 0.2, 1.0);  // Blue stripe
            }
            
            float3 depthAdjustedColor = calculateColorAtDepth(color, timeUniforms.colorBallDepth);
            finalColor = mix(depthAdjustedColor, finalColor, timeUniforms.colorBallDepth * 0.7);
        }
        
        // Then draw the dashed line
        float dashedLine = drawDashedLine(uv, ballPos, 0.02, 0.02);  // Dash and gap length
        float3 lineColor = float3(1.0, 1.0, 1.0);  // White line
        finalColor = mix(finalColor, lineColor, dashedLine * 0.5);  // Reduced line intensity
        
        return float4(finalColor, 1.0);
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
        float3 waterColorDeep = float3(0.0, 0.05, 0.2) * (depthDarkness + 0.95);  // Even more ambient
        
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
        
        // MARK: - Color Ball Demo
        float2 ballPos = calculateBallPosition(uv, timeUniforms.colorBallDepth, waterLine,
                                             time, timeUniforms.swellDirection,
                                             timeUniforms.swellHeight, timeUniforms.swellFrequency);
        
        // First draw the ball
        float3 finalColor = waterColorShallow;  // or skyColor depending on section
        if (length(uv - ballPos) < 0.05) {
            // Create a striped ball with red, green, and blue
            float3 color;
            float stripe = fract((uv.x - ballPos.x) * 20.0);  // Create vertical stripes
            
            if (stripe < 0.33) {
                color = float3(1.0, 0.2, 0.2);  // Red stripe
            } else if (stripe < 0.66) {
                color = float3(0.2, 1.0, 0.2);  // Green stripe
            } else {
                color = float3(0.2, 0.2, 1.0);  // Blue stripe
            }
            
            float3 depthAdjustedColor = calculateColorAtDepth(color, timeUniforms.colorBallDepth);
            finalColor = mix(depthAdjustedColor, finalColor, timeUniforms.colorBallDepth * 0.7);
        }
        
        // Then draw the dashed line
        float dashedLine = drawDashedLine(uv, ballPos, 0.02, 0.02);  // Dash and gap length
        float3 lineColor = float3(1.0, 1.0, 1.0);  // White line
        finalColor = mix(finalColor, lineColor, dashedLine * 0.5);  // Reduced line intensity
        
        return float4(finalColor, 1.0);
    }
}

// Add new vertex shader for the boat
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
    float2 positioned = scaled + boat.position;
    
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

// Add new fragment shader for the boat
fragment float4 boatFragmentShader(VertexOut in [[stage_in]],
                                 texture2d<float> boatTexture [[texture(0)]]) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    float4 color = boatTexture.sample(textureSampler, in.uv);
    return color;
}
