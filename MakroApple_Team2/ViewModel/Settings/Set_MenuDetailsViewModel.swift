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
    // UUID-based keys, e.g. "<productID>-name", "<productID>-price", "<sectionID>-cat"
    @Published var validationErrors: Set<String> = []
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

    // MARK: - Validasi (UUID-based keys)
    func validate() -> [String] {
        var keys: [String] = []

        for sIndex in sections.indices {
            let sec = sections[sIndex]

            // Kategori
            let catName = sec.title.trimmingCharacters(in: .whitespacesAndNewlines)
            if catName.isEmpty || ["Nama Kategori", "ZZZ", "Silakan isi nama kategori"].contains(catName) {
                keys.append("\(sec.id.uuidString)-cat")
            }

            // Produk
            for pIndex in sec.items.indices {
                let item = sec.items[pIndex]
                let prodName = item.name.trimmingCharacters(in: .whitespacesAndNewlines)

                if prodName.isEmpty || ["Silakan Isi Nama Produk", "ZZZ"].contains(prodName) {
                    keys.append("\(item.id.uuidString)-name")
                }
                if item.price <= 0 {
                    keys.append("\(item.id.uuidString)-price")
                }
            }
        }

        return keys
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
            name: "",
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
                            name: "",
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
                        name: "",
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

    // MARK: - Hapus Produk Sementara (bersihkan error by UUID)
    func deleteTemporaryProduct(from sectionIndex: Int, at productIndex: Int) {
        guard sectionIndex < sections.count,
              productIndex < sections[sectionIndex].items.count else { return }

        let product = sections[sectionIndex].items[productIndex]

        // Bersihkan error untuk produk ini
        let pid = product.id
        validationErrors = validationErrors.filter { !$0.hasPrefix(pid.uuidString) }

        deletedProducts.append(product)
        sections[sectionIndex].items.remove(at: productIndex)
        hasPendingChanges = true
    }

    // MARK: - Hapus Kategori Sementara (bersihkan error by UUID)
    func deleteTemporaryCategory(at index: Int) {
        guard index < sections.count else { return }

        let category = sections[index]

        // Bersihkan error kategori + semua produk di dalamnya
        let sid = category.id
        var filtered = validationErrors.filter { !$0.hasPrefix(sid.uuidString) }
        for item in category.items {
            filtered = filtered.filter { !$0.hasPrefix(item.id.uuidString) }
        }
        validationErrors = filtered

        deletedCategories.append(category)
        sections.remove(at: index)
        hasPendingChanges = true
    }

    // MARK: - Simpan Semua Perubahan
    func saveAll(dismiss: @escaping () -> Void) async {
        // Validasi (UUID-based keys)
        let errorKeys = validate()
        if !errorKeys.isEmpty {
            validationErrors = Set(errorKeys)
            return
        }

        validationErrors.removeAll()

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard let userId, let uuid = UUID(uuidString: userId) else {
            errorMessage = "User belum login."
            return
        }

        // 1) Deteksi kategori yang berubah title
        var sectionTitleChanged: Set<UUID> = []
        for sIndex in sections.indices {
            let sec = sections[sIndex]
            if sec.title != sec.originalTitle {
                sectionTitleChanged.insert(sec.id)
            }
        }

        // 2) Kumpulkan insert / update
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
                // Delete kategori
                for category in deletedCategories {
                    for item in category.items where !item.isNew {
                        group.addTask {
                            try await SupabaseManager.shared.deleteProduct(id: item.id)
                        }
                    }
                }

                // Delete produk
                for item in deletedProducts where !item.isNew {
                    group.addTask {
                        try await SupabaseManager.shared.deleteProduct(id: item.id)
                    }
                }

                // Update
                for (ep, _) in toUpdate {
                    group.addTask {
                        var payload = await ep.changedFieldsPayload()
                        if payload["product_type"] == nil {
                            payload["product_type"] = await ep.productType ?? NSNull()
                        }
                        _ = try await SupabaseManager.shared.updateProduct(id: ep.id, values: payload)
                    }
                }

                // Insert
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

            // 3) Reset
            deletedProducts.removeAll()
            deletedCategories.removeAll()
            await reorganizeSections()
            for i in sections.indices { sections[i].isEditing = false }

            // 4) Kembali
            await MainActor.run { dismiss() }

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

// MARK: - EditableProductRow
struct EditableProductRow: View {
    @ObservedObject var viewModel: EditableProduct
    var isEditing: Bool
    var sectionIndex: Int
    var productIndex: Int
    var validationErrors: Set<String>

    private let sentinelPlaceholders: Set<String> = [
        "Silakan Isi Nama Produk",
        "ZZZ"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // MARK: Nama Produk
            VStack(alignment: .leading, spacing: 4) {
                let font = Font.system(size: 16)
                let lineHeight: CGFloat = 20
                let vPad: CGFloat = 4
                let oneRow: CGFloat = lineHeight + vPad * 2
                let twoRows: CGFloat = lineHeight * 2 + vPad * 2

                HStack(alignment: .top, spacing: 8) {
                    Text("Nama Produk :")
                        .font(.subheadline)
                        .frame(width: 110, alignment: .leading)
                        .padding(.top, 2)

                    ZStack(alignment: .topLeading) {
                        if viewModel.name.isEmpty {
                            Text("Silakan Isi Nama Produk")
                                .font(font)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 8)
                                .padding(.vertical, vPad)
                                .allowsHitTesting(false)
                        }

                        TextEditor(text: Binding(
                            get: { viewModel.name },
                            set: { newValue in
                                let collapsed = newValue.replacingOccurrences(
                                    of: "\\s{3,}",
                                    with: "  ",
                                    options: .regularExpression
                                )
                                let maxChars = 70
                                var clipped = String(collapsed.prefix(maxChars))
                                if clipped.contains("\n\n") {
                                    clipped = clipped.replacingOccurrences(
                                        of: "\n\n+",
                                        with: "\n",
                                        options: .regularExpression
                                    )
                                }
                                viewModel.name = clipped
                            }
                        ))
                        .font(font)
                        .disabled(!isEditing)
                        .padding(.horizontal, 8)
                        .padding(.vertical, vPad)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.words)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .frame(minHeight: oneRow, maxHeight: twoRows, alignment: .top)
                        .onAppear {
                            UITextView.appearance().textContainerInset = .zero
                            UITextView.appearance().textContainer.lineFragmentPadding = 0
                            DispatchQueue.main.async { viewModel.objectWillChange.send() }
                        }
                    }
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.black, lineWidth: 1)
                            .allowsHitTesting(false)
                    )
                    .cornerRadius(8)
                    .opacity(isEditing ? 1 : 0.7)
                }

                // UUID-based error
                if validationErrors.contains("\(viewModel.id.uuidString)-name") {
                    HStack(spacing: 6) {
                            Color.clear.frame(width: 110) // offset label kiri "Nama Produk :"
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 12, weight: .bold))
                                Text("Nama produk harus diisi")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                        }
                }
            }

            // MARK: Harga Produk
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center) {
                    Text("Harga Produk :")
                        .font(.subheadline)
                        .frame(width: 110, alignment: .leading)

                    HStack(spacing: 4) {
                        Text("Rp")
                            .foregroundColor(.black)
                        TextField(
                            "0",
                            text: Binding(
                                get: {
                                    let intValue = NSDecimalNumber(decimal: viewModel.price).intValue
                                    if intValue == 0 { return "" }
                                    // Saat edit: tampilkan angka polos tanpa titik
                                    if isEditing {
                                        return String(intValue)
                                    } else {
                                        // Saat tidak edit: tampilkan terformat
                                        return IDRFormat.string(from: intValue)
                                    }
                                },
                                set: { newValue in
                                    // Setter tetap simpan digit murni + maxDigits
                                    let digits = newValue.filter { $0.isNumber }
                                    let maxDigits = 12
                                    let limited = String(digits.prefix(maxDigits))
                                    if limited.isEmpty {
                                        viewModel.price = 0
                                    } else if let dec = Decimal(string: limited) {
                                        viewModel.price = dec
                                    }
                                }
                            )
                        )
//                        TextField(
//                            "0",
//                            text: Binding(
//                                get: {
//                                    let intValue = NSDecimalNumber(decimal: viewModel.price).intValue
//                                    return intValue == 0 ? "" : IDRFormat.string(from: intValue) // mis. "1.000.000"
//                                },
//                                set: { newValue in
//                                    // Ambil digit saja dari input/hasil paste
//                                    let digits = newValue.filter { $0.isNumber }
//
//                                    // Batasi total digit seperti aturan lama
//                                    let maxDigits = 12
//                                    let limited = String(digits.prefix(maxDigits))
//
//                                    // Simpan ke model sebagai Decimal murni (tanpa titik)
//                                    if limited.isEmpty {
//                                        viewModel.price = 0
//                                    } else if let dec = Decimal(string: limited) {
//                                        viewModel.price = dec
//                                    }
//                                    // Tidak ada else-fallback: biarkan nilai lama jika parsing gagal
//                                }
//                            )
//                        )
                        .keyboardType(.numberPad)
                        .disabled(!isEditing)
                        .font(.system(size: 16))
                        .monospacedDigit()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.black, lineWidth: 1)
                            .allowsHitTesting(false)
                    )
                    .cornerRadius(8)
                    .frame(maxWidth: .infinity)
                    .opacity(isEditing ? 1 : 0.7)
                }
                

                // UUID-based error
                if validationErrors.contains("\(viewModel.id.uuidString)-price") {
                    HStack(spacing: 6) {
                            Color.clear.frame(width: 110) // offset label kiri "Harga Produk :"
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 12, weight: .bold))
                                Text("Harga harus lebih dari 0")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                        }
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        .frame(maxWidth: .infinity)
    }
}

extension NumberFormatter {
    static func currencyFormatter() -> NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "IDR"
        f.maximumFractionDigits = 0
        return f
    }
}
