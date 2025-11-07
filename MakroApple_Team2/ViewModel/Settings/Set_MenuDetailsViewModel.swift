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
        var isDeleted: Bool = false
    }

    @Published var sections: [SectionModel] = [] {
        didSet { detectChanges() }
    }
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasPendingChanges = false
    @Published var validationErrors: Set<String> = [] // ✅ untuk tracking field error
    @Published var isLoadedFromScan: Bool = false

    private(set) var userId: String?
    private var deletedProducts: [EditableProduct] = []
    private var deletedCategories: [SectionModel] = []

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
                return SectionModel(
                    title: key,
                    items: items,
                    isEditing: false,
                    originalTitle: key
                )
            }

            hasPendingChanges = false
            validationErrors.removeAll()
            deletedProducts.removeAll()
            deletedCategories.removeAll()

        } catch {
            errorMessage = "Gagal memuat produk: \(error.localizedDescription)"
        }
    }

    // MARK: - Validasi
    func validate() -> [(sectionIndex: Int, productIndex: Int?, field: String)] {
        var errors: [(Int, Int?, String)] = []
        
        for sIndex in sections.indices {
            let sec = sections[sIndex]
            
            // Validasi nama kategori
            let catName = sec.title.trimmingCharacters(in: .whitespacesAndNewlines)
            if catName.isEmpty || ["Nama Kategori", "ZZZ", "Silakan isi nama kategori"].contains(catName) {
                errors.append((sIndex, nil, "category"))
            }
            
            // Validasi tiap produk
            for pIndex in sec.items.indices {
                let item = sec.items[pIndex]
                let prodName = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if prodName.isEmpty || ["Silakan Isi Nama Produk", "ZZZ"].contains(prodName) {
                    errors.append((sIndex, pIndex, "name"))
                }
                
                if item.price <= 0 {
                    errors.append((sIndex, pIndex, "price"))
                }
            }
        }
        
        return errors
    }

    // MARK: - Deteksi Perubahan
    private func detectChanges() {
        Task { @MainActor in
            for section in sections {
                if section.title != section.originalTitle {
                    hasPendingChanges = true
                    return
                }
                for item in section.items {
                    if item.isNew || item.hasChanges {
                        hasPendingChanges = true
                        return
                    }
                }
            }
            if !deletedProducts.isEmpty || !deletedCategories.isEmpty {
                hasPendingChanges = true
                return
            }
            hasPendingChanges = false
        }
    }

    func markChanged() {
        hasPendingChanges = true
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
        hasPendingChanges = true
    }

    // MARK: - Tambah Kategori Baru
    func addTemporaryCategory() {
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

        sections.insert(newSection, at: 0)
        hasPendingChanges = true
    }

    // MARK: - Hapus Produk Sementara
    func deleteTemporaryProduct(from sectionIndex: Int, at productIndex: Int) {
        guard sectionIndex < sections.count,
              productIndex < sections[sectionIndex].items.count else { return }

        let product = sections[sectionIndex].items[productIndex]
        deletedProducts.append(product)
        sections[sectionIndex].items.remove(at: productIndex)
        hasPendingChanges = true
    }

    // MARK: - Hapus Kategori Sementara
    func deleteTemporaryCategory(at index: Int) {
        guard index < sections.count else { return }

        let category = sections[index]
        deletedCategories.append(category)
        sections.remove(at: index)
        hasPendingChanges = true
    }

    // MARK: - Simpan Semua Perubahan
    func saveAll(dismiss: @escaping () -> Void) async {
        // ✅ Validasi dulu
        let errors = validate()
        if !errors.isEmpty {
            validationErrors = Set(errors.map { err in
                if let pIndex = err.productIndex {
                    return "\(err.sectionIndex)-\(pIndex)-\(err.field)"
                } else {
                    return "\(err.sectionIndex)-cat"
                }
            })
            return // Jangan lanjut simpan
        }
        
        validationErrors.removeAll() // Clear kalau valid
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard let userId, let uuid = UUID(uuidString: userId) else {
            errorMessage = "User belum login."
            return
        }

        // 🔹 1) Simpan perubahan kategori yg berubah title
        var sectionTitleChanged: Set<UUID> = []
        for sIndex in sections.indices {
            let sec = sections[sIndex]
            if sec.title != sec.originalTitle {
                sectionTitleChanged.insert(sec.id)
            }
        }

        // 🔹 2) Kumpulkan data insert / update
        var toInsert: [(EditableProduct, Int)] = []
        var toUpdate: [(EditableProduct, Int)] = []

        for sIndex in sections.indices {
            let secTitle = sections[sIndex].title
            for item in sections[sIndex].items {
                var mutableItem = item
                if sectionTitleChanged.contains(sections[sIndex].id) {
                    mutableItem.productType = secTitle
                }

                if mutableItem.isNew {
                    toInsert.append((mutableItem, sIndex))
                } else if mutableItem.hasChanges || sectionTitleChanged.contains(sections[sIndex].id) {
                    toUpdate.append((mutableItem, sIndex))
                }
            }
        }

        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                // 🔹 Delete kategori
                for category in deletedCategories {
                    for item in category.items where !item.isNew {
                        group.addTask {
                            try await SupabaseManager.shared.deleteProduct(id: item.id)
                        }
                    }
                }

                // 🔹 Delete produk
                for item in deletedProducts where !item.isNew {
                    group.addTask {
                        try await SupabaseManager.shared.deleteProduct(id: item.id)
                    }
                }

                // 🔹 Update
                for (ep, _) in toUpdate {
                    group.addTask {
                        var payload = await ep.changedFieldsPayload()
                        if payload["product_type"] == nil {
                            payload["product_type"] = await ep.productType ?? NSNull()
                        }
                        _ = try await SupabaseManager.shared.updateProduct(id: ep.id, values: payload)
                    }
                }

                // 🔹 Insert
                for (ep, _) in toInsert {
                    group.addTask {
                        _ = try await SupabaseManager.shared.insertProduct(
                            name: ep.name,
                            price: Double(truncating: ep.price as NSNumber),
                            productType: ep.productType ?? "Uncategorized",
                            userId: uuid
                        )
                    }
                }

                try await group.waitForAll()
            }

            // 🔹 3) Reset
            deletedProducts.removeAll()
            deletedCategories.removeAll()
            await reorganizeSections()
            for i in sections.indices { sections[i].isEditing = false }

            // 🔹 4) Setelah semua sukses → kembali ke SettingsView
            await MainActor.run {
                dismiss()
            }

        } catch {
            print("❌ Error saving:", error)
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
            SectionModel(
                title: key,
                items: grouped[key]!,
                isEditing: false,
                originalTitle: key
            )
        }
    }
    
    // MARK: - Load from Scanned Data
    func loadFromScan(categories: [MenuCategory]) async {
        guard let userId, let uuid = UUID(uuidString: userId) else {
            errorMessage = "User belum login atau UID tidak valid."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        self.sections = categories.map { category in
            let items = category.products.map { product in
                var editableProduct = EditableProduct(record: ProductRecord(
                    id: UUID(),
                    userId: uuid,
                    name: product.name,
                    price: Decimal(product.price),
                    notes: product.notes,
                    isActive: true,
                    createdAt: nil,
                    updatedAt: nil,
                    productType: product.productType
                ))
                editableProduct.isNew = true
                return editableProduct
            }
            
            return SectionModel(
                title: category.categoryName,
                items: items,
                isEditing: false,
                originalTitle: category.categoryName
            )
        }
        
        isLoadedFromScan = true
        hasPendingChanges = true
        validationErrors.removeAll()
        deletedProducts.removeAll()
        deletedCategories.removeAll()
        
        print("✅ Loaded \(sections.count) categories with \(sections.flatMap { $0.items }.count) products from scan")
    }

}
