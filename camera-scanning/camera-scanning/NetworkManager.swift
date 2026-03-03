import Foundation
import UIKit

// Define some basic errors
enum NetworkError: Error {
    case invalidURL
    case compressionFailed
    case invalidResponse
    case serverError(Int)
}

class NetworkManager {
    static let shared = NetworkManager()
    
    private init() {}
    
    // Replace with your actual API endpoint
    private let uploadURL = "http://192.168.1.106:5050/upload"
    
    func uploadImage(_ image: UIImage) async throws -> String {
        guard let url = URL(string: uploadURL) else {
            throw NetworkError.invalidURL
        }
        
        // 1. Convert UIImage to JPEG Data (0.8 is a good balance of quality and size)
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NetworkError.compressionFailed
        }
        
        // 2. Setup the URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // 3. Create a unique boundary string for the multipart form
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Optional: Add authorization headers if your API requires a token
        // request.setValue("Bearer YOUR_TOKEN_HERE", forHTTPHeaderField: "Authorization")
        
        // 4. Construct the multipart form body
        request.httpBody = createMultipartBody(
            imageData: imageData,
            boundary: boundary,
            attachmentKey: "file", // Change this to match the key your API expects (e.g., "image", "upload", "file")
            fileName: "scanned_document.jpg"
        )
        
        // 5. Execute the network request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 6. Validate the response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            print("Server responded with status code: \(httpResponse.statusCode)")
            throw NetworkError.serverError(httpResponse.statusCode)
        }
        
        // 7. Return the raw response string (or decode to a Model if needed)
        return String(decoding: data, as: UTF8.self)
    }
    
    // Helper function to build the multipart/form-data body
    private func createMultipartBody(imageData: Data, boundary: String, attachmentKey: String, fileName: String) -> Data {
        var body = Data()
        
        let lineBreak = "\r\n"
        
        // Start Boundary
        body.append("--\(boundary)\(lineBreak)")
        // Content-Disposition
        body.append("Content-Disposition: form-data; name=\"\(attachmentKey)\"; filename=\"\(fileName)\"\(lineBreak)")
        // Content-Type
        body.append("Content-Type: image/jpeg\(lineBreak)\(lineBreak)")
        // Image Data
        body.append(imageData)
        body.append(lineBreak)
        
        // End Boundary
        body.append("--\(boundary)--\(lineBreak)")
        
        return body
    }
}

// Helper extension to make appending strings to Data easier
private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
