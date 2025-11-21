import Foundation
import SwiftUI
import Combine

@MainActor
final class Set_MenuDetailsViewModel: ObservableObject {

    // Tetap simpan struktur Section agar kompatibel dengan logic lama (save/validasi)
    struct SectionModel: Identifiable {
        let id = UUID()
        var title: String
        var items: [EditableProduct]
        var isEditing: Bool = false
        var originalTitle: String
        var isDeleted: Bool = false
    }

    // Data + status existing
    @Published var sections: [SectionModel] = [] {
        didSet { detectChanges() }
    }
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasPendingChanges = false
    @Published var validationErrors: Set<String> = []   // UUID-based keys
    @Published var isLoadedFromScan: Bool = false

    // UI flat + search
    @Published var searchText: String = ""

    // Urutan stabil (id produk) agar tidak “loncat” saat validasi/typing
    @Published private(set) var flatOrder: [UUID] = []

    // Referensi pengguna
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
            // Ambil semua produk user
            let products = try await SupabaseManager.shared.fetchProducts(for: uuid)

            // Kelompokkan ke sections seperti semula agar kompatibel dengan save/validasi
            let grouped = Dictionary(grouping: products) { (p: ProductRecord) -> String in
                p.productType ?? "No Category"
            }
            let sortedKeys = grouped.keys.sorted { $0.lowercased() < $1.lowercased() }
            self.sections = sortedKeys.map { key in
                let items = grouped[key]!.map { EditableProduct(record: $0) }
                return SectionModel(
                    title: key,
                    items: items,
                    isEditing: true,        // Flat view tetap editable
                    originalTitle: key
                )
            }

            // Bangun urutan stabil sekali (A–Z) saat halaman dibuka
            buildStableOrder()

