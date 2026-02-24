//
//  ContentView.swift
//  camera-scanning
//
//  Created by Yan Cheng Cheok on 16/01/2026.
//

import SwiftUI

struct ScannerView: View {
    @StateObject var cameraService = CameraService()

    var body: some View {
        ZStack {
            // 1. Live Camera Feed
            CameraPreviewView(cameraService: cameraService)
                .edgesIgnoringSafeArea(.all)
                .statusBar(hidden: true)
          
            // 3. The Scanner UI Box (Visuals)
            VStack {
                Spacer()
                
                CornerBrackets()
                    .frame(width: 300, height: 400)
                
                Spacer()
                

                // 4. Controls
                HStack(spacing: 40) {
                    Button(action: { /* Toggle Flash */ }) {
                        Image(systemName: "photo")
                            // 1. Use font to size the icon safely without stretching its bounding box
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            // 2. Force the exact button and background size you want
                            .frame(width: 56, height: 56)
                            // 3. Apply the background and clip it into a perfect circle
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    
                    // Capture Button
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
                            // 1. Use font to size the icon safely without stretching its bounding box
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            // 2. Force the exact button and background size you want
                            .frame(width: 56, height: 56)
                            // 3. Apply the background and clip it into a perfect circle
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .hidden()
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
        .onAppear {
            cameraService.start()
        }
        .onDisappear {
            cameraService.stop()
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
