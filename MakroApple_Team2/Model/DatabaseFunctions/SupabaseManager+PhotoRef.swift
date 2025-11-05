//
//  SupabaseManager+PhotoRef.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 31/10/25.
//

import Foundation
import Supabase

extension SupabaseManager {
    func uploadFile(_ fileURL: URL, folder: String = "uploads") async throws -> String {
        guard fileURL.isFileURL else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid file URL"])
        }
        
        let filename = "\(UUID().uuidString)-\(fileURL.lastPathComponent)"
        let filepath = "\(folder)/\(filename)"
        
        var didStartAccessing = false
        if fileURL.startAccessingSecurityScopedResource() {
            didStartAccessing = true
        }
        
        defer {
            if didStartAccessing {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }
        
        let fileData = try Data(contentsOf: fileURL)
        
        let uploadResponse = try await client.storage
            .from("MakroAppleTeam2_Bucket")
            .upload(
                filepath,
                data: fileData,
                options: FileOptions(contentType: "application/octet-stream")
            )
        
        print("Upload response:", uploadResponse)
        
        let publicURL = try client.storage
            .from("MakroAppleTeam2_Bucket")
            .getPublicURL(path: filepath)
        
        return publicURL.absoluteString
    }
}
