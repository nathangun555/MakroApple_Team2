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
  
  @Published var fieldErrors: [String: String] = [:]
  @Published var hasChanges = false  // ✅ Track changes
  
  // ✅ Store original data
  private var originalData: (
    businessName: String,
    businessPhone: String,
    businessAddress: String,
    businessLogoUrl: String,
    businessEmail: String,
    bankAccountNumber: String,
    bankAccountName: String,
    bankName: String
  )?

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
        
        // ✅ Simpan original data
        originalData = (
          businessName: businessName,
          businessPhone: businessPhone,
          businessAddress: businessAddress,
          businessLogoUrl: businessLogoUrl,
          businessEmail: businessEmail,
          bankAccountNumber: bankAccountNumber,
          bankAccountName: bankAccountName,
          bankName: bankName
        )
        
        hasChanges = false
      }
    } catch {
      errorMessage = "Gagal memuat data: \(error.localizedDescription)"
    }
  }

  // ✅ Check if data changed
  func checkForChanges() {
    guard let original = originalData else {
      hasChanges = false
      return
    }
    
    hasChanges = businessName != original.businessName ||
                 businessPhone != original.businessPhone ||
                 businessAddress != original.businessAddress ||
                 businessLogoUrl != original.businessLogoUrl ||
                 businessEmail != original.businessEmail ||
                 bankAccountNumber != original.bankAccountNumber ||
                 bankAccountName != original.bankAccountName ||
                 bankName != original.bankName
  }

  func validateAllFields() -> Bool {
    fieldErrors.removeAll()
    
    if businessName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      fieldErrors["businessName"] = "Lengkapi untuk melanjutkan."
    }
    
    if businessAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      fieldErrors["businessAddress"] = "Lengkapi untuk melanjutkan."
    }
    
    if businessPhone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      fieldErrors["businessPhone"] = "Lengkapi untuk melanjutkan."
    }
    
    if businessEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      fieldErrors["businessEmail"] = "Lengkapi untuk melanjutkan."
    } else {
      let pattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
      if businessEmail.range(of: pattern, options: [.regularExpression, .caseInsensitive]) == nil {
        fieldErrors["businessEmail"] = "Lengkapi untuk melanjutkan."
      }
    }
    
    if bankAccountName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      fieldErrors["bankAccountName"] = "Lengkapi untuk melanjutkan."
    }
    
    if bankAccountNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      fieldErrors["bankAccountNumber"] = "Lengkapi untuk melanjutkan."
    }
    
    if bankName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      fieldErrors["bankName"] = "Lengkapi untuk melanjutkan."
    }
    
    return fieldErrors.isEmpty
  }

  func save() async {
    guard let userId, let uuid = UUID(uuidString: userId) else {
      errorMessage = "User belum login atau UID tidak valid."
      return
    }
    
    fieldErrors.removeAll()
    let isValid = validateAllFields()
    
    guard isValid else {
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
      hasChanges = false  // ✅ Reset setelah save
      
      // ✅ Update original data
      originalData = (
        businessName: businessName,
        businessPhone: businessPhone,
        businessAddress: businessAddress,
        businessLogoUrl: businessLogoUrl,
        businessEmail: businessEmail,
        bankAccountNumber: bankAccountNumber,
        bankAccountName: bankAccountName,
        bankName: bankName
      )
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
          guard let imageData = try await item.loadTransferable(type: Data.self) else {
              errorMessage = "Gagal memuat foto"
              return
          }
          
          guard let uiImage = UIImage(data: imageData),
                let compressedData = uiImage.jpegData(compressionQuality: 0.7) else {
              errorMessage = "Gagal memproses foto"
              return
          }
          
          let fileName = "\(UUID().uuidString).jpg"
          let filePath = "business-logos/\(fileName)"
          
          let _ = try await SupabaseManager.shared.client.storage
              .from("MakroAppleTeam2_Bucket")
              .upload(
                  path: filePath,
                  file: compressedData,
                  options: FileOptions(contentType: "image/jpeg")
              )
          
          let publicUrl = try SupabaseManager.shared.client.storage
              .from("MakroAppleTeam2_Bucket")
              .getPublicURL(path: filePath)
          
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
