import SwiftUI

// MARK: - Chapter Structure
enum Chapter: Int, CaseIterable {
    case colorAndLight = 0    // 0-200m
    case pressureAndLife = 1  // 200-1000m
    case deepSeaAdaptations = 2 // 1000-4000m
    
    var title: String {
        switch self {
        case .colorAndLight:
            return "The Mystery of Light and Color"
        case .pressureAndLife:
            return "Pressure and Ocean Life"
        case .deepSeaAdaptations:
            return "Deep Sea Adaptations"
        }
    }
    
    var description: String {
        switch self {
        case .colorAndLight:
            return """
                Welcome to your deep-sea mission! Your goal is to study how life adapts 
                to the extreme conditions in Earth's deepest oceans.
                
                First, let's understand how light behaves underwater. Try moving the red ball 
                deeper to see how water affects different colors - this will help us understand 
                why deep-sea creatures look so different from surface creatures.
                """
        case .pressureAndLife:
            return """
                The deeper we go, the more intense the pressure becomes. As light fades away, 
                we enter the twilight zone where the real challenges begin.
                
                Look closely at how pressure affects different objects - the adaptations 
                we discover here will be crucial for understanding deep-sea life.
                """
        case .deepSeaAdaptations:
            return """
                In these pitch-black depths, we've found something extraordinary - life 
                thrives here despite the crushing pressure and eternal darkness!
                
                These creatures have evolved remarkable abilities like bioluminescence, 
                turning the dark abyss into a spectacular light show. Let's see how they 
                create their own light to survive in Earth's most extreme environment.
                """
        }
    }
    
    var experiments: [Experiment] {
        switch self {
        case .colorAndLight:
            return [
                Experiment(
                    title: "Color Absorption Experiment",
                    description: """
                        Move deeper to see how water affects colors. In real oceans, 
                        red light disappears by about 15 meters deep, followed by 
                        green at 30 meters and blue at 45 meters.
                        """,
                    interaction: .sunlightZoneDemo(name: "Depth", range: 0...200)
                )
            ]
        case .pressureAndLife:
            return [
                Experiment(
                    title: "Exploring Pressure",
                    description: """
                        Let's understand how water pressure changes as we go deeper.
                        
                        Watch the pressure gauge as we descend. Notice how:
                        - We start with 1 ATM at the surface
                        - Every 10 meters adds 1 more ATM of pressure
                        - At 30m depth, there's 4 ATM of pressure (1 + 3)
                        
                        Move the slider to explore different depths and observe
                        the pressure changes.
                        """,
                    interaction: .pressureDemo(name: "Observe", range: 0...50)
                ),
                Experiment(
                    title: "Calculating Pressure",
                    description: """
                        Now that you understand how pressure increases with depth,
                        let's practice calculating it!
                        
                        Remember the pattern:
                        - Start with 1 ATM (surface pressure)
                        - Add 1 ATM for every 10m of depth
                        
                        Formula: Pressure = (depth ÷ 10) + 1 ATM
                        
                        Example: At 20m depth
                        - Depth ÷ 10 = 20 ÷ 10 = 2
                        - Add 1 ATM = 2 + 1 = 3 ATM total
                        """,
                    interaction: .pressureCalculation(name: "Practice", range: 10...100)
                )
            ]
        case .deepSeaAdaptations:
            return [
                Experiment(
                    title: "Bioluminescence",
                    description: """
                        In the darkness of the deep sea, many creatures make their own light. 
                        This bioluminescence helps them communicate, find food, and survive 
                        in one of Earth's most extreme environments.
                        """,
                    interaction: .bioluminescenceDemo(name: "Creature Light", range: 0...1)
                )
            ]
        }
    }
}

// MARK: - Experiment System
struct Experiment {
    let title: String
    let description: String
    let interaction: Interaction
    var isCompleted: Bool = false
    
    enum Interaction {
        case sunlightZoneDemo(name: String, range: ClosedRange<Float>)
        case pressureDemo(name: String, range: ClosedRange<Float>)
        case pressureCalculation(name: String, range: ClosedRange<Float>)
        case bioluminescenceDemo(name: String, range: ClosedRange<Float>)
    }
}

enum OceanZone: Int, CaseIterable {
    case sunlight = 0      // 0-200m (Epipelagic/Sunlit Zone)
    case twilight = 1      // 200-1000m (Mesopelagic/Twilight Zone)
    case midnight = 2      // 1000-4000m (Bathypelagic/Midnight Zone)
    
    var depthRange: ClosedRange<Float> {
        switch self {
        case .sunlight: return 0...0.2    // 0-200m
        case .twilight: return 0.2...0.6  // 200-1000m
        case .midnight: return 0.6...1.0   // 1000-4000m
        }
    }
    
    var title: String {
        switch self {
        case .sunlight: return "Sunlight Zone"
        case .twilight: return "Twilight Zone"
        case .midnight: return "Midnight Zone"
        }
    }
    
    var description: String {
        switch self {
        case .sunlight:
            return "The sunlit zone (0-200m) is where most marine life thrives. Sunlight penetrates these waters, enabling photosynthesis and supporting diverse ecosystems."
        case .twilight:
            return "The twilight zone (200-1000m) receives minimal sunlight. Many creatures here have developed bioluminescence and unique adaptations to survive."
        case .midnight:
            return "The midnight zone (1000-4000m) exists in permanent darkness. Life here depends on marine snow from above and hydrothermal vents below."
        }
    }
}

struct LearningModule: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let zone: OceanZone
    let interactiveElements: [InteractiveElement]
    let learningObjectives: [String]
    
    var isCompleted: Bool = false
}
