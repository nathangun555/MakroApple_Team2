//
//  InputMenuViewModel.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 06/11/25.
//

import SwiftUI
import Foundation
import Observation
import PDFKit

@Observable
@MainActor
class InputMenuViewModel {
    var errorMessage: String?
    var isUploadingPhotos = false
    var uploadedPhotoURLs: [String] = []
    var scannedCategories: [MenuCategory] = []
    var scanResponseRaw: String?
    
    private(set) var userId: String?
    
    func configure(userId: String?) {
        self.userId = userId
    }
    
    func uploadMenu(fileUrl: URL, completion: @escaping (Result<String, Error>) -> Void) {
        Task {
            do {
                let photoURL = try await SupabaseManager.shared.uploadFile(
                    fileUrl,
                    folder: "order-references"
                )
                uploadedPhotoURLs.append(photoURL)
                print("✅ File uploaded: \(photoURL)")
                completion(.success(photoURL))
            } catch {
                print("❌ Upload error: \(error)")
                errorMessage = error.localizedDescription
                completion(.failure(error))
            }
        }
    }

    
    private func saveImageToTemp(_ image: UIImage) -> URL? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let tempDir = FileManager.default.temporaryDirectory
        let filename = UUID().uuidString + ".jpg"
        let fileURL = tempDir.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("❌ Error saving temp image: \(error)")
            return nil
        }
    }

    func pdfToImages(pdfUrl: URL) -> [UIImage] {
        var didStartAccessing = false
        if pdfUrl.startAccessingSecurityScopedResource() {
            didStartAccessing = true
        }
        
        defer {
            if didStartAccessing {
                pdfUrl.stopAccessingSecurityScopedResource()
            }
        }
        
        let tempUrl = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".pdf")
        
        do {
            try FileManager.default.copyItem(at: pdfUrl, to: tempUrl)
        } catch {
            print("❌ Failed to copy PDF to temp directory: \(error)")
            return []
        }
        
        guard let pdfDocument = PDFDocument(url: tempUrl) else {
            print("❌ Could not open PDF")
            return []
        }
        
        var images: [UIImage] = []
        
        for pageIndex in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: pageIndex) {
                let pageRect = page.bounds(for: .mediaBox)
                let renderer = UIGraphicsImageRenderer(size: pageRect.size)
                
                let image = renderer.image { ctx in
                    UIColor.white.set()
                    ctx.fill(pageRect)
                    ctx.cgContext.translateBy(x: 0, y: pageRect.size.height)
                    ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
                    page.draw(with: .mediaBox, to: ctx.cgContext)
                }
                images.append(image)
            }
        }
    
        try? FileManager.default.removeItem(at: tempUrl)
        
        return images
    }

    func menuScanBatch(imageUrls: [String], completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "https://iznjcwyoziqjgfjahemb.supabase.co/functions/v1/menu-parser") else {
            print("❌ URL is invalid.")
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml6bmpjd3lvemlxamdmamFoZW1iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY3MTg3NjksImV4cCI6MjA3MjI5NDc2OX0.J9zQpQajTg3V6qAN18W5Fkv2jCDobL_XzuRS3BdPmdA"
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")

        // ✅ Send array of image URLs
        let body: [String: Any] = ["imageUrls": imageUrls]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        print("📤 Sending \(imageUrls.count) images to Edge Function...")

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ URLSession Error: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("HTTP Status Code: \(httpResponse.statusCode)")
                    if httpResponse.statusCode != 200 {
                        if let data = data, let responseBody = String(data: data, encoding: .utf8) {
                            print("❌ HTTP Error. Response Body: \(responseBody)")
                        }
                        completion(nil)
                        return
                    }
                }
                
                guard let data = data else {
                    print("❌ Received no data from the server")
                    completion(nil)
                    return
                }
                
                // Return raw JSON string for parsing in the view
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("✅ Received response with data")
                    completion(jsonString)
                } else {
                    print("❌ Failed to convert response to string")
                    completion(nil)
                }
            }
        }.resume()
    }

    
    func mapScanResult(scanResult: String) {
        scanResponseRaw = scanResult
        
        guard let jsonData = scanResult.data(using: .utf8) else {
            print("❌ Failed to convert scan result to Data")
            errorMessage = "Invalid scan result format"
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(MenuScanResponse.self, from: jsonData)
            scannedCategories = response.categories
            
            let totalProducts = response.categories.reduce(0) { $0 + $1.products.count }
            print("✅ Mapped \(response.categories.count) categories with \(totalProducts) products")
            
            // Debug print
            for category in response.categories {
                print("📁 \(category.categoryName): \(category.products.count) products")
                for product in category.products {
                    print("  - \(product.name): Rp\(product.price)")
                }
            }
            
        } catch {
            print("❌ Failed to decode scan result: \(error)")
            errorMessage = "Failed to parse menu data: \(error.localizedDescription)"
        }
    }

}
