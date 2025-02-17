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
    
    // Track all discoveries per chapter
    private var colorDiscoveries: Set<String> = []
    private var pressureDiscoveries: Set<String> = []
    private var bioluminescenceDiscoveries: Set<String> = []
    
    // Track achievements
    @Published var hasCompletedColorExperiment = false
    @Published var hasCompletedPressureExperiment = false
    @Published var hasDesignedCreature = false
    
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
        default:
            break
        }
    }
    
    func setChapter(_ chapter: Chapter) {
        let previousChapter = currentChapter
        currentChapter = chapter
        
        // Maintain depth when transitioning from color to pressure chapter
        if previousChapter == .colorAndLight && chapter == .pressureAndLife && depth >= (190.0/200.0) {
            // Keep current depth
        } else {
            // Set default depths for other transitions
            switch chapter {
            case .colorAndLight:
                depth = 0.0
            case .pressureAndLife:
                depth = 200.0 / 4000.0
            case .deepSeaAdaptations:
                depth = 1000.0 / 4000.0
            }
        }
        
        // Update discoveries
        switch chapter {
        case .colorAndLight:
            discoveries = colorDiscoveries
        case .pressureAndLife:
            discoveries = pressureDiscoveries
        case .deepSeaAdaptations:
            discoveries = bioluminescenceDiscoveries
        }
    }
    
    /// Handles the color ball experiment interaction
    /// - Parameters:
    ///   - element: The interactive element type
    ///   - value: Normalized depth value (0-1) where 1.0 = 200m for this experiment
    /// - Note: Value is already normalized from ExperimentView, do not normalize again
    private func handleColorBallInteraction(element: InteractiveElement, value: Float) {
        depth = value  // Direct use of normalized value
        delegate?.didUpdateColorBallDepth(value)
        
        // Convert normalized value to actual meters for discovery triggers
        let depthInMeters = value * 200  // Scale to 200m range
        
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
        case .deepSeaAdaptations:
            handleBioluminescenceExperiment(value)
        }
    }
    
    private func handlePressureExperiment(_ value: Float) {
        // Instead of using slider value, we'll update depth when pressure calculations are correct
        // The depth will be set by a new function that's called when pressure is calculated correctly
    }
    
    /// Sets the depth for pressure experiment
    /// - Parameter depthInMeters: Actual depth in meters (200-1000m range)
    /// - Note: This method handles normalization to 0-1 range internally
    func setPressureExperimentDepth(_ depthInMeters: Float) {
        depth = depthInMeters / 4000.0  // Normalize to 0-1 range
        
        if depthInMeters > 300 && !pressureDiscoveries.contains("Pressure300") {
            pressureDiscoveries.insert("At 300m, pressure is 30 times greater than at surface")
            discoveries = pressureDiscoveries
        }
        if depthInMeters > 500 && !pressureDiscoveries.contains("Pressure500") {
            pressureDiscoveries.insert("Most fish have swim bladders that would collapse at 500m")
            discoveries = pressureDiscoveries
        }
        if depthInMeters > 800 && !pressureDiscoveries.contains("Pressure800") {
            pressureDiscoveries.insert("At 800m, pressure reaches 80 atmospheres, requiring special adaptations")
            discoveries = pressureDiscoveries
        }
        
        // Mark pressure experiment as completed when reaching maximum depth
        if depthInMeters > 950 && !hasCompletedPressureExperiment {
            hasCompletedPressureExperiment = true
            discoveries.insert("Completed pressure zone exploration!")
        }
    }
    
    /// Handles the bioluminescence experiment
    /// - Parameter value: Raw slider value (0-1) for 1000-4000m range
    private func handleBioluminescenceExperiment(_ value: Float) {
        let depthInMeters = 1000 + (value * 3000)  // Convert to 1000-4000m range
        depth = depthInMeters / 4000.0  // Normalize to 0-1 range
        
        if depthInMeters > 1200 && !bioluminescenceDiscoveries.contains("Biolum1200") {
            bioluminescenceDiscoveries.insert("90% of deep-sea marine life can produce bioluminescence")
            discoveries = bioluminescenceDiscoveries
        }
        if depthInMeters > 2000 && !bioluminescenceDiscoveries.contains("Biolum2000") {
            bioluminescenceDiscoveries.insert("Discovered anglerfish using bioluminescent lure to attract prey")
            discoveries = bioluminescenceDiscoveries
        }
        if depthInMeters > 3000 && !bioluminescenceDiscoveries.contains("Biolum3000") {
            bioluminescenceDiscoveries.insert("Found colonies of flashlight fish using synchronized bioluminescence")
            discoveries = bioluminescenceDiscoveries
        }
        if depthInMeters > 3800 && !bioluminescenceDiscoveries.contains("Biolum3800") {
            bioluminescenceDiscoveries.insert("Observed deep-sea creatures using bioluminescence for communication")
            discoveries = bioluminescenceDiscoveries
        }
        
        // Mark creature design milestone when reaching maximum depth
        if depthInMeters > 3900 && !hasDesignedCreature {
            hasDesignedCreature = true
            discoveries.insert("Ready to design your own deep-sea creature!")
        }
    }
    
    // MARK: - Progress Tracking
    func recordDiscovery(_ discovery: String) {
        discoveries.insert(discovery)
        updateMissionProgress()
    }
    
    private func updateMissionProgress() {
        let totalMilestones = 4.0
        var completedMilestones = 0.0
        
        if !discoveries.isEmpty { completedMilestones += 1 }
        if hasCompletedColorExperiment { completedMilestones += 1 }
        if hasCompletedPressureExperiment { completedMilestones += 1 }
        if hasDesignedCreature { completedMilestones += 1 }
        
        missionProgress = Float(completedMilestones / totalMilestones)
    }
}
