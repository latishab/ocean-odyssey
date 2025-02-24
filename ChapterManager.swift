import SwiftUI

protocol ChapterManagerDelegate: AnyObject {
    func didUpdateColorBallDepth(_ depth: Float)
}

/// Manages the state and interactions for ocean depth experiments
/// Depth values are normalized (0-1) throughout the system where:
/// - 0.0 represents surface level
/// - 1.0 represents maximum depth (4000m)
@MainActor
class ChapterManager: ObservableObject {
    @Published var currentChapter: Chapter = .colorAndLight
    @Published var completedModules: Set<UUID> = []
    @Published var missionProgress: Float = 0.0
    @Published var discoveries: Set<String> = []  // Current chapter's discoveries
    @Published var depth: Float = 0.0
    @Published var currentPressureDepth: Float = 0.0 
    
    // Track all discoveries per chapter
    private var colorDiscoveries: Set<String> = []
    private var pressureDiscoveries: Set<String> = []
    
    // Track achievements
    @Published var hasCompletedColorExperiment = false
    @Published var hasCompletedPressureExperiment = false
    
    // Add quiz discoveries tracking
    private var quizDiscoveries: Set<String> = []
    @Published var hasCompletedQuiz = false
    
    weak var delegate: ChapterManagerDelegate?
    weak var oceanView: OceanView?
    
    init() {
        currentChapter = .colorAndLight
    }
    
    func handleInteraction(element: InteractiveElement, value: Float) {
        switch element.type {
        case .slider:
            handleSliderInteraction(element: element, value: value)
        case .colorBallDemo:
            handleColorBallInteraction(element: element, value: value)
        case .quiz:
            handleQuizInteraction(element: element, value: value)
        default:
            break
        }
    }
    
    func setChapter(_ chapter: Chapter) {
        let previousChapter = currentChapter
        currentChapter = chapter
        
        // NOTE: - Reset depths when changing chapters
        depth = 0.0
        currentPressureDepth = 0.0
        
        // Update discoveries
        switch chapter {
        case .colorAndLight:
            discoveries = colorDiscoveries
        case .pressureAndLife:
            discoveries = pressureDiscoveries
        case .finalQuiz:
            discoveries = quizDiscoveries
        }
    }
    
    /// Handles the color ball experiment interaction
    /// - Parameters:
    ///   - element: The interactive element type
    ///   - value: Normalized depth value (0-1) where 1.0 = 100m for this experiment
    private func handleColorBallInteraction(element: InteractiveElement, value: Float) {
        depth = value  // Direct use of normalized value
        delegate?.didUpdateColorBallDepth(value)
        
        // Convert normalized value to actual meters for discovery triggers
        let depthInMeters = value * 100  // Scale to 100m range
        
        // Record discoveries at specific depths
        if depthInMeters > 15 && !colorDiscoveries.contains("Red Light") {
            colorDiscoveries.insert("Red light disappears around 15 meters deep")
            discoveries = colorDiscoveries
        }
        if depthInMeters > 30 && !colorDiscoveries.contains("Green Light") {
            colorDiscoveries.insert("Green light starts to fade around 30 meters deep")
            discoveries = colorDiscoveries
        }
        if depthInMeters > 45 && !colorDiscoveries.contains("Blue Light") {
            colorDiscoveries.insert("Blue light begins to diminish around 45 meters deep")
            discoveries = colorDiscoveries
        }
    }
    
    private func handleSliderInteraction(element: InteractiveElement, value: Float) {
        switch currentChapter {
        case .colorAndLight:
            handleColorBallInteraction(element: element, value: value)
        case .pressureAndLife:
            handlePressureExperiment(value)
        case .finalQuiz:
            break  
        }
    }
    
    private func handlePressureExperiment(_ value: Float) {
        let actualDepth = value * 200
        currentPressureDepth = actualDepth  
        depth = value
    }
    
    /// Sets the depth for pressure experiment
    /// - Parameter depthInMeters: Actual depth in meters (0-200m range)
    func setPressureExperimentDepth(_ depthInMeters: Float) {
        depth = depthInMeters / 200.0  // Normalize to 0-1 range
        
        if depthInMeters > 50 && !pressureDiscoveries.contains("Pressure50") {
            pressureDiscoveries.insert("At 50m, pressure is 6 times greater than at surface")
            discoveries = pressureDiscoveries
        }
        if depthInMeters > 100 && !pressureDiscoveries.contains("Pressure100") {
            pressureDiscoveries.insert("At 100m, pressure reaches 11 atmospheres")
            discoveries = pressureDiscoveries
        }
        if depthInMeters > 150 && !pressureDiscoveries.contains("Pressure150") {
            pressureDiscoveries.insert("Most recreational diving stops at 130m due to intense pressure")
            discoveries = pressureDiscoveries
        }
        
        // Mark pressure experiment as completed when reaching maximum depth
        if depthInMeters > 190 && !hasCompletedPressureExperiment {
            hasCompletedPressureExperiment = true
            discoveries.insert("Completed pressure zone exploration!")
        }
    }
    
    // MARK: - Progress Tracking
    func recordDiscovery(_ discovery: String) {
        discoveries.insert(discovery)
        updateMissionProgress()
    }
    
    private func updateMissionProgress() {
        let totalMilestones = 3.0  // Updated to include quiz
        var completedMilestones = 0.0
        
        if !discoveries.isEmpty { completedMilestones += 1 }
        if hasCompletedColorExperiment { completedMilestones += 0.5 }
        if hasCompletedPressureExperiment { completedMilestones += 0.5 }
        if hasCompletedQuiz { completedMilestones += 1 }
        
        missionProgress = Float(completedMilestones / totalMilestones)
    }
    
    private func handleQuizInteraction(element: InteractiveElement, value: Float) {
        let percentage = value
        let achievement = if percentage >= 0.8 {
            "🏆 Ocean Science Master: Excellent understanding of ocean phenomena!"
        } else if percentage >= 0.6 {
            "🌊 Ocean Explorer: Good grasp of ocean science fundamentals"
        } else {
            "🔍 Ocean Apprentice: Keep exploring to deepen your understanding"
        }
        
        quizDiscoveries.insert(achievement)
        discoveries = quizDiscoveries
        hasCompletedQuiz = true
        
        updateMissionProgress()
    }
}

struct InteractiveElement {
    let title: String
    let type: InteractionType
    
    enum InteractionType {
        case slider
        case colorBallDemo
        case quiz
    }
}
