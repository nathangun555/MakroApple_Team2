//
//  Set_InputMenuViewModel.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 16/11/25.
//

import SwiftUI
import Foundation
import Observation
import PDFKit

@Observable
@MainActor
class Set_InputMenuViewModel {
    var errorMessage: String?
    var isUploadingPhotos = false
    var uploadedPhotoURLs: [String] = []
    var scannedCategories: [MenuCategory] = []
    var scanResponseRaw: String?

    private(set) var userId: String?

    func configure(userId: String?) {
        self.userId = userId
    }

    // MARK: - Upload (MIME + upsert)
    func uploadMenu(fileUrl: URL, completion: @escaping (Result<String, Error>) -> Void) {
        Task {
            do {
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

    // MARK: - PDF to images
    func pdfToImages(pdfUrl: URL) -> [UIImage] {
        var didStartAccessing = false
        if pdfUrl.startAccessingSecurityScopedResource() { didStartAccessing = true }
        defer { if didStartAccessing { pdfUrl.stopAccessingSecurityScopedResource() } }

        let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".pdf")
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

    // MARK: - Call Edge Function (single batch)
    func menuScanBatch(imageUrls: [String], completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "https://hddpofvkwanymugjtlpp.supabase.co/functions/v1/menu-parser") else {
            print("❌ URL is invalid.")
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 90

        // NOTE: ganti key ini jika perlu
        let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhkZHBvZnZrd2FueW11Z2p0bHBwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc3ODczMTIsImV4cCI6MjA4MzM2MzMxMn0.47Ts6UPaoQHQhrQ2nVx8LnTxFuJxdjZUXbr0mkLw9cA"
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
