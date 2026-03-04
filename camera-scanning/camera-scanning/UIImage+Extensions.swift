import UIKit

extension UIImage {
    /// Explicitly offloads the heavy image rendering to the background thread pool
    /// in Swift 6.2+, preventing the main thread from blocking.
    @concurrent
    func resizedForAI(maxDimension: CGFloat = 768.0) async -> UIImage {
        let originalSize = self.size
        
        // 1. Guard against upscaling
        if originalSize.width <= maxDimension && originalSize.height <= maxDimension {
            return self
        }
        
        // 2. Calculate the new size preserving the aspect ratio
        let aspectRatio = originalSize.width / originalSize.height
        let newSize: CGSize
        
        if originalSize.width > originalSize.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        
        // 3. Setup the renderer format
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        
        // 4. Render the new image (runs safely in the background)
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
