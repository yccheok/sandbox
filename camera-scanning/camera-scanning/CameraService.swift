import SwiftUI
import AVFoundation
import Combine

class CameraService: NSObject, ObservableObject {
    @Published var capturedImage: UIImage?
    // 1. AlertError should be published on MainActor usually, but @Published handles it.
    @Published var alertError: AlertError?
    
    // 2. Keep session public for PreviewLayer, but manage lifecycle internally
    let session = AVCaptureSession()
    
    private let photoOutput = AVCapturePhotoOutput()
    // 3. Serial queue is correct to prevent blocking Main Thread
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    
    private var isSessionConfigured = false
    
    override init() {
        super.init()
        // Don't auto-start in init. Just check permissions.
        // Let the View tell us when to start (onAppear).
        checkPermissions()
    }
    
    // MARK: - Deinit Safety
    deinit {
        // 4. STOPPING IN DEINIT
        // We capture the SESSION, not 'self'. self is dying.
        let session = self.session
        sessionQueue.async {
            if session.isRunning {
                session.stopRunning()
            }
        }
        print("CameraService deinit: Camera stopped")
    }
    
    // MARK: - Lifecycle Management
    
    // Call this from SwiftUI .onAppear
    func start() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            // Only setup if needed
            if !self.isSessionConfigured {
                self.setupSession()
            }
            // Only start if not running
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }
    
    // Call this from SwiftUI .onDisappear
    func stop() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }
    
    private func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // Permission good, wait for start() to be called
            break
        case .notDetermined:
            sessionQueue.suspend() // Pause queue until we know
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    self.sessionQueue.resume()
                } else {
                    // Handle denial
                    DispatchQueue.main.async {
                        self.alertError = AlertError(title: "Camera Error", message: "Permission denied.")
                    }
                    self.sessionQueue.resume()
                }
            }
        default:
            DispatchQueue.main.async {
                self.alertError = AlertError(title: "Camera Error", message: "Permission denied.")
            }
        }
    }
    
    private func setupSession() {
        // 5. MEMORY SAFETY: Guard against retain cycles if this takes long
        guard !isSessionConfigured else { return }
        
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            session.commitConfiguration()
            return
        }
        
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }
        
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        
        session.commitConfiguration()
        isSessionConfigured = true
        // Note: We do NOT call startRunning() here anymore. We let the start() method do it.
    }
    
    func capturePhoto() {
        // Ensure we are on the session queue or just dispatch carefully.
        // capturePhoto itself is thread-safe but settings creation is fast.
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

// MARK: - Delegate
extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing: \(error)")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let fullImage = UIImage(data: imageData) else { return }
        
        DispatchQueue.main.async {
            self.capturedImage = fullImage
        }
    }
}

struct AlertError: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
