import SwiftUI

struct PressureGaugeView: View {
    let depth: Float
    let maxDepth: Float
    
    private var pressure: Float {
        (depth / 10.0) + 1.0
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Pressure Gauge
            ZStack {
                // Gauge background
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 10)
                    .frame(width: 150, height: 150)
                
                // Pressure indicator
                Circle()
                    .trim(from: 0, to: CGFloat(min(pressure / (maxDepth/10 + 1), 1.0)))
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .red]),
                            startPoint: .bottom,
                            endPoint: .top
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))
                
                // Center display
                VStack {
                    Text("\(Int(pressure * 10)/10, specifier: "%.1f")")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("ATM")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            // Depth indicator
            VStack(spacing: 5) {
                Text("Current Depth")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                Text("\(Int(depth))m")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // Pressure explanation
            if depth > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pressure Breakdown:")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    Text("• 1 ATM (surface pressure)")
                        .foregroundColor(.white)
                    if depth > 0 {
                        Text("• \(String(format: "%.1f", pressure - 1)) ATM (from \(Int(depth))m of water)")
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.black.opacity(0.2))
        .cornerRadius(16)
    }
}

// Preview provider for SwiftUI canvas
struct PressureGaugeView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            PressureGaugeView(depth: 30, maxDepth: 50)
        }
    }
} 