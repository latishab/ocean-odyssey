import SwiftUI
import ObjectiveC

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
    @FocusState private var isTextFieldFocused: Bool
    @State private var cursorPosition: Int = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
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
                                    depthText = String(format: "%.1fm", actualDepth)
                                    onValueChanged(newValue)  // Pass normalized value
                                }
                            Text(depthText)
                                .foregroundColor(.white)
                                .frame(width: 60, alignment: .trailing)
                        }
                    }
                    
                case .pressureDemo(let name, let range):
                    // Learning experiment - just show the pressure change
                    VStack(spacing: 15) {
                        // Pressure gauge visualization
                        PressureGaugeView(
                            depth: Float(depthText.replacingOccurrences(of: "m", with: "")) ?? 0,
                            maxDepth: range.upperBound
                        )
                        
                        // Depth control
                        HStack {
                            Text(name)
                                .foregroundColor(.white)
                            Slider(value: $sliderValue, in: 0...1)
                                .onChange(of: sliderValue) { newValue in
                                    let actualDepth = range.lowerBound + (newValue * (range.upperBound - range.lowerBound))
                                    depthText = String(format: "%.0fm", actualDepth)
                                    onValueChanged(newValue)
                                }
                            Text(depthText)
                                .foregroundColor(.white)
                                .frame(width: 60, alignment: .trailing)
                        }
                    }
                    .padding()
                    
                case .pressureCalculation(let name, let range):
                    // The existing pressure calculation quiz code
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Calculate the pressure at this depth:")
                            .foregroundColor(.white)
                        
                        HStack {
                            TextField("Enter pressure", text: $pressureAnswer)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 200)
                                .focused($isTextFieldFocused)
                                .toolbar {
                                    ToolbarItemGroup(placement: .keyboard) {
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 12) {
                                                ForEach(["depth/10 + 1", "depth × 0.1 + 1", "(depth + 10)/10"], id: \.self) { formula in
                                                    Button(action: {
                                                        if let depth = Float(depthText.replacingOccurrences(of: "m", with: "")),
                                                           let result = evaluateFormula(formula, depth: depth) {
                                                            pressureAnswer = String(format: "%.1f", result)
                                                        }
                                                    }) {
                                                        Text(formula)
                                                            .font(.system(.body, design: .monospaced))
                                                            .foregroundColor(.white)
                                                            .padding(.horizontal, 12)
                                                            .padding(.vertical, 8)
                                                            .background(Color(white: 0.2))
                                                            .cornerRadius(8)
                                                    }
                                                }
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Button("Done") {
                                            isTextFieldFocused = false
                                        }
                                    }
                                }
                            
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
        }
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
    
    private func evaluateFormula(_ formula: String, depth: Float) -> Float? {
        // Replace the text formula with actual calculation
        switch formula {
        case "depth/10 + 1":
            return depth/10 + 1
        case "depth × 0.1 + 1":
            return depth * 0.1 + 1
        case "(depth + 10)/10":
            return (depth + 10)/10
        default:
            return nil
        }
    }
}

// MARK: - Formula Buttons
struct FormulaButton: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(8)
                .foregroundColor(.white)
        }
    }
}

enum PressureFormula {
    case basic      // "Depth ÷ 10 + 1"
    case decimal    // "(Depth × 0.1) + 1"
    case atmospheric // "Depth/10 + 1 ATM"
}

// MARK: - Keyboard Toolbar
struct KeyboardToolbar: UIViewRepresentable {
    let suggestions: [String]
    let onSelect: (String) -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let toolbar = UIInputView(frame: .init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44), inputViewStyle: .keyboard)
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        suggestions.forEach { suggestion in
            let button = UIButton(type: .system)
            button.setTitle(suggestion, for: .normal)
            button.titleLabel?.font = .monospacedSystemFont(ofSize: 15, weight: .regular)
            button.backgroundColor = UIColor(white: 0.2, alpha: 1)
            button.layer.cornerRadius = 6
            button.setTitleColor(.white, for: .normal)
            button.addAction(UIAction { _ in
                onSelect(suggestion)
            }, for: .touchUpInside)
            stackView.addArrangedSubview(button)
        }
        
        toolbar.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: toolbar.trailingAnchor, constant: -8),
            stackView.topAnchor.constraint(equalTo: toolbar.topAnchor, constant: 6),
            stackView.bottomAnchor.constraint(equalTo: toolbar.bottomAnchor, constant: -6)
        ])
        
        view.addSubview(toolbar)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}
