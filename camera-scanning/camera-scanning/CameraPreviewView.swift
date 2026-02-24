//
//  CameraPreviewView.swift
//  camera-scanning
//
//  Created by Yan Cheng Cheok on 16/01/2026.
//

import SwiftUI
import UIKit
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    @ObservedObject var cameraService: CameraService
    
    func makeUIView(context: Context) -> VideoPreviewUIView {
        let view = VideoPreviewUIView()
        view.backgroundColor = .black
        
        // Use the layer created by our subclass
        view.videoPreviewLayer.session = cameraService.session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        
        return view
    }
    
    func updateUIView(_ uiView: VideoPreviewUIView, context: Context) {
        // No manual frame setting needed here!
        // The UIView's auto-layout handles it.
    }
    
    // This is the magic part
    class VideoPreviewUIView: UIView {
        // Tells UIKit to use AVCaptureVideoPreviewLayer as the backing layer
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }
        
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
    }
}
