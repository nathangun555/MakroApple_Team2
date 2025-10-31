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
        var originalTitle: String
    }

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
            createdAt: nil, // ⚠️ penting: biarkan nil agar bisa dikenali sebagai produk baru
            updatedAt: nil,
            productType: sections[sectionIndex].title
        )
        var new = EditableProduct(record: newRecord)
        new.isNew = true // ✅ tandai produk ini baru
        sections[sectionIndex].items.insert(new, at: 0)
    }
    
    // MARK: - Tambah Kategori Baru (belum tersimpan)
    func addTemporaryCategory() {
        // Buat section baru dengan 1 produk kosong di dalamnya
        let newSection = SectionModel(
            title: "Nama Kategori",
            items: [
                {
                    guard let userUUID = UUID(uuidString: userId ?? "") else {
                        return EditableProduct(record: ProductRecord(
                            id: UUID(),
                            userId: UUID(),
                            name: "Silakan Isi Nama Produk",
                            price: 0,
                            notes: nil,
                            isActive: true,
                            createdAt: nil,
                            updatedAt: nil,
                            productType: "Nama Kategori"
                        ))
                    }
                    var newProduct = EditableProduct(record: ProductRecord(
                        id: UUID(),
                        userId: userUUID,
                        name: "Silakan Isi Nama Produk",
                        price: 0,
                        notes: nil,
                        isActive: true,
                        createdAt: nil,
                        updatedAt: nil,
                        productType: "Nama Kategori"
                    ))
                    newProduct.isNew = true
                    return newProduct
                }()
            ],
            isEditing: true,
            originalTitle: "Nama Kategori"
        )

        // Insert di urutan paling atas
        sections.insert(newSection, at: 0)
    }


    // MARK: - Simpan Semua Perubahan (insert + update)
    // MARK: - Simpan Semua Perubahan (insert + update) — FIXED kategori-propagation
    func saveAll() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard let userId, let uuid = UUID(uuidString: userId) else {
            errorMessage = "User belum login."
            return
        }

        // MARK: - 1) Hitung section yang title-nya berubah
        var sectionTitleChanged: Set<UUID> = []
        for sIndex in sections.indices {
            let sec = sections[sIndex]
            if sec.title != sec.originalTitle {
                sectionTitleChanged.insert(sec.id)
            }
        }

        // MARK: - 2) Kumpulkan toInsert & toUpdate, dan pastikan productType sinkron dengan section title
        var toInsert: [(EditableProduct, Int)] = []
        var toUpdate: [(EditableProduct, Int)] = []

        for sIndex in sections.indices {
            let secTitle = sections[sIndex].title

            for item in sections[sIndex].items {
                // make a mutable copy to adjust productType if needed
                var mutableItem = item

                // If the section title changed, ensure the product's productType is updated to the new title
                if sectionTitleChanged.contains(sections[sIndex].id) {
                    // update the editable product's productType so payload will carry new category
                    mutableItem.productType = secTitle
                }

                if mutableItem.isNew {
                    toInsert.append((mutableItem, sIndex))
                } else if mutableItem.hasChanges || sectionTitleChanged.contains(sections[sIndex].id) {
                    // existing item changed OR its section category changed -> update
                    toUpdate.append((mutableItem, sIndex))
                }
            }
        }

        // MARK: - 3) Nothing to do?
        guard !toInsert.isEmpty || !toUpdate.isEmpty else {
            for i in sections.indices { sections[i].isEditing = false }
            return
        }

        // MARK: - 4) Execute (parallel)
        do {
            try await withThrowingTaskGroup(of: (UUID, ProductRecord).self) { group in
                // Updates
                for (ep, _) in toUpdate {
                    group.addTask {
                        var payload = await ep.changedFieldsPayload()
                        // ensure product_type included if not present
                        if payload["product_type"] == nil {
                            payload["product_type"] = await ep.productType ?? NSNull()
                        }
                        let updated = try await SupabaseManager.shared.updateProduct(id: ep.id, values: payload)
                        return (ep.id, updated)
                    }
                }

                // Inserts
                for (ep, _) in toInsert {
                    group.addTask {
                        let inserted = try await SupabaseManager.shared.insertProduct(
                            name: ep.name,
                            price: Double(truncating: ep.price as NSNumber),
                            productType: ep.productType ?? "Uncategorized",
                            userId: uuid
                        )
                        return (inserted.id, inserted)
                    }
                }

                // Collect results (use DB id as key)
                var results: [UUID: ProductRecord] = [:]
                for try await (_, record) in group {
                    results[record.id] = record
                }

                // MARK: - 5) Apply results to local state
                for sIndex in sections.indices {
                    for (idx, item) in sections[sIndex].items.enumerated() {
                        // If DB returned a record with same local id (rare), use it
                        if let newRecordById = results[item.id] {
                            sections[sIndex].items[idx] = EditableProduct(record: newRecordById)
                            continue
                        }

                        // Otherwise try match by name+price for newly inserted items
                        if item.isNew {
                            if let match = results.values.first(where: {
                                $0.name == item.name &&
                                $0.price == Decimal(Double(truncating: item.price as NSNumber))
                            }) {
                                var updatedEditable = EditableProduct(record: match)
                                updatedEditable.isNew = false
                                sections[sIndex].items[idx] = updatedEditable
                            }
                        } else {
                            // For existing items that had their section title changed but didn't get matched by id (edge cases),
                            // attempt to update their productType locally to reflect new section title.
                            if sectionTitleChanged.contains(sections[sIndex].id) {
                                // update productType locally to keep UI consistent
                                let current = sections[sIndex].items[idx]
                                current.productType = sections[sIndex].title
                            }
                        }
                    }
                }
            }

            // MARK: - 6) Reorganize & exit edit mode
            await reorganizeSections()
            for i in sections.indices { sections[i].isEditing = false }

        } catch {
            print("❌ Error detail:", error)
            if let decodingError = error as? DecodingError {
                print("🧩 DecodingError:", decodingError)
            }
            errorMessage = "Gagal menyimpan perubahan: \(error.localizedDescription)"
        }
    }



    // MARK: - Reorganize Sections
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
