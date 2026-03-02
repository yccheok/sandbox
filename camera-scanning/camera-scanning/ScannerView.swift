//
//  ContentView.swift
//  camera-scanning
//
//  Created by Yan Cheng Cheok on 16/01/2026.
//

import SwiftUI

struct ScannerView: View {
    @StateObject var cameraService = CameraService()

    // 2. Add Navigation Path state
    @State private var path = NavigationPath()
    
    var body: some View {
        // 3. Wrap entire content in NavigationStack
        NavigationStack(path: $path) {
            Group {
                if let image = cameraService.capturedImage {
                    capturedImageView(image)
                } else {
                    scannerUI()
                }
            }
            // navigation and lifecycle handlers remain the same
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .screenB:
                    // Pass the captured image to the new screen
                    if let image = cameraService.capturedImage {
                        CapturedResultView(image: image)
                    }
                case .screenC:
                    Text("Screen C")
                }
            }
            .onAppear {
                cameraService.start()
            }
            .onDisappear {
                cameraService.stop()
            }
            // Add the alert here
            .alert(
                cameraService.alertError?.title ?? "Error",
                isPresented: Binding(
                    get: { cameraService.alertError != nil },
                    set: { isPresented in
                        if !isPresented { cameraService.alertError = nil }
                    }
                ),
                presenting: cameraService.alertError
            ) { _ in
                Button("OK", role: .cancel) { }
            } message: { error in
                Text(error.message)
            }
        }
    }
    
    // MARK: - View Builders
    
    @ViewBuilder
    private func scannerUI() -> some View {
        ZStack {
            // Live camera feed
            GeometryReader { proxy in
                CameraPreviewView(cameraService: cameraService)
                    .onAppear {
                        cameraService.previewSize = proxy.size
                    }
                    .onChange(of: proxy.size) { _, newSize in
                        cameraService.previewSize = newSize
                    }
            }
            .edgesIgnoringSafeArea(.all)
            .statusBar(hidden: true)
            
            // Scanner frame and controls
            VStack {
                Spacer()
                
                CornerBrackets()
                    .frame(width: 300, height: 400)
                
                Spacer()
                
                HStack(spacing: 40) {
                    Button(action: { /* Toggle Flash */ }) {
                        Image(systemName: "photo")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    
                    Button(action: {
                        cameraService.capturePhoto()
                    }) {
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .background(Circle().fill(Color.black.opacity(0.6)))
                            .frame(width: 80, height: 80)
                            .overlay(Circle().fill(Color.white).padding(8))
                    }
                    
                    Button(action: { /* Toggle Flash */ }) {
                        Image(systemName: "photo")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .hidden()
                }
                .foregroundColor(.white)
                .padding(.bottom, 30)
            }
        }
    }
    
    @ViewBuilder
    private func capturedImageView(_ image: UIImage) -> some View {
        ZStack(alignment: .bottom) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .edgesIgnoringSafeArea(.all)
                .statusBarHidden(true)
            
            Button(action: { cameraService.capturedImage = nil }) {
                Image(systemName: "xmark")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
                    .padding(.bottom, 30)
            }
        }
    }
}

// Helper to draw corners like the screenshot
struct CornerBrackets: View {
    var body: some View {
        ZStack {
            // Top Left
            VStack { HStack { Bracket(); Spacer() }; Spacer() }
            // Top Right
            VStack { HStack { Spacer(); Bracket().rotationEffect(.degrees(90)) }; Spacer() }
            // Bottom Right
            VStack { Spacer(); HStack { Spacer(); Bracket().rotationEffect(.degrees(180)) } }
            // Bottom Left
            VStack { Spacer(); HStack { Bracket().rotationEffect(.degrees(270)); Spacer() } }
        }
        .padding(-2) // Offset slightly outside the border
    }
    
    struct Bracket: View {
        // 1. Set this to match the cornerRadius of your white border
        var cornerRadius: CGFloat = 20
        // 2. The total length of the bracket's side (curve + straight line)
        var length: CGFloat = 40
        
        var body: some View {
            Path { path in
                // Start at the bottom of the left vertical line
                path.move(to: CGPoint(x: 0, y: length))
                
                // Draw up to the corner, curve exactly matching the radius, and face right
                path.addArc(
                    tangent1End: CGPoint(x: 0, y: 0),
                    tangent2End: CGPoint(x: length, y: 0),
                    radius: cornerRadius
                )
                
                // Draw the remaining straight part on the top horizontal line
                path.addLine(to: CGPoint(x: length, y: 0))
            }
            .stroke(Color.white, style: StrokeStyle(lineWidth: 5, lineCap: .round))
            .frame(width: length, height: length)
        }
    }
}