            hasPendingChanges = false
            validationErrors.removeAll()
            deletedProducts.removeAll()
            deletedCategories.removeAll()

        } catch {
            errorMessage = "Gagal memuat produk: \(error.localizedDescription)"
        }
    }

    // MARK: - Flat mapping untuk UI tanpa kategori

    struct FlatItemRef: Identifiable {
        let id: UUID
        let sectionIndex: Int
        let productIndex: Int
        let item: EditableProduct
    }

    // Semua item dengan indeks asli, agar delete/validasi tetap akurat
    var flatIndexMap: [FlatItemRef] {
        var refs: [FlatItemRef] = []
        for s in sections.indices {
            for p in sections[s].items.indices {
                let it = sections[s].items[p]
                refs.append(.init(id: it.id, sectionIndex: s, productIndex: p, item: it))
            }
        }
        return refs
    }

    // Urutkan stabil sekali saat load: A–Z by name → simpan IDnya
    private func buildStableOrder() {
        let all = sections.flatMap { $0.items }
        let sortedOnce = all.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        flatOrder = sortedOnce.map { $0.id }
    }

    // Koleksi tampil: ikuti flatOrder (stabil), lalu filter by search tanpa re-sort
    var visibleFlat: [FlatItemRef] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        // Buat map id->ref untuk lookup cepat
        let refMap = flatIndexMap.reduce(into: [UUID: FlatItemRef]()) { dict, ref in
            dict[ref.id] = ref
        }

        // Ikuti urutan stabil
        var ordered = flatOrder.compactMap { refMap[$0] }

        // Filter tanpa mengubah urutan
        if q.isEmpty { return ordered }
        return ordered.filter { $0.item.name.lowercased().contains(q) }
    }

    // MARK: - Validasi (UUID-based keys) — tidak diubah
    func validate() -> [String] {
        var keys: [String] = []

        for sIndex in sections.indices {
            let sec = sections[sIndex]

            // Kategori masih divalidasi agar kompatibel, UI menganggap "No Category"
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

    // MARK: - Deteksi Perubahan — tidak diubah
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

    // MARK: - Edit Mode (opsional)
    func toggleEdit(sectionIndex: Int) {
        for i in sections.indices {
            sections[i].isEditing = (i == sectionIndex) ? !sections[i].isEditing : false
        }
    }

    // MARK: - Tambah Produk Baru — default "No Category"
    func addTemporaryProductFlat() {
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
            productType: "No Category"
        )
        var new = EditableProduct(record: newRecord)
        new.isNew = true

        // Sisipkan ke section "No Category" (buat jika belum ada)
        if let idx = sections.firstIndex(where: { $0.title == "No Category" }) {
            sections[idx].items.insert(new, at: 0)
        } else {
            sections.insert(
                SectionModel(
                    title: "No Category",
                    items: [new],
                    isEditing: true,
                    originalTitle: "No Category"
                ),
                at: 0
            )
        }

        // Masukkan id baru pada posisi yang sesuai urutan A–Z awal: taruh di akhir agar stabil,
        // atau sisipkan pada posisi alfabet jika ingin, tapi hanya sekali ini.
        flatOrder.insert(new.id, at: 0)

        hasPendingChanges = true
    }

    // Versi lama tetap ada jika dipanggil dari UI lama
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
        flatOrder.insert(new.id, at: 0)
        hasPendingChanges = true
    }

    // MARK: - Tambah Kategori Baru (kompatibilitas)
    func addTemporaryCategory() {
        let newSection = SectionModel(
            title: "Nama Kategori",
            items: [],
            isEditing: true,
            originalTitle: "Nama Kategori"
        )
        sections.insert(newSection, at: 0)
        hasPendingChanges = true
    }

    // MARK: - Hapus Produk Sementara — tidak diubah
    func deleteTemporaryProduct(from sectionIndex: Int, at productIndex: Int) {
        guard sectionIndex < sections.count,
              productIndex < sections[sectionIndex].items.count else { return }

        let product = sections[sectionIndex].items[productIndex]

        // Bersihkan error untuk produk ini
        let pid = product.id
        validationErrors = validationErrors.filter { !$0.hasPrefix(pid.uuidString) }

        // Hapus dari urutan stabil juga
        flatOrder.removeAll { $0 == pid }

        deletedProducts.append(product)
        sections[sectionIndex].items.remove(at: productIndex)
        hasPendingChanges = true
    }

    // Non-breaking helper untuk delete by ID (dipakai Confirm)
    func deleteTemporaryProductById(_ id: UUID) {
        print("🧨 VM delete id =", id)
        // Bersihkan error terkait produk
        validationErrors = validationErrors.filter { !$0.hasPrefix(id.uuidString) }
        // Hapus dari urutan stabil visibleFlat
        flatOrder.removeAll { $0 == id }
        // Cari dan hapus dari sections
        for s in sections.indices {
            if let p = sections[s].items.firstIndex(where: { $0.id == id }) {
                let product = sections[s].items.remove(at: p)
                deletedProducts.append(product)
                hasPendingChanges = true
                return
            }
        }
        
    }

    
    // MARK: - Hapus Kategori Sementara — tidak diubah
    func deleteTemporaryCategory(at index: Int) {
        guard index < sections.count else { return }

        let category = sections[index]

        // Bersihkan error kategori + semua produk di dalamnya
        let sid = category.id
        var filtered = validationErrors.filter { !$0.hasPrefix(sid.uuidString) }
        for item in category.items {
            filtered = filtered.filter { !$0.hasPrefix(item.id.uuidString) }
            flatOrder.removeAll { $0 == item.id }
        }
        validationErrors = filtered

        deletedCategories.append(category)
        sections.remove(at: index)
        hasPendingChanges = true
    }

    // MARK: - Simpan Semua Perubahan — default kategori saat insert
    func saveAll(dismiss: @escaping () -> Void) async {
        // Validasi
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

        // Deteksi section title berubah (tetap ada meski UI flat)
        var sectionTitleChanged: Set<UUID> = []
        for sIndex in sections.indices {
            let sec = sections[sIndex]
            if sec.title != sec.originalTitle {
                sectionTitleChanged.insert(sec.id)
            }
        }

        // Kumpulkan insert / update
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

                // Insert — paksa default "No Category"
                for (ep, _) in toInsert {
                    group.addTask {
                        _ = try await SupabaseManager.shared.insertProduct(
                            name: ep.name,
                            price: Double(truncating: ep.price as NSNumber),
                            productType: "No Category",
                            userId: uuid
                        )
                    }
                }

                try await group.waitForAll()
            }

            // Reset tanpa re-sort
            deletedProducts.removeAll()
            deletedCategories.removeAll()
            // Jangan panggil reorganizeSections() agar urutan stabil tetap dipakai
            for i in sections.indices { sections[i].isEditing = true }

            await MainActor.run { dismiss() }

        } catch {
            print("❌ Error saving:", error)
            errorMessage = "Gagal menyimpan perubahan: \(error.localizedDescription)"
        }
    }

    // MARK: - Reorganize Sections (tidak dipakai di flow flat)
    private func reorganizeSections() async {
        let allProducts = sections.flatMap { $0.items }
        let grouped = Dictionary(grouping: allProducts) { (p: EditableProduct) -> String in
            p.productType ?? "No Category"
        }
        let sortedKeys = grouped.keys.sorted { $0.lowercased() < $1.lowercased() }
        sections = sortedKeys.map { key in
            SectionModel(
                title: key,
                items: grouped[key]!,
                isEditing: true,
                originalTitle: key
            )
        }
        // Setelah rebuild, bisa bangun ulang urutan stabil bila benar-benar perlu:
        buildStableOrder()
    }

    // MARK: - Load from Scanned Data — kompatibel (produk isNew)
    func loadFromScan(categories: [MenuCategory]) async {
        guard let userId, let uuid = UUID(uuidString: userId) else {
            errorMessage = "User belum login atau UID tidak valid."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        self.sections = categories.map { _ in
            // Semua hasil scan dipetakan ke "No Category" agar rata
            SectionModel(
                title: "No Category",
                items: [],
                isEditing: true,
                originalTitle: "No Category"
            )
        }

        // Flatten hasil scan → items isNew
        var items: [EditableProduct] = []
        for category in categories {
            for product in category.products {
                var editableProduct = EditableProduct(record: ProductRecord(
                    id: UUID(),
                    userId: uuid,
                    name: product.name,
                    price: Decimal(product.price),
                    notes: product.notes,
                    isActive: true,
                    createdAt: nil,
                    updatedAt: nil,
                    productType: "No Category"
                ))
                editableProduct.isNew = true
                items.append(editableProduct)
            }
        }

        // Taruh semua item di satu section "No Category"
        if sections.isEmpty {
            sections = [SectionModel(title: "No Category", items: items, isEditing: true, originalTitle: "No Category")]
        } else {
            sections[0].items = items
        }

        // Bangun urutan stabil sekali
        buildStableOrder()

        isLoadedFromScan = true
        hasPendingChanges = true
        validationErrors.removeAll()
        deletedProducts.removeAll()
        deletedCategories.removeAll()

        print("✅ Loaded \(sections.count) sections with \(sections.flatMap { $0.items }.count) products from scan")
    }
}

