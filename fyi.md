# Ocean Odyssey: Deep Sea Explorer

## Mission Overview
An interactive deep-sea exploration where students discover how marine life adapts to increasingly extreme conditions as they descend through ocean depths. Through hands-on experiments, they'll understand the key challenges of deep-sea survival: light loss, crushing pressure, and darkness adaptation.

## Mission Structure

### Chapter 1: The Mystery of Light and Color (0-200m)
- **Color Absorption Experiment**
  - Interactive striped ball (red, green, blue) demonstrating color loss
  - Key discovery points:
    - Red light disappears ~15m
    - Green light fades ~30m
    - Blue light diminishes ~45m
  - Learning goal: Understand why deep-sea creatures look different from surface creatures

### Chapter 2: Pressure and Ocean Life (200-1000m)
- **Pressure Visualization**
  - Interactive pressure demonstration
  - Visual representation of crushing forces
  - Connection to marine life adaptations
  - Learning goal: Understand how pressure shapes deep-sea life

### Chapter 3: Deep Sea Adaptations (1000-4000m)
- **Bioluminescence Experiment**
  - Interactive light creation demonstration
  - Examples of bioluminescent creatures
  - Connection to survival strategies
  - Learning goal: Discover how life thrives in extreme conditions

## Technical Implementation Notes

### Visualization System
- Unified depth system (0-4000m)
- Smooth transitions between chapters
- Real-time water effects
- Dynamic lighting changes

### Key Features
1. **Color Ball Experiment**
   - Wave physics at surface
   - Scientifically accurate color absorption
   - Clear depth markers

2. **Pressure Visualization**
   - Visual pressure effects
   - Object deformation demos
   - Marine life examples

3. **Bioluminescence**
   - Interactive light creation
   - Creature demonstrations
   - Dark environment effects

## Educational Design

### Learning Flow
1. Start with familiar concepts (light and color)
2. Build understanding of underwater physics
3. Culminate in discovery of deep-sea adaptations

### Key Concepts
- Color absorption in water
- Pressure effects with depth
- Bioluminescence as adaptation

### Engagement Strategy
- Clear mission goal
- Progressive discovery
- Connected narrative
- Hands-on experiments

## Development Priorities
1. Perfect the color absorption experiment
2. Implement pressure visualization
3. Create bioluminescence system
4. Ensure smooth transitions
5. Polish narrative flow

# Ocean Odyssey - Todo List

## Color Ball Experiment Improvements
1. Fix the ball's initial position to be at the water line when depth is 0m
2. Ensure wave physics only affect the ball when it's at the surface (0m)
3. Adjust color absorption rates to be more scientifically accurate (red ~15m, green ~30m, blue ~45m)
4. Add visual depth markers/scale to show actual depth in meters

## Camera and Scene Improvements
1. Keep the ball centered in view while camera moves down
2. Make water darkening more gradual to maintain visibility
3. Add depth zone indicators (Sunlight Zone, Twilight Zone, etc.)
4. Add more ambient light/visibility in shallow waters

## UI/UX Improvements
1. Update chapter navigation to reflect removal of introduction chapter
2. Fix disabled state of previous/next buttons (currently still checking for .introduction)
3. Add visual feedback when discovering color absorption phenomenon
4. Add educational tooltips/callouts explaining the science

## Content Improvements
1. Expand the Light Penetration experiment to be more interactive
2. Add more scientific facts about color absorption in water
3. Create smoother transition between color experiment and pressure chapter
4. Add visual examples of deep-sea creatures that use red coloration

## Technical Debt
1. Clean up unused code from removed introduction chapter
2. Consolidate depth-related calculations into a single system
3. Improve shader performance for color calculations
4. Add comments explaining key scientific concepts in code

## Bugs to Fix
1. Fix any remaining issues with wave physics at surface
2. Ensure color changes are consistent at all depths
3. Verify camera movement scaling for all depth ranges
4. Check for any memory leaks in shader calculations 