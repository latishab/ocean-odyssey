import SwiftUI
import UIKit

struct OceanViewRepresentable: UIViewRepresentable {
    @Binding var depth: Float
    
    // Remove static shared instance and make ViewHolder instance-based
    @MainActor
    class ViewHolder: @unchecked Sendable {
        var oceanView: OceanView?
        init() {}
    }
    
    // Create instance-level view holder
    private let viewHolder = ViewHolder()
    
    init(depth: Binding<Float>) {
        self._depth = depth
    }
    
    func makeUIView(context: Context) -> OceanView {
        let view = OceanView()
        view.setDepth(depth)
        Task { @MainActor in
            viewHolder.oceanView = view
        }
        return view
    }
    
    func updateUIView(_ uiView: OceanView, context: Context) {
        uiView.setDepth(depth)  
    }
    
    func getOceanView() -> OceanView? {
        return viewHolder.oceanView
    }
    
    static func dismantleUIView(_ uiView: OceanView, coordinator: ()) {
        Task { @MainActor in
            uiView.invalidateDisplayLink()
            uiView.releaseResources()
        }
    }
}

@main
struct MyApp: App {
    @State private var depth: Float = 0.0
    
    var body: some Scene {
        WindowGroup {
            ContentView(depth: $depth)
                .statusBar(hidden: true)
                .onAppear {
                    UIDevice.current.setValue(UIInterfaceOrientation.landscapeLeft.rawValue, forKey: "orientation")
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeLeft))
                        windowScene.windows.first?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
                    }
                }
        }
    }
}

struct ContentView: View {
    @Binding var depth: Float
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ChapterView(depth: $depth)
                
                DepthMarkerView(
                    depth: depth * 200,
                    yPosition: 0.5
                )
                .offset(x: geometry.size.width * 0.5)
            }
        }
    }
}

