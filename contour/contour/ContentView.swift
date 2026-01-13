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
    @State private var contours: CGPath? = nil
    
    @State private var position: CGFloat = 0.0
    
    private let aspectRatio: CGSize = {
        guard let image = UIImage(named: "sample") else { return CGSize(width: 1, height: 1) }
        return image.size
    }()
    
    var body: some View {
        VStack {
            ZStack {
                Image("sample")
                    .resizable()
                    .scaledToFit()

                ContoursShape(contours: contours)
                    .stroke(Color.white, lineWidth: 2)
                    
                    // 3. Apply aspect ratio directly to the Shape.
                    //    SwiftUI Shapes naturally fill the space provided by this modifier.
                    .aspectRatio(aspectRatio, contentMode: .fit)
                    
                    // 4. The Mask
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
                                .frame(height: geo.size.height * 0.2) // 20% band
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
                    UIImage(named: "sample")!.size,
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
        Task {
            
            print(">>>> CALL detectContours Thread.isMainThread \(Thread.isMainThread)")
            
            do {
                contours = try await detectContours()
            } catch {
                print("Error detecting contours: \(error)")
            }
        }
    }
    
    private nonisolated func detectContours() async throws -> CGPath? {
        print(">>>> In detectContours Thread.isMainThread \(Thread.isMainThread)")
        
        let image = UIImage(named: "sample")!
        
        // Image to be used
        guard var image = CIImage(image: image) else {
            return nil
        }
        
        if let mask = createMask(from: image) {
            image = applyMask(mask: mask, to: image)
        }
        
        // Set up the detect contours request
        var request = DetectContoursRequest()
        request.contrastAdjustment = 2
        request.contrastPivot = 0.5
        
        // Perform the detect contours request
        let contoursObservations = try await request.perform(
            on: image,
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
