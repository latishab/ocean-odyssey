import SwiftUI

// MARK: - Chapter Structure
enum Chapter: Int, CaseIterable {
    case colorAndLight = 0    // 0-100m
    case pressureAndLife = 1  // 0-200m
    
    var title: String {
        switch self {
        case .colorAndLight:
            return "The Mystery of Light and Color"
        case .pressureAndLife:
            return "Pressure in the Sunlit Zone"
        }
    }
    
    var description: String {
        switch self {
        case .colorAndLight:
            return """
                Welcome to your ocean mission! Your goal is to study how life adapts 
                to changing conditions in the sunlit zone of Earth's oceans.
                
                First, let's understand how light behaves underwater. Try moving the red ball 
                deeper to see how water affects different colors - this will help us understand 
                why marine creatures look so different at various depths.
                """
        case .pressureAndLife:
            return """
                As we descend through the sunlit zone, pressure becomes an increasingly 
                important factor. Every 10 meters of depth adds another atmosphere of pressure!
                
                Look closely at how pressure affects different objects - these observations 
                will help us understand how marine life adapts to increasing pressure.
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
                    interaction: .sunlightZoneDemo(name: "Depth", range: 0...100)
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
                    interaction: .pressureDemo(name: "Observe", range: 0...200)
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
                        
                        Example: At 50m depth
                        - Depth ÷ 10 = 50 ÷ 10 = 5
                        - Add 1 ATM = 5 + 1 = 6 ATM total
                        """,
                    interaction: .pressureCalculation(name: "Practice", range: 0...200)
                )
            ]
        }
    }
}