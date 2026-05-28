//
//  EditTemplateFormViewModel.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 23/10/25.
//

import SwiftUI
import Foundation
import Observation

@Observable
@MainActor
class EditTemplateViewModel {
    var customerFields: [FormFieldItem] = []
    var scheduleFields: [FormFieldItem] = []
    var orderFields: [FormFieldItem] = []
    var otherFields: [FormFieldItem] = []
    
    var isLoading = false
    var isSaving = false
    var errorMessage: String?
    var didSave = false
    
    private(set) var userId: String?
    
    func configure(userId: String?) {
        self.userId = userId
    }
    
    func loadTemplate() async {
        guard let userId, let uuid = UUID(uuidString: userId) else {
            errorMessage = "User belum login atau UID tidak valid."
            return
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            guard let userRecord = try await SupabaseManager.shared.fetchUser(by: uuid),
                  let templateDict = userRecord.templateFormat else {
                errorMessage = "Template tidak ditemukan"
                return
            }
            
            if customerFields.isEmpty {
                parseTemplate(templateDict)
            }
            
        } catch {
            errorMessage = "Gagal memuat template: \(error.localizedDescription)"
        }
    }
    
    
    
    // MARK: - Parse Template
    private func parseTemplate(_ dict: [String: AnyCodable]) {
        let customerKeys = ["Nama Pemesan", "No. Telp Pemesan", "Nama Penerima", "No. Telp Penerima", "Alamat Kirim"]
        let scheduleKeys = ["Tanggal Pesanan", "Jam Kirim"]
        let orderKeys = ["Pesanan"]
        
        // Load saved order for "other fields"
        let savedOrder = (dict["_other_order"]?.value as? [String]) ?? []
        
        var tempOther: [FormFieldItem] = []
        
        for (key, anyValue) in dict {
            if key == "_other_order" { continue } // metadata, skip
            
            let stringValue: String
            if let str = anyValue.value as? String {
                stringValue = str
            } else if let arr = anyValue.value as? [Any] {
                stringValue = "\(arr)"
            } else {
                stringValue = "\(anyValue.value)"
            }
            
            let field = FormFieldItem(label: key, value: stringValue)
            
            if customerKeys.contains(key) {
                customerFields.append(field)
            } else if scheduleKeys.contains(key) {
                scheduleFields.append(field)
            } else if orderKeys.contains(key) {
                orderFields.append(field)
            } else {
                tempOther.append(field)
            }
        }
        
        // FIXED: customer/schedule/order keep sorted
        customerFields.sort { customerKeys.firstIndex(of: $0.label)! < customerKeys.firstIndex(of: $1.label)! }
        scheduleFields.sort { scheduleKeys.firstIndex(of: $0.label)! < scheduleKeys.firstIndex(of: $1.label)! }
        orderFields.sort { orderKeys.firstIndex(of: $0.label)! < orderKeys.firstIndex(of: $1.label)! }
        
        // Option B: otherFields are purely user-defined order
        if !savedOrder.isEmpty {
            otherFields = tempOther.sorted {
                (savedOrder.firstIndex(of: $0.label) ?? 999) <
                (savedOrder.firstIndex(of: $1.label) ?? 999)
            }
        } else {
            // First-time user → preserve Supabase order as-is (NO SORTING)
            otherFields = tempOther
        }
    }
    
    
    // MARK: - Field Modification
    func addCustomerField() { customerFields.append(FormFieldItem(label: "New Field", value: "")) }
    func addScheduleField() { scheduleFields.append(FormFieldItem(label: "New Field", value: "")) }
    func addOrderField() { orderFields.append(FormFieldItem(label: "New Field", value: "")) }
    func addOtherField() {
        otherFields.insert(FormFieldItem(label: "New Field", value: ""), at: 0)
    }
    
    func deleteOrderField(at index: Int) { orderFields.remove(at: index) }
    func deleteOtherField(at index: Int) { otherFields.remove(at: index) }
    
    
    // MARK: - Save Template
    func saveTemplate() async {
        guard let userId, let uuid = UUID(uuidString: userId) else {
            errorMessage = "User belum login atau UID tidak valid."
            return
        }
        
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        
        var templateDict: [String: Any] = [:]
        
        // Save all fields normally
        for field in customerFields + scheduleFields + orderFields + otherFields {
            let key = field.label.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty else { continue }
            
            if let data = field.value.data(using: .utf8),
               let array = try? JSONSerialization.jsonObject(with: data) as? [Any] {
                templateDict[key] = array
            } else {
                templateDict[key] = field.value
            }
        }
        
        // 🔥 SAVE the user-defined order for otherFields
        templateDict["_other_order"] = otherFields.map { $0.label }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: templateDict),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            errorMessage = "Gagal mengkonversi template"
            return
        }
        
        do {
            _ = try await SupabaseManager.shared.upsertFormTemplate(
                id: uuid,
                formTemplate: jsonString
            )
            didSave = true
        } catch {
            errorMessage = "Gagal menyimpan: \(error.localizedDescription)"
        }
    }
}


// MARK: - Data Model
struct FormFieldItem: Identifiable, Hashable {
    let id = UUID()
    var label: String
    var value: String
}
