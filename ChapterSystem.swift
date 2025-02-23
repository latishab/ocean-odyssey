import SwiftUI

// MARK: - Chapter Structure
enum Chapter: Int, CaseIterable {
    case colorAndLight = 0    // 0-100m
    case pressureAndLife = 1  // 0-200m
    case finalQuiz = 2        // Final assessment
    
    var title: String {
        switch self {
        case .colorAndLight:
            return "The Mystery of Light and Color"
        case .pressureAndLife:
            return "Pressure in the Sunlit Zone"
        case .finalQuiz:
            return "Ocean Explorer Assessment"
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
        case .finalQuiz:
            return """
                Congratulations on exploring both light behavior and pressure in the ocean! 
                Now it's time to test your knowledge as an ocean scientist.
                
                This final assessment will challenge your understanding of how these 
                fundamental forces shape life in the sunlit zone. Good luck!
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
        case .finalQuiz:
            return [
                Experiment(
                    title: "Ocean Science Mastery Quiz",
                    description: """
                        Show what you've learned about the ocean's sunlit zone! 
                        
                        This comprehensive quiz will test your understanding of:
                        • How light behaves at different depths
                        • How water pressure changes as we go deeper
                        • How these factors influence marine life
                        
                        Ready to prove yourself as an ocean scientist?
                        """,
                    interaction: .quiz(name: "Final Quiz", questions: quizQuestions)
                )
            ]
        }
    }
}

let quizQuestions = [
    QuizQuestion(
        question: "Which color disappears first as you go deeper?",
        options: ["Blue", "Green", "Red", "Yellow"],
        correctAnswer: 2,  // Red
        explanation: "Red light has the longest wavelength and is absorbed first, disappearing around 15m depth."
    ),
    QuizQuestion(
        question: "At 50 meters deep, what is the water pressure?",
        options: ["3 ATM", "6 ATM", "9 ATM", "12 ATM"],
        correctAnswer: 1,  // 6 ATM
        explanation: "Every 10m adds 1 ATM. At 50m: (50/10) + 1 = 6 ATM"
    ),
    QuizQuestion(
        question: "Why do deep-sea creatures often appear blue or black?",
        options: [
            "They prefer those colors",
            "Only blue light reaches deep water",
            "To hide from predators",
            "Due to high pressure"
        ],
        correctAnswer: 1,
        explanation: "Since blue light penetrates deepest in water, many deep-sea creatures appear blue or black to blend in with their environment."
    ),
    QuizQuestion(
        question: "How much pressure increase do you experience every 10 meters?",
        options: [
            "0.5 ATM",
            "1 ATM",
            "2 ATM",
            "5 ATM"
        ],
        correctAnswer: 1,
        explanation: "For every 10 meters of depth, pressure increases by 1 atmosphere (ATM)."
    ),
    QuizQuestion(
        question: "At what depth does green light typically disappear?",
        options: [
            "15 meters",
            "30 meters",
            "45 meters",
            "60 meters"
        ],
        correctAnswer: 1,
        explanation: "Green light typically disappears around 30 meters deep, after red light but before blue light."
    )
]