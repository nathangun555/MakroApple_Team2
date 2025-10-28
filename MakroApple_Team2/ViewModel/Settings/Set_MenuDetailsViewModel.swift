//
//  Set_MenuDetailsViewModel.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 22/10/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class Set_MenuDetailsViewModel: ObservableObject {
  struct SectionModel: Identifiable {
    let id = UUID()
    var title: String
    var items: [EditableProduct]
    var isEditing: Bool = false
    var originalTitle: String // untuk tahu kategori lama
  }

  @Published var sections: [SectionModel] = []
  @Published var isLoading = false
  @Published var errorMessage: String?

  private(set) var userId: String?

  func configure(userId: String?) { self.userId = userId }

  func load() async {
    guard let userId, let uuid = UUID(uuidString: userId) else {
      errorMessage = "User belum login atau UID tidak valid."
      return
    }
    isLoading = true
    errorMessage = nil
    defer { isLoading = false }

    do {
      let products = try await SupabaseManager.shared.fetchProducts(for: uuid)
      let grouped = Dictionary(grouping: products) { (p: ProductRecord) -> String in
        p.productType ?? "Uncategorized"
      }

      let sortedKeys = grouped.keys.sorted { $0.lowercased() < $1.lowercased() }

      self.sections = sortedKeys.map { key in
        let items = grouped[key]!.map { EditableProduct(record: $0) }
        return SectionModel(title: key, items: items, isEditing: false, originalTitle: key)
      }

    } catch {
      errorMessage = "Gagal memuat produk: \(error.localizedDescription)"
    }
  }

  func toggleEdit(sectionIndex: Int) {
    for i in sections.indices {
      sections[i].isEditing = (i == sectionIndex) ? !sections[i].isEditing : false
    }
  }

  func saveAll() async {
    isLoading = true
    errorMessage = nil
    defer { isLoading = false }

    var toUpdate: [(EditableProduct, Int)] = []

    // Produk yang berubah (nama / harga / kategori)
    for sIndex in sections.indices {
      for item in sections[sIndex].items {
        if item.hasChanges {
          toUpdate.append((item, sIndex))
        }
      }
    }

    // Jika kategori berubah, update semua produk di section itu
    for sIndex in sections.indices {
      let section = sections[sIndex]
      if section.title != section.originalTitle {
        for item in section.items {
          var newItem = item
          newItem.productType = section.title
          toUpdate.append((newItem, sIndex))
        }
      }
    }

    // Jika tidak ada perubahan, keluar
    if toUpdate.isEmpty {
      for i in sections.indices { sections[i].isEditing = false }
      return
    }

    do {
      try await withThrowingTaskGroup(of: (UUID, ProductRecord).self) { group in
        for (ep, _) in toUpdate {
          group.addTask {
            let payload = await ep.changedFieldsPayload()
            // kalau payload kosong tapi category section berubah, tetap update
            var finalPayload = payload
            if finalPayload["product_type"] == nil {
                finalPayload["product_type"] = await ep.productType ?? NSNull()
            }

            let updated = try await SupabaseManager.shared.updateProduct(id: ep.id, values: finalPayload)
            return (ep.id, updated)
          }
        }

        var results: [UUID: ProductRecord] = [:]
        for try await (id, record) in group {
          results[id] = record
        }

        // Replace produk yang sudah diupdate
        for sIndex in sections.indices {
          for (idx, item) in sections[sIndex].items.enumerated() {
            if let newRecord = results[item.id] {
              sections[sIndex].items[idx] = EditableProduct(record: newRecord)
            }
          }
        }
      }

      // Reorganize ulang section berdasarkan kategori baru
      await reorganizeSections()

      for i in sections.indices { sections[i].isEditing = false }

    } catch {
      errorMessage = "Gagal menyimpan perubahan: \(error.localizedDescription)"
    }
  }

  private func reorganizeSections() async {
    let allProducts = sections.flatMap { $0.items }
    let grouped = Dictionary(grouping: allProducts) { (p: EditableProduct) -> String in
      p.productType ?? "Uncategorized"
    }
    let sortedKeys = grouped.keys.sorted { $0.lowercased() < $1.lowercased() }

    sections = sortedKeys.map { key in
      SectionModel(title: key, items: grouped[key]!, isEditing: false, originalTitle: key)
    }
  }
}
