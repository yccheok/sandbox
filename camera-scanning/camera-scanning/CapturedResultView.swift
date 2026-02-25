import SwiftUI
import UIKit

struct CapturedResultView: View {
    let image: UIImage
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        // 1. GeometryReader gives us the exact screen dimensions
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                
                // 2. The Image (Constrained to Screen Size)
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    // 3. Force the image frame to match the screen exactly
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped() // Crop the parts that overflow
                
                // 4. Custom Floating Back Button
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }
                .padding(.leading, 20)
                // 5. Use safeAreaInsets to position correctly on any device (dynamic island/notch)
                .padding(.top, geometry.safeAreaInsets.top)
            }
        }
        .ignoresSafeArea() // Allow the GeometryReader to fill the whole screen
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}
