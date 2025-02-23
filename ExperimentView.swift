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
    
    private var formattedPressureDepth: String {
        String(format: "%.0fm", chapterManager.currentPressureDepth)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 10) {
                // Header
                ExperimentHeader(title: experiment.title, description: experiment.description)
                
                // Interactive content
                switch experiment.interaction {
                case .colorChangeDemo(let name, _):
                    ColorExperimentView(
                        name: name,
                        sliderValue: $sliderValue,
                        depthText: $depthText,
                        onValueChanged: onValueChanged
                    )
                    
                case .pressureDemo(let name, _):
                    PressureExperimentView(
                        name: name,
                        sliderValue: $sliderValue,
                        depthText: $depthText,
                        onValueChanged: { value in
                            chapterManager.currentPressureDepth = value * 200
                            onValueChanged(value)
                        }
                    )
                    
                case .pressureCalculation(let name, _):
                    PressureCalculationView(
                        name: name,
                        pressureAnswer: $pressureAnswer,
                        depthText: .constant(formattedPressureDepth),  
                        feedbackMessage: $feedbackMessage,
                        isCorrect: $isCorrect,
                        isTextFieldFocused: _isTextFieldFocused,
                        checkPressure: checkPressureCalculation,
                        evaluateFormula: evaluateFormula
                    )
                    
                case .quiz(_, let questions):
                    QuizView(questions: questions, chapterManager: chapterManager)
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
    }
    
    private func checkPressureCalculation() {
        let depth = chapterManager.currentPressureDepth
        guard let answer = Float(pressureAnswer) else {
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
        switch formula {
        case "depth/10 + 1":    // Correct: Converts to ATM and adds surface pressure
            return depth/10 + 1
        case "depth/10":        // Wrong: Forgets to add surface pressure
            return depth/10
        case "(depth + 1)/10":  // Wrong: Adds 1 before dividing
            return (depth + 1)/10
        default:
            return nil
        }
    }
}

// MARK: - Subviews
private struct ExperimentHeader: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "circle.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 8))
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Text(description)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

private struct ColorExperimentView: View {
    let name: String
    @Binding var sliderValue: Float
    @Binding var depthText: String
    let onValueChanged: (Float) -> Void
    
    var body: some View {
        VStack {
            HStack {
                Text(name)
                    .foregroundColor(.white)
                Slider(value: $sliderValue, in: 0...1)
                    .onChange(of: sliderValue) { newValue in
                        let actualDepth = newValue * 200
                        depthText = String(format: "%.1fm", actualDepth)
                        onValueChanged(newValue)
                    }
                Text(depthText)
                    .foregroundColor(.white)
                    .frame(width: 60, alignment: .trailing)
            }
        }
    }
}

private struct PressureExperimentView: View {
    let name: String
    @Binding var sliderValue: Float
    @Binding var depthText: String
    let onValueChanged: (Float) -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            let parsedDepth = Float(depthText.replacingOccurrences(of: "m", with: "")) ?? 0
            PressureGaugeView(depth: parsedDepth, maxDepth: 200)
            
            HStack {
                Text(name)
                    .foregroundColor(.white)
                Slider(value: $sliderValue, in: 0...1)
                    .onChange(of: sliderValue) { newValue in
                        let actualDepth = newValue * 200
                        depthText = String(format: "%.0fm", actualDepth)
                        onValueChanged(newValue)
                    }
                Text(depthText)
                    .foregroundColor(.white)
                    .frame(width: 60, alignment: .trailing)
            }
        }
        .padding()
    }
}

private struct PressureCalculationView: View {
    let name: String
    @Binding var pressureAnswer: String
    @Binding var depthText: String
    @Binding var feedbackMessage: String
    @Binding var isCorrect: Bool
    @FocusState var isTextFieldFocused: Bool
    let checkPressure: () -> Void
    let evaluateFormula: (String, Float) -> Float?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Current depth indicator
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundColor(.blue)
                Text("Current depth: \(depthText)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            
            // Instructions
            VStack(alignment: .leading, spacing: 8) {
                Text("Calculate the water pressure at this depth")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Remember:")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("• Start with 1 ATM (surface pressure)")
                    Text("• Add 1 ATM for every 10m of depth")
                }
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .padding(.leading, 4)
            }
            
            // Formula reference (collapsible)
            DisclosureGroup {
                Text("Pressure = (depth ÷ 10) + 1 ATM")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.blue.opacity(0.8))
                    .padding(.vertical, 8)
            } label: {
                Text("Show formula")
                    .foregroundColor(.blue)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            
            // Input section
            VStack(alignment: .leading, spacing: 8) {
                Text("Your answer:")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                HStack(spacing: 12) {
                    TextField("Enter pressure", text: $pressureAnswer)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: .infinity)
                        .focused($isTextFieldFocused)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                FormulaKeyboardView(
                                    depthText: depthText,
                                    pressureAnswer: $pressureAnswer,
                                    evaluateFormula: evaluateFormula
                                )
                            }
                        }
                    
                    Text("ATM")
                        .foregroundColor(.white)
                        .font(.headline)
                    
                    Button("Check") {
                        checkPressure()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
            }
            .padding(.top, 8)
            
            // Feedback message
            if !feedbackMessage.isEmpty {
                Text(feedbackMessage)
                    .foregroundColor(isCorrect ? .green : .orange)
                    .font(.callout)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(isCorrect ? .green : .orange).opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.2))
        .cornerRadius(12)
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

