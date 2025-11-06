//
//  Set_BusinessDetailsViewModel.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 21/10/25.
//

import Foundation
import SwiftUI
import Combine
import PhotosUI
import UIKit
import Storage
import Supabase

@MainActor
final class Set_BusinessDetailsViewModel: ObservableObject {
  @Published var businessName = ""
  @Published var businessPhone = ""
  @Published var businessAddress = ""
  @Published var businessLogoUrl = ""
  @Published var businessEmail = ""
  @Published var bankAccountNumber = ""
  @Published var bankAccountName = ""
  @Published var bankName = ""

  @Published var isLoading = false
  @Published var isSaving = false
  @Published var errorMessage: String?
  @Published var saveSuccess = false

  private(set) var userId: String?

  func configure(userId: String?) {
    self.userId = userId
  }

  func load() async {
    guard let userId, let uuid = UUID(uuidString: userId) else {
      errorMessage = "User belum login atau UID tidak valid."
      return
    }
    isLoading = true
    errorMessage = nil
    saveSuccess = false
    defer { isLoading = false }

    do {
      if let u = try await SupabaseManager.shared.fetchUser(by: uuid) {
        businessName        = u.businessName ?? ""
        businessPhone       = u.businessPhone ?? ""
        businessAddress     = u.businessAddress ?? ""
        businessLogoUrl     = u.businessLogoUrl ?? ""
        businessEmail       = u.businessEmail ?? ""
        bankAccountNumber   = u.bankAccountNumber ?? ""
        bankAccountName     = u.bankAccountName ?? ""
        bankName            = u.bankName ?? ""
      }
    } catch {
      errorMessage = "Gagal memuat data: \(error.localizedDescription)"
    }
  }

  func validate() -> String? {
    if businessName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      return "Nama bisnis wajib diisi."
    }
    if !businessEmail.isEmpty {
      let pattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
      if businessEmail.range(of: pattern, options: [.regularExpression, .caseInsensitive]) == nil {
        return "Format email bisnis tidak valid."
      }
    }
    return nil
  }

  func save() async {
    guard let userId, let uuid = UUID(uuidString: userId) else {
      errorMessage = "User belum login atau UID tidak valid."
      return
    }
    if let msg = validate() {
      errorMessage = msg
      return
    }

    isSaving = true
    errorMessage = nil
    saveSuccess = false
    defer { isSaving = false }

    do {
      _ = try await SupabaseManager.shared.upsertUser(
        id: uuid,
        businessName: businessName,
        businessPhone: businessPhone,
        businessAddress: businessAddress,
        businessLogoUrl: businessLogoUrl,
        businessEmail: businessEmail,
        bankAccountNumber: bankAccountNumber,
        bankAccountName: bankAccountName,
        bankName: bankName
      )
       
      saveSuccess = true
    } catch {
      errorMessage = "Gagal menyimpan: \(error.localizedDescription)"
    }
  }
  
  // MARK: - Upload Logo
  func uploadLogo(from item: PhotosPickerItem?, setUploadingFlag: @escaping (Bool) -> Void) async {
      guard let item else { return }
      
      setUploadingFlag(true)
      defer { setUploadingFlag(false) }
      
      do {
          // 1. Load image data
          guard let imageData = try await item.loadTransferable(type: Data.self) else {
              errorMessage = "Gagal memuat foto"
              return
          }
          
          // 2. Compress image
          guard let uiImage = UIImage(data: imageData),
                let compressedData = uiImage.jpegData(compressionQuality: 0.7) else {
              errorMessage = "Gagal memproses foto"
              return
          }
          
          // 3. Generate nama file unik
          let fileName = "\(UUID().uuidString).jpg"
          let filePath = "business-logos/\(fileName)"
          
          // 4. Upload ke Supabase Storage
          let _ = try await SupabaseManager.shared.client.storage
              .from("MakroAppleTeam2_Bucket") // ⚠️ GANTI dengan nama bucket kamu
              .upload(
                  path: filePath,
                  file: compressedData,
                  options: FileOptions(contentType: "image/jpeg")
              )
          
          // 5. Generate public URL using the known path string
          let publicUrl = try SupabaseManager.shared.client.storage
              .from("MakroAppleTeam2_Bucket") // ⚠️ GANTI dengan nama bucket kamu
              .getPublicURL(path: filePath)
          
          // 6. Update businessLogoUrl
          await MainActor.run {
              self.businessLogoUrl = publicUrl.absoluteString
              self.saveSuccess = false
          }
          
          print("✅ Logo uploaded successfully:", publicUrl.absoluteString)
          
      } catch {
          await MainActor.run {
              self.errorMessage = "Gagal upload logo: \(error.localizedDescription)"
          }
      }
  }
}
