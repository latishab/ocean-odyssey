#include "ShaderFunctions.h"

// Deform ball shape based on water pressure
float3 applyPressureDeformation(float3 position, float2 ballPos, float pressure, float colorBallDepth) {
    float distanceFromBall = abs(position.y - colorBallDepth);
    float deformationFactor = 1.0;
    float verticalCompression = max(1.0 - (pressure - 1.0) * 0.15, 0.3);
    float horizontalExpansion = 1.0 + (pressure - 1.0) * 0.1;
    
    if (distanceFromBall < 0.1) {
        position.y = mix(position.y,
                        colorBallDepth + (position.y - colorBallDepth) * verticalCompression,
                        deformationFactor);
        position.x = mix(position.x,
                        ballPos.x + (position.x - ballPos.x) * horizontalExpansion,
                        deformationFactor);
    }
    return position;
}

// Calculate color absorption at different depths
float3 calculateColorAtDepth(float3 originalColor, float depth) {
    float scaledDepth = depth * 200.0;
    return originalColor * float3(
        exp(-scaledDepth * 0.02),  // Red: ~50m
        exp(-scaledDepth * 0.01),  // Green: ~100m
        exp(-scaledDepth * 0.005)  // Blue: ~150m
    );
}

// Draw the color ball with pressure deformation and color absorption
float3 drawColorBall(float2 uv, float2 ballPos, float3 backgroundColor, float depth,
                    constant TimeUniforms& uniforms) {
    float pressure = uniforms.pressure;
    float baseRadius = 0.05;
    
    // Calculate compression that increases with pressure
    float compressionFactor = pressure - 1.0;  // Will be 0 at surface (pressure = 1)
    
    // At surface: a = b = baseRadius
    float a = baseRadius * (1.0 + compressionFactor * 0.2);
    float b = baseRadius / (1.0 + compressionFactor * 4.0);
    
    // Calculate offset from ball center
    float2 offset = uv - ballPos;
    
    // MARK: - Calculate the pinch effect
    float yFactor = abs(offset.y/b);  // 0 at middle, 1 at top/bottom
    float pinchAmount = compressionFactor * 0.8;
    float xScale = 1.0 - pinchAmount * (1.0 - pow(yFactor, 2.0));
    xScale = max(xScale, 0.2);
    float2 normalizedOffset = float2(
        offset.x / (a * xScale),  // X gets pinched inward at middle
        offset.y / b              // Y just gets compressed
    );

    float horizontalExp = 2.0;
    float verticalExp = 2.0;
    float horizontalTerm = pow(abs(normalizedOffset.x), horizontalExp);
    float verticalTerm = pow(abs(normalizedOffset.y), verticalExp);
    
    float finalShape = horizontalTerm + verticalTerm;
    
    if (finalShape <= 1.0) {
        float stripeWidth = 20.0;
        float stripe = fract((uv.x - ballPos.x) * stripeWidth);
        
        float3 color;
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
