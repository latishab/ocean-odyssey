import Foundation

struct InteractiveElement: Identifiable {
    let id = UUID()
    let title: String
    let type: InteractionType
    var value: Float = 0
    
    enum InteractionType {
        case slider
        case toggle
        case button
        case colorPicker
        case colorBallDemo
    }
} 