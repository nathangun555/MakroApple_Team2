
//
//  Set_MenuDetailsViewModel.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 22/10/25.
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
        var originalTitle: String
        var pendingDelete: Bool = false // ✅ kategori bisa ditandai delete
    }
    private var deletedCategoryTitles: Set<String> = []
    @Published var sections: [SectionModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private(set) var userId: String?

    func configure(userId: String?) { self.userId = userId }

    // MARK: - Load Data
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

    // MARK: - Toggle Edit Mode
    func toggleEdit(sectionIndex: Int) {
        for i in sections.indices {
            sections[i].isEditing = (i == sectionIndex) ? !sections[i].isEditing : false
        }
    }

    // MARK: - Tambah Produk Baru
    func addTemporaryProduct(to sectionIndex: Int) {
        guard let userUUID = UUID(uuidString: userId ?? "") else { return }
        let newRecord = ProductRecord(
            id: UUID(),
            userId: userUUID,
            name: "Silakan Isi Nama Produk",
            price: 0,
            notes: nil,
            isActive: true,
            createdAt: nil,
            updatedAt: nil,
            productType: sections[sectionIndex].title
        )
        var new = EditableProduct(record: newRecord)
        new.isNew = true
        sections[sectionIndex].items.insert(new, at: 0)
    }

    // MARK: - Tambah Kategori Baru
    func addTemporaryCategory() {
        let newSection = SectionModel(
            title: "Nama Kategori",
            items: [],
            isEditing: true,
            originalTitle: "Nama Kategori"
        )
        sections.insert(newSection, at: 0)
    }

    // MARK: - Delete Produk
    func markProductDeleted(sectionIndex: Int, productId: UUID) {
        sections[sectionIndex].items.removeAll { $0.id == productId }
    }

    // MARK: - Delete Seluruh Kategori
   func markCategoryDeleted(sectionIndex: Int) {
    let title = sections[sectionIndex].title
    deletedCategoryTitles.insert(title)
    // tandai item di kategori ini ikut terhapus di server
    for i in sections[sectionIndex].items.indices {
      sections[sectionIndex].items[i].pendingDelete = true
    }
    // hilangkan dari UI
    sections.remove(at: sectionIndex)
  }

    // MARK: - Simpan Semua Perubahan
    func saveAll() async {
    isLoading = true
    errorMessage = nil
    defer { isLoading = false }

    guard let userId, let uuid = UUID(uuidString: userId) else {
      errorMessage = "User belum login."
      return
    }

    // Flatten semua produk yang tersisa (kategori terhapus sudah di-remove dari sections)
    let allProducts = sections.flatMap { $0.items }

    var toInsert: [EditableProduct] = []
    var toUpdate: [EditableProduct] = []
    var toDelete: [EditableProduct] = []

    for product in allProducts {
      if product.pendingDelete { toDelete.append(product); continue }
      if product.isNew { toInsert.append(product) }
      else if product.hasChanges { toUpdate.append(product) }
    }

    do {
      // 1) Delete semua produk milik kategori yang dihapus
      for cat in deletedCategoryTitles {
        try await SupabaseManager.shared.deleteProductsByCategory(userId: uuid, productType: cat)
      }

      // 2) Delete produk yang ditandai pendingDelete
      for del in toDelete {
        try await SupabaseManager.shared.deleteProduct(id: del.id)
      }

      // 3) Update produk yang berubah
      for upd in toUpdate {
        var payload = upd.changedFieldsPayload()
        if payload["product_type"] == nil, let t = upd.productType { payload["product_type"] = t }
        _ = try await SupabaseManager.shared.updateProduct(id: upd.id, values: payload)
      }

      // 4) Insert produk baru
      for newP in toInsert {
        _ = try await SupabaseManager.shared.insertProduct(
          name: newP.name,
          price: Double(truncating: newP.price as NSNumber),
          productType: newP.productType ?? "Uncategorized",
          userId: uuid
        )
      }

      // 5) Kosongkan daftar kategori terhapus dan reload
      deletedCategoryTitles.removeAll()
      await load()

    } catch {
      errorMessage = "Gagal menyimpan perubahan: \(error.localizedDescription)"
    }
  }

}
