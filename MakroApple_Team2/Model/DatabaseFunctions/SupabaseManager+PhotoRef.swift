//
//  SupabaseManager+PhotoRef.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 31/10/25.
//

import Foundation
import Supabase
import UniformTypeIdentifiers

extension SupabaseManager {
    /// Upload file ke Supabase Storage dengan MIME yang benar + retry eksponensial untuk error jaringan.
    func uploadFile(_ fileURL: URL,
                    folder: String = "uploads",
                    contentType forcedContentType: String? = nil,
                    cacheControl: String = "public, max-age=31536000, immutable",
                    upsert: Bool = true,
                    maxRetry: Int = 3) async throws -> String {
        guard fileURL.isFileURL else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid file URL"])
        }

        // Ekstensi & nama file aman
        let originalExt = fileURL.pathExtension.lowercased()
        let baseName = fileURL.deletingPathExtension().lastPathComponent
        let sanitizedBase = baseName.replacingOccurrences(of: "[^A-Za-z0-9._-]+",
                                                          with: "-",
                                                          options: .regularExpression)
        let safeExt = originalExt.isEmpty ? "jpg" : originalExt
        let filename = "\(UUID().uuidString)-\(sanitizedBase).\(safeExt)"
        let filepath = "\(folder)/\(filename)"

        // Tentukan contentType
        let resolvedContentType: String = {
            if let forced = forcedContentType { return forced }
            switch safeExt {
            case "jpg", "jpeg": return "image/jpeg"
            case "png": return "image/png"
            case "gif": return "image/gif"
            case "pdf": return "application/pdf"
            default:
                if let ut = UTType(filenameExtension: safeExt),
                   let mime = ut.preferredMIMEType {
                    return mime
                }
                return "application/octet-stream"
            }
        }()

        // Security-scoped access (untuk iOS sandbox)
        var didStartAccessing = false
        if fileURL.startAccessingSecurityScopedResource() { didStartAccessing = true }
        defer { if didStartAccessing { fileURL.stopAccessingSecurityScopedResource() } }

        let fileData = try Data(contentsOf: fileURL)

        // Retry eksponensial untuk error jaringan tertentu
        var attempt = 0
        var lastError: Error?

        while attempt <= maxRetry {
            do {
                let uploadResponse = try await client.storage
                    .from("MakroAppleTeam2_Bucket")
                    .upload(
                        filepath,
                        data: fileData,
                        options: FileOptions(
                            cacheControl: cacheControl,          // e.g. immutable 1 tahun
                            contentType: resolvedContentType,    // image/jpeg, image/png, application/pdf
                            upsert: upsert                        // true: cegah 409 Duplicate saat retry
                        )
                    )

                print("Upload response:", uploadResponse)

                let publicURL = try client.storage
                    .from("MakroAppleTeam2_Bucket")
                    .getPublicURL(path: filepath)

                return publicURL.absoluteString
            } catch {
                lastError = error
                let nsErr = error as NSError
                // -1005: The network connection was lost, -1001: timed out
                let shouldRetry = nsErr.domain == NSURLErrorDomain && (nsErr.code == -1005 || nsErr.code == -1001)
                if shouldRetry && attempt < maxRetry {
                    attempt += 1
                    // Backoff: 0.2s, 0.4s, 0.8s
                    let backoff = UInt64(pow(2.0, Double(attempt)) * 200_000_000)
                    print("⚠️ Upload transient error (\(nsErr.code)). Retrying in \(Double(backoff)/1_000_000_000)s (attempt \(attempt)/\(maxRetry))")
                    try? await Task.sleep(nanoseconds: backoff)
                    continue
                }
                print("❌ Upload failed permanently:", error)
                throw error
            }
        }

        throw lastError ?? NSError(domain: "upload", code: -1, userInfo: [NSLocalizedDescriptionKey: "Upload failed"])
    }
    
    func deleteFiles(fromPublicURLs urls: [String]) async throws {
            let paths: [String] = urls.compactMap { urlString in
                guard let url = URL(string: urlString) else { return nil }
                
                // Example:
                // https://xxx.supabase.co/storage/v1/object/public/order-references/abc.jpg
                guard let range = url.path.range(of: "/object/public/") else { return nil }
                return String(url.path[range.upperBound...])
            }
            
            guard !paths.isEmpty else { return }
            
            try await client.storage
                .from("MakroAppleTeam2_Bucket")
                .remove(paths: paths)
        }
}
