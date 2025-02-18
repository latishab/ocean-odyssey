import SwiftUI

struct ChapterView: View {
    @StateObject private var chapterManager = ChapterManager()
    @State private var currentChapter: Chapter = .colorAndLight
    @Binding var depth: Float
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    private let oceanViewRepresentable: OceanViewRepresentable
    
    init(depth: Binding<Float>) {
        self._depth = depth
        self.oceanViewRepresentable = OceanViewRepresentable(depth: depth)
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Left panel - Chapter content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Chapter navigation
                        ChapterNavigationView(
                            currentChapter: $currentChapter,
                            onChapterChange: { updateDepthForChapter($0) },
                            chapterManager: chapterManager
                        )
                        
                        // Chapter description
                        Text(currentChapter.description)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.vertical)
                        
                        // Current experiment
                        if let experiment = currentChapter.experiments.first {
                            ExperimentView(
                                experiment: experiment,
                                onValueChanged: { value in
                                    handleExperiment(experiment, value: value)
                                },
                                chapterManager: chapterManager
                            )
                        }
                        
                        // Progress indicators
                        ForEach(Array(chapterManager.discoveries), id: \.self) { discovery in
                            DiscoveryView(message: discovery)
                        }
                    }
                    .padding()
                }
                .frame(width: geometry.size.width * 0.5)
                .background(Color.black.opacity(0.7))
                
                // Right panel - Ocean visualization
                oceanViewRepresentable
                    .frame(width: geometry.size.width * 0.5)
                    .ignoresSafeArea()
            }
        }
        .onReceive(chapterManager.$depth) { newDepth in
            withAnimation(.easeInOut(duration: 0.5)) {
                self.depth = newDepth
            }
        }
    }
    
    private func updateDepthForChapter(_ chapter: Chapter) {
        let targetDepth: Float
        switch chapter {
        case .colorAndLight:
            targetDepth = 0.0  // Start at surface
        case .pressureAndLife:
            if currentChapter == .colorAndLight && depth >= (190.0/200.0) {
                targetDepth = depth  // Keep current depth
            } else {
                targetDepth = 200.0 / 4000.0  // Otherwise start at 200m
            }
        case .deepSeaAdaptations:
            if currentChapter == .pressureAndLife && depth >= (3900.0/4000.0) {
                targetDepth = depth  // Keep current depth
            } else {
                targetDepth = 1000.0 / 4000.0  // Otherwise start at 200m
            }
            targetDepth = 1000.0 / 4000.0  // Start at 1000m
        }
        depth = targetDepth
    }
    
    private func handleExperiment(_ experiment: Experiment, value: Float) {
        switch experiment.interaction {
        case .sunlightZoneDemo(_, _):
            chapterManager.depth = value
            
        case .pressureDemo(_, _):
            chapterManager.depth = value
            if let oceanView = chapterManager.oceanView {
                oceanView.setColorBallDepth(value)
            }
            
        case .pressureCalculation(_, _):
            chapterManager.depth = value
            if let oceanView = chapterManager.oceanView {
                oceanView.setColorBallDepth(value)
            }
            
        case .bioluminescenceDemo(_, _):
            chapterManager.depth = value
        }
        
        chapterManager.handleInteraction(
            element: InteractiveElement(title: experiment.title, type: .slider),
            value: value
        )
    }
}

// Helper Views
struct ChapterNavigationView: View {
    @Binding var currentChapter: Chapter
    // Note: onChapterChange is kept for future use but not called during chapter navigation
    // to prevent double depth updates with setChapter
    let onChapterChange: (Chapter) -> Void
    @ObservedObject var chapterManager: ChapterManager
    
    var body: some View {
        HStack {
            Button(action: {
                withAnimation {
                    if let previous = Chapter(rawValue: currentChapter.rawValue - 1) {
                        currentChapter = previous
                        chapterManager.setChapter(previous)
                    }
                }
            }) {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title)
            }
            .disabled(currentChapter == .colorAndLight)
            .opacity(currentChapter == .colorAndLight ? 0.3 : 1)
            
            Spacer()
            
            Text(currentChapter.title)
                .font(.title)
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    if let next = Chapter(rawValue: currentChapter.rawValue + 1) {
                        currentChapter = next
                        chapterManager.setChapter(next)
                    }
                }
            }) {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title)
            }
            .disabled(currentChapter == .deepSeaAdaptations)
            .opacity(currentChapter == .deepSeaAdaptations ? 0.3 : 1)
        }
        .foregroundColor(.white)
    }
}

struct DiscoveryView: View {
    let message: String
    
    var body: some View {
        HStack {
            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
            Text(message)
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.blue.opacity(0.2))
        .cornerRadius(8)
    }
}
