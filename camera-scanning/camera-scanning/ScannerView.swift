//
//  ContentView.swift
//  camera-scanning
//
//  Created by Yan Cheng Cheok on 16/01/2026.
//

import SwiftUI

struct ScannerView: View {
    @StateObject var cameraService = CameraService()
    
    // This defines the size of your scan area (e.g., square or 4:3)
    // We use a GeometryReader in the body to get exact screen coordinates
    @State private var scanRect: CGRect = .zero
    
    var body: some View {
        ZStack {
            // 1. Live Camera Feed
            CameraPreviewView(cameraService: cameraService)
                .edgesIgnoringSafeArea(.all)
            
            // 2. Darken overlay (The area outside the box)
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
                .mask(
                    ZStack {
                        Rectangle().fill(Color.white) // Full screen
                        
                        // Cut out the hole
                        RoundedRectangle(cornerRadius: 20)
                            .frame(width: 300, height: 400) // Adjust size as needed
                            .blendMode(.destinationOut)
                    }
                    .compositingGroup()
                )
            
            // 3. The Scanner UI Box (Visuals)
            VStack {
                Spacer()
                
                ZStack {
                    // This invisible view is just to measure the frame for the cropper
                    GeometryReader { geo in
                        Color.clear
                            .onAppear {
                                // Save the rect frame in global coordinates
                                self.scanRect = geo.frame(in: .global)
                            }
                            .onChange(of: geo.frame(in: .global)) { newFrame in
                                self.scanRect = newFrame
                            }
                    }
                    
                    // The visual white border and corners
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white, lineWidth: 3)
                    
                    // Corner Brackets (Optional visual flair from screenshot)
                    CornerBrackets()
                }
                .frame(width: 300, height: 400) // Match the hole size
                
                Spacer()
                
                // 4. Controls
                HStack(spacing: 40) {
                    Button(action: { /* Toggle Flash */ }) {
                        Image(systemName: "bolt.fill").font(.title)
                    }
                    
                    // Capture Button
                    Button(action: {
                        cameraService.capturePhoto(in: scanRect)
                    }) {
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 70, height: 70)
                            .overlay(Circle().fill(Color.white).padding(6))
                    }
                    
                    Button(action: { /* Help */ }) {
                        Image(systemName: "questionmark.circle").font(.title)
                    }
                }
                .foregroundColor(.white)
                .padding(.bottom, 30)
            }
            
            // 5. Result Preview (For testing)
            if let img = cameraService.capturedImage {
                VStack {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.green, lineWidth: 3))
                    
                    Button("Close") {
                        cameraService.capturedImage = nil
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                }
                .background(Color.black.opacity(0.8))
                .cornerRadius(20)
                .shadow(radius: 20)
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
        var body: some View {
            Path { path in
                path.move(to: CGPoint(x: 0, y: 30))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 30, y: 0))
            }
            .stroke(Color.white, style: StrokeStyle(lineWidth: 5, lineCap: .round))
            .frame(width: 30, height: 30)
        }
    }
}
