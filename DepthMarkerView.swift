import SwiftUI

struct DepthMarkerView: View {
    let depth: Float
    let yPosition: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dashed line
                Path { path in
                    let y = yPosition * geometry.size.height
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                }
                .stroke(style: StrokeStyle(
                    lineWidth: 1,
                    dash: [5, 5]  // 5 points line, 5 points gap
                ))
                .foregroundColor(.white.opacity(0.5))
                
                // Depth text
                Text(String(format: "%.1f m", depth))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(4)
                    .position(x: geometry.size.width - 50,
                            y: yPosition * geometry.size.height)
            }
        }
    }
} 