// MARK: - EditableProductRow (tidak berubah dari versi sebelumnya)

enum EditableProductField: Hashable {
    case price
}

struct EditableProductRow: View {
    @ObservedObject var viewModel: EditableProduct
    @FocusState private var focusedField: EditableProductField?
    var isEditing: Bool
    var sectionIndex: Int
    var productIndex: Int
    var validationErrors: Set<String>
    var onChanged: () -> Void = {}

    
    private let sentinelPlaceholders: Set<String> = ["Silakan Isi Nama Produk", "ZZZ"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // MARK: Nama Produk
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top, spacing: 8) {
                    Text("Nama Produk :")
                        .font(.subheadline)
                        .frame(width: 110, alignment: .leading)
                        .padding(.top, 2)

                    AutoGrowingTextEditor(
                        text: Binding(
                            get: { viewModel.name },
                            set: { newValue in
                                let collapsed = newValue.replacingOccurrences(of: "\\s{3,}", with: "  ", options: .regularExpression)
                                let maxChars = 70
                                var clipped = String(collapsed.prefix(maxChars))
                                if clipped.contains("\n\n") {
                                    clipped = clipped.replacingOccurrences(of: "\n\n+", with: "\n", options: .regularExpression)
                                }
                                viewModel.name = clipped
                                onChanged()
                            }
                        ),
                        placeholder: "Silakan Isi Nama Produk",
                        isEditing: isEditing,
                        font: .system(size: 16, weight: .regular),  // samakan
                        lineHeight: 18,
                        verticalPadding: 6,
                        maxChars: 70,
                        cornerRadius: 8,
                        borderColor: .black,
                        borderWidth: 1
                    )
                    .opacity(isEditing ? 1 : 0.7)
                }

                if validationErrors.contains("\(viewModel.id.uuidString)-name") {
                    HStack(spacing: 6) {
                        Color.clear.frame(width: 110)
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 12, weight: .bold))
                            Text("Lengkapi untuk melanjutkan")
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
                        Text("Rp").foregroundColor(.black)
                            .font(.system(size: 16, weight: .regular))
                        TextField(
                            "0",
                            text: Binding(
                                get: {
                                    let intValue = NSDecimalNumber(decimal: viewModel.price).intValue
                                    if intValue == 0 { return "" }
                                    return isEditing ? String(intValue) : IDRFormat.string(from: intValue)
                                },
                                set: { newValue in
                                    let digits = newValue.filter { $0.isNumber }
                                    let maxDigits = 12
                                    let limited = String(digits.prefix(maxDigits))
                                    if limited.isEmpty {
                                        viewModel.price = 0
                                    } else if let dec = Decimal(string: limited) {
                                        viewModel.price = dec
                                    }
                                    onChanged()
                                }
                            )
                        )
                        .keyboardType(.numberPad)
                        .disabled(!isEditing)
                        .font(.system(size: 16, weight: .regular))
                        .monospacedDigit()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .focused($focusedField, equals: .price)
                        .doneToolbar(isFocused: $focusedField)
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

                if validationErrors.contains("\(viewModel.id.uuidString)-price") {
                    HStack(spacing: 6) {
                        Color.clear.frame(width: 110)
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 12, weight: .bold))
                            Text("Lengkapi untuk melanjutkan")
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
        .background(.deadlineCard)
            .cornerRadius(10)
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
