import SwiftUI

struct ExperimentView: View {
    let experiment: Experiment
    let onValueChanged: (Float) -> Void
    @ObservedObject var chapterManager: ChapterManager
    
    @State private var sliderValue: Float = 0
    @State private var depthText: String = "0.0m"
    @State private var selectedFormula: PressureFormula = .basic
    @State private var pressureAnswer: String = ""
    @State private var feedbackMessage: String = ""
    @State private var isCorrect: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Title with mission-style formatting
            HStack {
                Image(systemName: "circle.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 8))
                Text(experiment.title)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Text(experiment.description)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
            
            // Interactive elements based on experiment type
            switch experiment.interaction {
            case .sunlightZoneDemo(let name, _):
                // Color absorption experiment (0-200m)
                VStack {
                    HStack {
                        Text(name)
                            .foregroundColor(.white)
                        Slider(value: $sliderValue, in: 0...1)
                            .onChange(of: sliderValue) { newValue in
                                // IMPORTANT: We normalize the depth here (0-1)
                                // This normalized value flows through the entire system
                                // Do not normalize again in ChapterManager
                                let actualDepth = newValue * 200  // For display only
                                print("ExperimentView: Depth \(actualDepth)m (normalized: \(newValue))")
                                depthText = String(format: "%.1fm", actualDepth)
                                onValueChanged(newValue)  // Pass normalized value
                            }
                        Text(depthText)
                            .foregroundColor(.white)
                            .frame(width: 60, alignment: .trailing)
                    }
                }
                
            case .pressureDemo(let name, _):
                // Pressure experiment (200-1000m)
                VStack(spacing: 15) {
                    // Current depth display
                    HStack {
                        Text("Depth:")
                            .foregroundColor(.white)
                        Text(depthText)
                            .foregroundColor(.white)
                            .frame(width: 60, alignment: .trailing)
                    }
                    
                    // Pressure calculation quiz
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Calculate the pressure at this depth:")
                            .foregroundColor(.white)
                        
                        HStack {
                            // Auto-complete keyboard options
                            Picker("Calculation", selection: $selectedFormula) {
                                Text("Depth ÷ 10 + 1").tag(PressureFormula.basic)
                                Text("(Depth × 0.1) + 1").tag(PressureFormula.decimal)
                                Text("Depth/10 + 1 ATM").tag(PressureFormula.atmospheric)
                            }
                            .pickerStyle(.menu)
                            .foregroundColor(.white)
                            
                            TextField("Enter pressure", text: $pressureAnswer)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                            
                            Text("ATM")
                                .foregroundColor(.white)
                            
                            Button("Check") {
                                checkPressureCalculation()
                            }
                            .buttonStyle(.bordered)
                            .tint(.blue)
                        }
                    }
                    
                    // Feedback message
                    if !feedbackMessage.isEmpty {
                        Text(feedbackMessage)
                            .foregroundColor(isCorrect ? .green : .orange)
                            .font(.callout)
                    }
                }
                .padding()
                
            case .bioluminescenceDemo(let name, _):
                // Bioluminescence experiment (1000-4000m)
                VStack {
                    HStack {
                        Text(name)
                            .foregroundColor(.white)
                        Slider(value: $sliderValue, in: 0...1)
                            .onChange(of: sliderValue) { newValue in
                                let actualDepth = 1000 + (newValue * 3000) // 1000-4000m range
                                depthText = String(format: "%.0fm", actualDepth)
                                onValueChanged(newValue)
                            }
                        Text(depthText)
                            .foregroundColor(.white)
                            .frame(width: 60, alignment: .trailing)
                    }
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func checkPressureCalculation() {
        guard let depth = Float(depthText.replacingOccurrences(of: "m", with: "")),
              let answer = Float(pressureAnswer) else {
            feedbackMessage = "Please enter a valid number"
            return
        }
        
        let correctPressure = (depth / 10) + 1
        let isClose = abs(correctPressure - answer) < 0.1
        
        if isClose {
            isCorrect = true
            feedbackMessage = "Correct! At \(Int(depth))m, the pressure is \(String(format: "%.1f", correctPressure)) atmospheres."
        } else {
            isCorrect = false
            feedbackMessage = "Try again! Hint: Every 10 meters adds 1 atmosphere of pressure."
        }
    }
}

enum PressureFormula {
    case basic      // "Depth ÷ 10 + 1"
    case decimal    // "(Depth × 0.1) + 1"
    case atmospheric // "Depth/10 + 1 ATM"
}
