#include "ShaderFunctions.h"

float3 applyPressureDeformation(float3 position, float pressure, float colorBallDepth) {
    // Only apply deformation to vertices near the color ball's depth
    float distanceFromBall = abs(position.y - colorBallDepth);
    float deformationFactor = exp(-distanceFromBall * 3.0); // Make effect more spread out
    
    // Calculate compression based on pressure (more visible effect)
    // At 200m depth, pressure is about 21 atm
    // Make the ball visibly compress vertically and expand horizontally
    float verticalCompression = 1.0 - (pressure - 1.0) * 0.05; // Stronger vertical compression
    verticalCompression = max(verticalCompression, 0.5); // Allow more compression
    
    float horizontalExpansion = 1.0 + (pressure - 1.0) * 0.03; // Expand horizontally as it compresses
    
    // Apply compression only to the ball
    if (distanceFromBall < 0.1) {
        // Compress vertically (y-axis)
        position.y = mix(position.y, 
                        colorBallDepth + (position.y - colorBallDepth) * verticalCompression, 
                        deformationFactor);
        
        // Expand horizontally (x-axis) to maintain volume
        position.x = mix(position.x, 
                        ballPos.x + (position.x - ballPos.x) * horizontalExpansion,
                        deformationFactor);
    }
    
    return position;
}

// NOTE: Gradual color absorption is handled in the fragment shader
float3 calculateColorAtDepth(float3 originalColor, float depth) {
    // Scale depth to 200m range for full sunlight zone
    float scaledDepth = depth * 200.0;  // 200m range
    
    // Even more gradual color absorption rates
    float redLoss = exp(-scaledDepth * 0.02);    // Red disappears ~50m
    float greenLoss = exp(-scaledDepth * 0.01);   // Green persists to ~100m
    float blueLoss = exp(-scaledDepth * 0.005);   // Blue persists to ~150m
    
    return originalColor * float3(redLoss, greenLoss, blueLoss);
}

// NOTE: Colors are fully absorbed by 200m
float3 drawColorBall(float2 uv, float2 ballPos, float3 backgroundColor, float depth, constant TimeUniforms& uniforms) {
    float pressure = uniforms.pressure;
    
    // Calculate compressed ball shape
    float baseRadius = 0.05;
    float verticalRadius = baseRadius * (1.0 - (pressure - 1.0) * 0.05); // Compress vertically
    float horizontalRadius = baseRadius * (1.0 + (pressure - 1.0) * 0.03); // Expand horizontally
    
    // Use elliptical shape for compressed ball
    float2 offset = uv - ballPos;
    float horizontalScale = 1.0 / horizontalRadius;
    float verticalScale = 1.0 / verticalRadius;
    float distanceSquared = (offset.x * offset.x * horizontalScale * horizontalScale) + 
                           (offset.y * offset.y * verticalScale * verticalScale);
    
    if (distanceSquared < 1.0) {
        // Rest of the existing color ball code...
        float3 color;
        float stripe = fract((uv.x - ballPos.x) * 20.0);
        
        if (stripe < 0.33) {
            color = float3(1.0, 0.2, 0.2);
        } else if (stripe < 0.66) {
            color = float3(0.2, 1.0, 0.2);
        } else {
            color = float3(0.2, 0.2, 1.0);
        }
        
        float scaledDepth = depth * 200.0;
        float3 waterColor = float3(0.0, 0.2, 0.8);
        
        float redAbsorption = 1.0 - smoothstep(5.0, 40.0, scaledDepth);
        float greenAbsorption = 1.0 - smoothstep(30.0, 80.0, scaledDepth);
        float blueAbsorption = 1.0 - smoothstep(60.0, 150.0, scaledDepth);
        
        float3 depthAdjustedColor;
        depthAdjustedColor.r = mix(waterColor.r, color.r, redAbsorption);
        depthAdjustedColor.g = mix(waterColor.g, color.g, greenAbsorption);
        depthAdjustedColor.b = mix(waterColor.b, color.b, blueAbsorption);
        
        float lightPenetration = 1.0 - smoothstep(150.0, 200.0, scaledDepth);
        return depthAdjustedColor * mix(0.3, 1.0, lightPenetration);
    }
    return backgroundColor;
}