// MARK: - Pressure Formulas
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

// MARK: - Formula Keyboard View
private struct FormulaKeyboardView: View {
    let depthText: String
    @Binding var pressureAnswer: String
    let evaluateFormula: (String, Float) -> Float?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach([
                    "depth/10 + 1",      // Correct formula
                    "depth/10",          // Wrong: Forgets to add surface pressure
                    "(depth + 1)/10",    // Wrong: Adds 1 before dividing
                ], id: \.self) { formula in
                    Button(action: {
                        if let depth = Float(depthText.replacingOccurrences(of: "m", with: "")),
                           let result = evaluateFormula(formula, depth) {
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
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                         to: nil,
                                         from: nil,
                                         for: nil)
        }
    }
}

private struct QuizView: View {
    let questions: [QuizQuestion]
    @ObservedObject var chapterManager: ChapterManager
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswer: Int? = nil
    @State private var showExplanation = false
    @State private var correctAnswers = 0
    @State private var hasCompletedQuiz = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Progress indicator
            HStack {
                Text("Question \(currentQuestionIndex + 1) of \(questions.count)")
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Text("Score: \(correctAnswers)/\(questions.count)")
                    .foregroundColor(.white)
            }
            .padding(.bottom, 8)
            
            // Question
            Text(questions[currentQuestionIndex].question)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Options
            VStack(spacing: 12) {
                ForEach(0..<questions[currentQuestionIndex].options.count, id: \.self) { index in
                    Button(action: {
                        if !showExplanation {
                            selectedAnswer = index
                            showExplanation = true
                            if index == questions[currentQuestionIndex].correctAnswer {
                                correctAnswers += 1
                            }
                        }
                    }) {
                        HStack {
                            Text(questions[currentQuestionIndex].options[index])
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            if showExplanation {
                                if index == questions[currentQuestionIndex].correctAnswer {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                } else if index == selectedAnswer {
                                    Image(systemName: "x.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(buttonBackgroundColor(for: index))
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(showExplanation)
                }
            }
            .frame(maxWidth: .infinity)
            
            // Explanation
            if showExplanation {
                VStack(alignment: .leading, spacing: 8) {
                    Text(selectedAnswer == questions[currentQuestionIndex].correctAnswer ? "Correct!" : "Not quite...")
                        .font(.headline)
                        .foregroundColor(selectedAnswer == questions[currentQuestionIndex].correctAnswer ? .green : .orange)
                    
                    Text(questions[currentQuestionIndex].explanation)
                        .foregroundColor(.white.opacity(0.9))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(10)
                
                Button(currentQuestionIndex < questions.count - 1 ? "Next Question" : "Finish Quiz") {
                    if currentQuestionIndex < questions.count - 1 {
                        currentQuestionIndex += 1
                        selectedAnswer = nil
                        showExplanation = false
                    } else {
                        hasCompletedQuiz = true
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .padding(.top)
            }
            
            if hasCompletedQuiz {
                QuizSummaryView(score: correctAnswers, total: questions.count)
                    .onAppear {
                        // Report quiz completion to ChapterManager
                        let percentage = Float(correctAnswers) / Float(questions.count)
                        chapterManager.handleInteraction(
                            element: InteractiveElement(
                                title: "Ocean Knowledge Quiz",
                                type: .quiz
                            ),
                            value: percentage
                        )
                    }
            }
        }
        .padding()
        .background(Color.black.opacity(0.2))
        .cornerRadius(12)
    }
    
    private func buttonBackgroundColor(for index: Int) -> Color {
        if !showExplanation {
            return Color.blue.opacity(0.3)
        }
        
        if index == questions[currentQuestionIndex].correctAnswer {
            return Color.green.opacity(0.3)
        }
        if index == selectedAnswer {
            return Color.red.opacity(0.3)
        }
        return Color.blue.opacity(0.2)
    }
}

private struct QuizSummaryView: View {
    let score: Int
    let total: Int
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Quiz Complete!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("You scored \(score) out of \(total)")
                .font(.title3)
                .foregroundColor(.white)
            
            Text(feedbackMessage)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.blue.opacity(0.2))
        .cornerRadius(12)
    }
    
    private var feedbackMessage: String {
        let percentage = Double(score) / Double(total)
        switch percentage {
        case 0.8...1.0:
            return "Excellent! You've mastered the concepts!"
        case 0.6..<0.8:
            return "Good job! You understand most of the material."
        case 0.4..<0.6:
            return "Keep practicing! You're getting there."
        default:
            return "Review the chapters again and try the quiz later."
        }
    }
}
