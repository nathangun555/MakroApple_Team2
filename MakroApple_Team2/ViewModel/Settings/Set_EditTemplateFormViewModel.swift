//
//  Set_TemplateFormViewModel.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 10/11/25.
//

import SwiftUI
import Foundation
import Observation

@Observable
@MainActor
class Set_EditTemplateFormViewModel {
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
            parseTemplate(templateDict)
        } catch {
            errorMessage = "Gagal memuat template: \(error.localizedDescription)"
        }
    }

    private func parseTemplate(_ dict: [String: AnyCodable]) {
        let customerKeys = ["Nama Pemesan", "No. Telp Pemesan", "Nama Penerima", "No. Telp Penerima", "Alamat Kirim"]
        let scheduleKeys = ["Tanggal Pesanan", "Jam Kirim"]
        let orderKeys = ["Pesanan", "Adds-on", "Wish / Greeting"]
        let otherKeys = ["Pengiriman: Kurir / Pickup", "Notes", "Foto Referensi (optional)"]

        customerFields.removeAll()
        scheduleFields.removeAll()
        orderFields.removeAll()
        otherFields.removeAll()

        for (key, anyValue) in dict {
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
            } else if otherKeys.contains(key) {
                otherFields.append(field)
            } else {
                otherFields.append(field)
            }
        }

        customerFields.sort { customerKeys.firstIndex(of: $0.label) ?? 999 < customerKeys.firstIndex(of: $1.label) ?? 999 }
        scheduleFields.sort { scheduleKeys.firstIndex(of: $0.label) ?? 999 < scheduleKeys.firstIndex(of: $1.label) ?? 999 }
        orderFields.sort { orderKeys.firstIndex(of: $0.label) ?? 999 < orderKeys.firstIndex(of: $1.label) ?? 999 }
    }

    func addCustomerField() { customerFields.append(FormFieldItem(label: "New Field", value: "")) }
    func addScheduleField() { scheduleFields.append(FormFieldItem(label: "New Field", value: "")) }
    func addOrderField() { orderFields.append(FormFieldItem(label: "New Field", value: "")) }
    func addOtherField() {
        otherFields.insert(FormFieldItem(label: "New Field", value: ""), at: 0)
    }

    func deleteOrderField(at index: Int) { orderFields.remove(at: index) }
    func deleteOtherField(at index: Int) { otherFields.remove(at: index) }

    func saveTemplate() async {
        guard let userId, let uuid = UUID(uuidString: userId) else {
            errorMessage = "User belum login atau UID tidak valid."
            return
        }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        var templateDict: [String: Any] = [:]

        for field in customerFields + scheduleFields + orderFields + otherFields {
            let label = field.label.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !label.isEmpty else { continue }

            if let data = field.value.data(using: .utf8),
               let array = try? JSONSerialization.jsonObject(with: data) as? [Any] {
                templateDict[label] = array
            } else {
                templateDict[label] = field.value
            }
        }

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

