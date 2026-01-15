@preconcurrency import SwiftUI
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

struct ContoursShape: Shape {
    
    var contours: CGPath?
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        if let contours = contours {
            let transform = CGAffineTransform(
                scaleX: rect.width, y: rect.height
            )
            
            path.addPath(Path(contours), transform: transform)
        }
        
        return path
    }
    
}

struct ContourDetectionView: View {
    private let sourceImage: UIImage
    
    @State private var contours: CGPath? = nil
    @State private var position: CGFloat = 0.0
    
    init(imageName: String = "sample") {
        if let img = UIImage(named: imageName) {
            self.sourceImage = img
        } else {
            // Fallback empty image to prevent crash if asset is missing
            self.sourceImage = UIImage()
            print("Error: Image \(imageName) not found")
        }
    }
    
    var body: some View {
        VStack {
            ZStack {
                Image(uiImage: sourceImage)
                    .resizable()
                    .scaledToFit()

                ContoursShape(contours: contours)

                    .stroke(Color.white, lineWidth: 2)
                    .aspectRatio(sourceImage.size, contentMode: .fit)
                    .mask(
                        GeometryReader { geo in
                            Color.black
                                .frame(height: geo.size.height * 0.2)
                                .offset(y: (position - 0.2) * geo.size.height)
                        }
                    )

                GeometryReader { geo in
                    Color.white
                        .frame(width: geo.size.width, height: geo.size.height)
                        .mask(
                            GeometryReader { geo in
                                LinearGradient(
                                    colors: [.clear, .black],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(height: geo.size.height * 0.2)
                                .offset(y: (position - 0.2) * geo.size.height)
                            }
                        )
                        .onAppear {
                            withAnimation(
                                .easeInOut(duration: 2)
                                    .repeatForever(autoreverses: true)
                            ) {
                                position = 1.0
                            }
                        }
                }
                .aspectRatio(
                    sourceImage.size,
                    contentMode: .fit
                )
            }
      
            Button {
                self.drawContours()
            } label: {
                Text("Draw Contours")
            }
        }
        .padding()
    }
    
    private func drawContours() {
        let processingImage = self.sourceImage
                
        Task {
            do {
                contours = try await detectContours(from: processingImage)
            } catch {
                print("Error detecting contours: \(error)")
            }
        }
    }
    
    
    @concurrent
    private func detectContours(from inputImage: UIImage) async throws -> CGPath? {
        // Image conversion
        guard var ciImage = CIImage(image: inputImage) else {
            return nil
        }
        
        if let mask = createMask(from: ciImage) {
            ciImage = applyMask(mask: mask, to: ciImage)
        }
        
        // Set up the detect contours request
        var request = DetectContoursRequest()
        request.contrastAdjustment = 2
        request.contrastPivot = 0.5
        
        // Perform the detect contours request
        let contoursObservations = try await request.perform(
            on: ciImage,
            orientation: .downMirrored
        )
        
        // An array of all detected contours as a path object
        let contours = contoursObservations.normalizedPath
        
        return contours
    }
    
    private nonisolated func createMask(from inputImage: CIImage) -> CIImage? {
        
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(ciImage: inputImage)

        do {
            try handler.perform([request])
            
            if let result = request.results?.first {
                let mask = try result.generateScaledMaskForImage(forInstances: result.allInstances, from: handler)
                return CIImage(cvPixelBuffer: mask)
            }
        } catch {
            print(error)
        }
        
        return nil
    }
    
    private nonisolated func applyMask(mask: CIImage, to image: CIImage) -> CIImage {
        let filter = CIFilter.blendWithMask()
        
        filter.inputImage = image
        filter.maskImage = mask
        filter.backgroundImage = CIImage.empty()
        
        return filter.outputImage!
    }
}
