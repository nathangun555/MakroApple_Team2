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
    
    var isLoading = false
    
    private(set) var userId: String?
    
    func configure(userId: String?) {
        self.userId = userId
    }
    
    // MARK: - Upload (set MIME benar + upsert via manager)
    func uploadMenu(fileUrl: URL, completion: @escaping (Result<String, Error>) -> Void) {
        Task {
            do {
                // Tentukan MIME dari ekstensi
                let ext = fileUrl.pathExtension.lowercased()
                let mime: String
                switch ext {
                case "png": mime = "image/png"
                case "pdf": mime = "application/pdf"
                default:    mime = "image/jpeg"
                }

                let photoURL = try await SupabaseManager.shared.uploadFile(
                    fileUrl,
                    folder: "order-references",
                    contentType: mime,
                    upsert: true,
                    maxRetry: 3
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

    // MARK: - Image helpers
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
        if pdfUrl.startAccessingSecurityScopedResource() { didStartAccessing = true }
        defer { if didStartAccessing { pdfUrl.stopAccessingSecurityScopedResource() } }
        
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
    
    // MARK: - Scan batched (opsional; tidak dipakai untuk "1 scan per batch")
    func menuScanBatchBatched(imageUrls: [String],
                              batchSize: Int = 6,
                              completion: @escaping (String?) -> Void) {
        let chunks = stride(from: 0, to: imageUrls.count, by: batchSize).map {
            Array(imageUrls[$0..<min($0 + batchSize, imageUrls.count)])
        }
        
        var aggregatedCategories: [[String: Any]] = []
        
        func mergeCategories(_ newCats: [[String: Any]]) {
            for cat in newCats {
                guard let catNameRaw = cat["category_name"] as? String,
                      let products = cat["products"] as? [[String: Any]] else { continue }
                let catName = catNameRaw.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if let idx = aggregatedCategories.firstIndex(where: {
                    (($0["category_name"] as? String)?.caseInsensitiveCompare(catName) == .orderedSame)
                }) {
                    var existing = aggregatedCategories[idx]
                    var list = (existing["products"] as? [[String: Any]]) ?? []
                    var seen = Set(list.compactMap { p in
                        if let n = p["name"] as? String,
                           let pr = p["price"] as? NSNumber { return "\(n)@@\(pr.intValue)" }
                        return nil
                    })
                    for p in products {
                        if let n = p["name"] as? String,
                           let pr = p["price"] as? NSNumber {
                            let sig = "\(n)@@\(pr.intValue)"
                            if !seen.contains(sig) { list.append(p); seen.insert(sig) }
                        }
                    }
                    existing["products"] = list
                    aggregatedCategories[idx] = existing
                } else {
                    aggregatedCategories.append(["category_name": catName, "products": products])
                }
            }
        }
        
        func next(_ i: Int) {
            if i >= chunks.count {
                let final: [String: Any] = ["categories": aggregatedCategories]
                if let data = try? JSONSerialization.data(withJSONObject: final),
                   let json = String(data: data, encoding: .utf8) {
                    completion(json)
                } else {
                    completion(nil)
                }
                return
            }
            
            menuScanBatch(imageUrls: chunks[i]) { jsonString in
                if let jsonString,
                   let data = jsonString.data(using: .utf8),
                   let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let cats = obj["categories"] as? [[String: Any]] {
                    mergeCategories(cats)
                }
                next(i + 1)
            }
        }
        
        next(0)
    }
    
    // MARK: - Scan single batch (detail: low, timeout besar)
    func menuScanBatch(imageUrls: [String], completion: @escaping (String?) -> Void) {
        isLoading = true
        guard let url = URL(string: "https://ynxrqdbpovgmhhoobfjt.supabase.co/functions/v1/menu-parser") else {
            print("❌ URL is invalid.")
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 90
        
        let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlueHJxZGJwb3ZnbWhob29iZmp0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAwODkwMjksImV4cCI6MjA3NTY2NTAyOX0.1da8SzP39NVbIt7gLgRbPA6wG3aDpL0es5nb-GCNfG4"
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = ["imageUrls": imageUrls, "detail": "low"]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        print("📤 Sending \(imageUrls.count) images to Edge Function...")
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 90
        config.timeoutIntervalForResource = 120
        let session = URLSession(configuration: config)
        
        func callEdgeWithRetry(_ req: URLRequest, attempt: Int = 0) {
            session.dataTask(with: req) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error as NSError? {
                        if error.domain == NSURLErrorDomain, error.code == -1001, attempt < 1 {
                            // Retry sekali untuk -1001
                            let delay = DispatchTime.now() + .milliseconds(600)
                            DispatchQueue.global().asyncAfter(deadline: delay) {
                                callEdgeWithRetry(req, attempt: attempt + 1)
                            }
                            return
                        }
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
        
        callEdgeWithRetry(request, attempt: 0)
    }
    
    // MARK: - Parse result
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

            // Normalisasi ringan (trim + fallback productType kosong)
            let categoriesBaru: [MenuCategory] = response.categories.map { cat in
                let catName = cat.categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
                let fixedProducts = cat.products.map { p in
                    let ptTrim = p.productType.trimmingCharacters(in: .whitespacesAndNewlines)
                    let pt = ptTrim.isEmpty ? "No Category" : ptTrim
                    return MenuProduct(
                        name: p.name.trimmingCharacters(in: .whitespacesAndNewlines),
                        price: p.price,
                        notes: p.notes,
                        productType: pt
                    )
                }
                return MenuCategory(categoryName: catName, products: fixedProducts)
            }

            // PAKAI categoriesBaru, bukan response.categories
            scannedCategories = categoriesBaru
            sortCategoriesAlphabetically()

            let totalProducts = scannedCategories.reduce(0) { $0 + $1.products.count }
            print("✅ Mapped \(scannedCategories.count) categories with \(totalProducts) products")
            for category in scannedCategories {
                print("📁 \(category.categoryName): \(category.products.count) products")
                for product in category.products {
                    print("  - \(product.name): Rp\(product.price)")
                }
            }
            isLoading = false
        } catch {
            print("❌ Failed to decode scan result: \(error)")
            errorMessage = "Failed to parse menu data: \(error.localizedDescription)"
        }
    }


    
    private func sortCategoriesAlphabetically() {
        scannedCategories = scannedCategories.map { cat in
            var prods = cat.products
            prods.sort {
                $0.name.trimmingCharacters(in: .whitespacesAndNewlines)
                    .localizedCaseInsensitiveCompare(
                        $1.name.trimmingCharacters(in: .whitespacesAndNewlines)
                    ) == .orderedAscending
            }
            return MenuCategory(categoryName: cat.categoryName, products: prods)
        }
        scannedCategories.sort {
            $0.categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
                .localizedCaseInsensitiveCompare(
                    $1.categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
                ) == .orderedAscending
        }
    }


}

