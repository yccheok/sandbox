//
//  CameraService.swift
//  camera-scanning
//
//  Created by Yan Cheng Cheok on 16/01/2026.
//

import SwiftUI
import AVFoundation
import Combine

class CameraService: NSObject, ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var session = AVCaptureSession()
    @Published var alertError: AlertError?
    
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    
    // We keep a reference to the preview layer to calculate the crop rect later
    weak var previewLayer: AVCaptureVideoPreviewLayer?

    override init() {
        super.init()
        checkPermissions()
    }
    
    private func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted { self.setupSession() }
            }
        default:
            DispatchQueue.main.async {
                self.alertError = AlertError(title: "Camera Error", message: "Permission denied.")
            }
        }
    }
    
    private func setupSession() {
        sessionQueue.async {
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo // High res photo preset
            
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
                return
            }
            
            if self.session.canAddInput(videoInput) {
                self.session.addInput(videoInput)
            }
            
            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
            }
            
            self.session.commitConfiguration()
            self.session.startRunning()
        }
    }
    
    // MARK: - Capture & Crop Logic
    
    func capturePhoto(in boundingBox: CGRect) {
        // Create settings
        let settings = AVCapturePhotoSettings()
        
        // We pass the bounding box (from UI) as a context to the delegate
        // Note: In production, you might want to create a custom object to hold this
        // For simplicity, we will store the requested rect temporarily or calculate it in the delegate
        // However, the cleanest way in AVFoundation is to do the math *after* capture or use the previewLayer helper.
        
        photoOutput.capturePhoto(with: settings, delegate: self)
        
        // Store the rect to use inside the delegate
        self.lastBoundingBox = boundingBox
    }
    
    private var lastBoundingBox: CGRect = .zero

}

// MARK: - Delegate Extension
extension CameraService: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else { return }
        
        guard let imageData = photo.fileDataRepresentation(),
              let fullImage = UIImage(data: imageData),
              let previewLayer = self.previewLayer else { return }
        
        // 1. Convert UI Rectangle to Normalized Device Coordinates (0-1)
        // metadataOutputRectConverted converts the view's CGRect to the camera sensor's relative coordinates
        let normalizedRect = previewLayer.metadataOutputRectConverted(fromLayerRect: lastBoundingBox)
        
        // 2. Calculate the pixel rect on the actual image
        let cgImage = fullImage.cgImage!
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        
        // Note: AVCapture usually returns landscape orientation images natively.
        // If the photo is portrait, the coordinate system might be rotated.
        // For robustness, we usually fix orientation first, but here is the raw math:
        
        let cropRect = CGRect(
            x: normalizedRect.origin.x * width,
            y: normalizedRect.origin.y * height,
            width: normalizedRect.size.width * width,
            height: normalizedRect.size.height * height
        )
        
        // 3. Perform Crop
        if let croppedCG = cgImage.cropping(to: cropRect) {
            let croppedUIImage = UIImage(cgImage: croppedCG, scale: 1.0, orientation: fullImage.imageOrientation)
            
            DispatchQueue.main.async {
                self.capturedImage = croppedUIImage
                // Stop session if you want to freeze frame
                // self.session.stopRunning()
            }
        }
    }
}

struct AlertError: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
