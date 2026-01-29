//
//  EditOrderViewModel.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 30/10/25.
//

import SwiftUI
import Foundation
import Observation

// MARK: - Models
struct ProductItem: Identifiable {
    var id: UUID
    var name: String
    var quantity: Int
    var productPrice: Decimal
    var discount: Decimal
    var productType: String
    var createdAt: String
    var updatedAt: String
    
    init(id: UUID = UUID(), name: String = "", quantity: Int = 0, productPrice: Decimal = 0, discount: Decimal = 0, productType: String = "", createdAt: String = "", updatedAt: String = "") {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.productPrice = productPrice
        self.discount = discount
        self.productType = productType
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var subtotal: Decimal {
        productPrice * Decimal(quantity)
    }
    
    var subtotalAfterDiscount: Decimal {
        subtotal - discount
    }
}

struct AddOnItem: Identifiable, Codable {
    let id = UUID()
    var name: String
    var quantity: Int
}

@Observable
@MainActor
class EditOrderViewModel {
    
    var customerFields: [OrderField] = []
    var scheduleFields: [OrderField] = []
    var products: [ProductItem] = []
    var addOns: [AddOnItem] = []
    var otherFields: [OrderField] = []
    
    var selectedPhotos: [UIImage] = []
    var uploadedPhotoURLs: [String] = []
    var isUploadingPhotos = false
    
    var isLoading = false
    var didSave = false
    var errorMessage: String?
    var fieldErrors: Set<String> = []
    
    var orderIdNow: String?
    
    private(set) var userId: String?
    private var originalParsedData: [String: Any] = [:]
    
    // MARK: - Invoice-related properties (from ConfirmInvoiceViewModel)
    var userRecord: UserRecord?
    var orderRecord: OrderRecord?
    var orderItems: [OrderItemRecord] = []
    
    var invoiceNumber: String = ""
    var invoiceDate: String = ""
    var invoiceDueDate: String? = nil
    var shippingCostText: String = ""
    var downPaymentText: String = ""
    
    var hasInvalidProduct: Bool {
        for p in products {
            if p.quantity == 0 || p.productPrice == 0 {
                return true
            }
        }
        return false
    }
    
    var totalProductSubtotal: Decimal {
        products.reduce(0) { $0 + $1.subtotal - $1.discount }
    }

    var shippingCost: Decimal {
        Decimal(string: shippingCostText) ?? 0
    }

    var total: Decimal {
        totalProductSubtotal + (Decimal(string: shippingCostText) ?? 0)
    }
    
    var totalAfterDiscount: Decimal {
        let subtotalAfterDiscount = products.reduce(Decimal(0)) { $0 + $1.subtotalAfterDiscount }
        return subtotalAfterDiscount + shippingCost
    }
    
    var downPayment: Decimal {
        Decimal(string: downPaymentText) ?? 0
    }
    
    func configure(userId: String?, parsedOrderData: [String: Any], selectedPhotos: [UIImage] = []) {
        print("parsedOrderData: \(parsedOrderData)")
        self.userId = userId
        self.originalParsedData = parsedOrderData
        self.selectedPhotos = selectedPhotos
        
        if customerFields.isEmpty {
            parseIntoSections(parsedOrderData)
            
            // Setelah parsing, langsung coba auto-match produk ke katalog menu
            if let userId, let uuid = UUID(uuidString: userId), !products.isEmpty {
                Task {
                    await self.autoMapOrderedItemsToMenu(orderedItems: self.products, for: uuid)
                }
            }
        }
    }
    
    private func parseIntoSections(_ data: [String: Any]) {
        var processedKeys: Set<String> = []
        
        // 1. Customer fields
        let customerKeys = ["Nama Pemesan", "No. Telp Pemesan", "Nama Penerima", "No. Telp Penerima", "Alamat Kirim"]
        for key in customerKeys {
            if let value = data[key] as? String {
                customerFields.append(OrderField(label: "\(key)", value: value))
                processedKeys.insert(key)
            }
        }
        
        // 2. Schedule fields
        let scheduleKeys = ["Tanggal Pesanan", "Jam Kirim"]
        for key in scheduleKeys {
            if let value = data[key] as? String {
                scheduleFields.append(OrderField(label: "\(key)", value: value))
                processedKeys.insert(key)
            }
        }
        
        // 3. Products
        if let pesananValue = data["Pesanan"] {
            let pesananArray = JSONStringArrayParse(pesananValue)
            products = pesananArray.compactMap { item in
                guard let name = item["item"] as? String, !name.isEmpty else { return nil }
                let qty = item["quantity"] as? Int ?? 1
                let nowString = ISO8601DateFormatter().string(from: Date())
                return ProductItem(
                    name: name,
                    quantity: qty,
                    productPrice: 0,
                    discount: 0,
                    productType: "",
                    createdAt: nowString,
                    updatedAt: nowString
                )
            }
            processedKeys.insert("Pesanan")
        }
        if products.isEmpty {
            let nowString = ISO8601DateFormatter().string(from: Date())
            products.append(ProductItem(name: "", quantity: 0, createdAt: nowString, updatedAt: nowString))
        }

//        // 4. Add-ons
//        if let addonsValue = data["Adds-on"] {
//            let addOnsArray = JSONStringArrayParse(addonsValue)
//            addOns = addOnsArray.compactMap { item in
//                guard let name = item["item"] as? String, !name.isEmpty else { return nil }
//                let qty = item["quantity"] as? Int ?? 1
//                return AddOnItem(name: name, quantity: qty)
//            }
//            processedKeys.insert("Adds-on")
//        }
//        if addOns.isEmpty {
//            addOns.append(AddOnItem(name: "", quantity: 0))
//        }

        // 5. Add ALL remaining fields to otherFields
        for (key, value) in data {
            // Skip if already processed
            if processedKeys.contains(key) {
                continue
            }
            
            let stringValue: String
            if let str = value as? String {
                stringValue = str
            } else if value is NSNull {
                stringValue = ""
            } else if let dict = value as? [String: Any] {
                continue
            } else if let array = value as? [Any] {
                continue
            } else {
                stringValue = "\(value)"
            }
        
            otherFields.append(OrderField(label: "\(key)", value: stringValue))
        }
        
        if let savedOrder = data["_other_order"] as? [String] {
            otherFields.sort { a, b in
                let aIndex = savedOrder.firstIndex(of: a.label) ?? 999
                let bIndex = savedOrder.firstIndex(of: b.label) ?? 999
                return aIndex < bIndex
            }
        }
        
        // 6. Apply saved ordering for otherFields if exists
        print("📋 Parsed Order Data:")
        print("  Customer fields: \(customerFields.count)")
        print("  Schedule fields: \(scheduleFields.count)")
        print("  Products: \(products.count)")
        print("  Add-ons: \(addOns.count)")
        print("  Other fields: \(otherFields.count)")
        if !otherFields.isEmpty {
            print("  Other field keys: \(otherFields.map { $0.label })")
        }
    }
    
    // MARK: - Product add and delete
    func addProduct() {
        let nowString = ISO8601DateFormatter().string(from: Date())
        products.append(ProductItem(name: "", quantity: 0, createdAt: nowString, updatedAt: nowString))
    }
    
    func deleteProduct(at index: Int) {
        guard products.count > 1 else { return }
        products.remove(at: index)
    }
    
    // MARK: - Add-On add and delete
    func addAddOn() {
        addOns.append(AddOnItem(name: "", quantity: 0))
    }
    
    func deleteAddOn(at index: Int) {
        guard addOns.count > 1 else { return }
        addOns.remove(at: index)
    }
    
    // MARK: - Save Order
    func saveOrder(photos: [UIImage]) async -> OrderRecord? {
        guard let userId, let uuid = UUID(uuidString: userId) else {
            errorMessage = "User belum login"
            return nil
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            uploadedPhotoURLs = []
            if !photos.isEmpty {
                isUploadingPhotos = true
                for photo in photos {
                    if let tempURL = saveImageToTemp(photo) {
                        let photoURL = try await SupabaseManager.shared.uploadFile(
                            tempURL,
                            folder: "order-references"
                        )
                        uploadedPhotoURLs.append(photoURL)
                        print("✅ Photo uploaded: \(photoURL)")
                    }
                }
                isUploadingPhotos = false
            }
            
            let orderData = buildOrderData()
            
            var order: OrderRecord
            
            print("🔵 Saving order...")
            
            if let orderId = orderIdNow {
                try await SupabaseManager.shared.deleteOrderItems(for: UUID(uuidString: orderId)!)
                try await SupabaseManager.shared.deleteOrder(for: UUID(uuidString: orderId)!)
            }
            order = try await SupabaseManager.shared.createOrder(
                orderId: "",
                userId: uuid,
                parsedOrder: orderData,
                photoURLs: uploadedPhotoURLs
            )
            
            orderIdNow = order.id.uuidString
            print("✅ Order saved: \(order.id)")
            print(order)
            
            // Create order items with pricing information
            let nowString = ISO8601DateFormatter().string(from: Date())
            let orderItemsToCreate = products.filter { !$0.name.isEmpty }.map { product in
                OrderItemRecord(
                    id: UUID(),
                    orderId: order.id,
                    productId: UUID(),
                    productName: product.name,
                    productPrice: product.productPrice,
                    productType: product.productType,
                    productDiscount: product.discount,
                    quantity: product.quantity,
                    subtotal: product.subtotalAfterDiscount,
                    createdAt: nowString,
                    updatedAt: nowString
                )
            }
            
            if !orderItemsToCreate.isEmpty {
                let createdItems = try await SupabaseManager.shared.updateOrderItems(
                    id: order.id,
                    order: orderItemsToCreate
                )
                print("✅ Order items created count: \(createdItems.count)")
                self.orderItems = createdItems
            }
            
            // Set invoice details
            self.invoiceNumber = order.orderNumber
            let now = Date()
            self.invoiceDate = DateFormatterHelper.isoDateString(from: now)
            if invoiceDueDate == nil {
                let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
                self.invoiceDueDate = DateFormatterHelper.formatIndonesianDate(tomorrow)
            }
            
            // Update order with invoice details (subtotal, shipping, total)
            // Note: downPayment will be saved later when user confirms
            let shippingCost = Decimal(string: shippingCostText) ?? 0
            let _ = try await SupabaseManager.shared.updateOrder(
                orderId: order.id,
                invoiceDueDate: invoiceDueDate,
                subtotal: totalProductSubtotal,
                shippingCost: shippingCost,
                totalAmount: totalAfterDiscount,
                discountAmount: 0,
                downPayment: nil
            )
            
            return order
        } catch {
            print("❌ Error saving: \(error)")
            errorMessage = error.localizedDescription
            return nil
        }
    }

    private func saveImageToTemp(_ image: UIImage) -> URL? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let tempDir = FileManager.default.temporaryDirectory
        let filename = UUID().uuidString + ".jpg"
        let fileURL = tempDir.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("❌ Error saving temp image: \(error)")
            return nil
        }
    }

    
    private func buildOrderData() -> [String: Any] {
        var data: [String: Any] = [:]
        
        // Customer fields
        for field in customerFields {
            let key = field.label.trimmingCharacters(in: .whitespaces)
            data[key] = field.value
        }
        
        // Schedule fields
        for field in scheduleFields {
            let key = field.label.trimmingCharacters(in: .whitespaces)
            data[key] = field.value

        }
        
        // Products
        let productsArray = products.filter { !$0.name.isEmpty }.map { product in
            [
//                "category": product.category,
                "item": product.name,
                "quantity": product.quantity
            ] as [String: Any]
        }
        data["Pesanan"] = productsArray
        
        // Add-ons
        let addOnsArray = addOns.filter { !$0.name.isEmpty }.map { addOn in
            [
                "item": addOn.name,
                "quantity": addOn.quantity
            ] as [String: Any]
        }
        data["Adds-on"] = addOnsArray
        
        // Other fields (including all unmapped fields)
        for field in otherFields {
            let key = field.label.trimmingCharacters(in: .whitespaces)
            data[key] = field.value
        }
        
        return data
    }
    
    func JSONStringArrayParse(_ raw: Any?) -> [[String: Any]] {
        if let arr = raw as? [[String: Any]] { return arr }
        if let arr = raw as? [[Any]], let first = arr.first as? [[String: Any]] { return first }
        if let arr = raw as? [[Any]] {
            return arr.flatMap { $0 as? [[String: Any]] ?? [] }
        }
        if let arr = raw as? [Any], let dictArr = arr as? [[String: Any]] { return dictArr }
        return []
    }
    
    func validateAllFields() -> Bool {
            fieldErrors.removeAll()
            
            // 1. Validate customer fields
            for (index, field) in customerFields.enumerated() {
                if field.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    fieldErrors.insert("customer-\(index)")
                }
            }
            
            // 2. Validate schedule fields
            for (index, field) in scheduleFields.enumerated() {
                let key = "schedule-\(index)"
                
                if isOptionalField(field.label) { continue }
                
                if field.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    fieldErrors.insert(key)
                }
            }
            
            // 3. Validate products
            for (index, product) in products.enumerated() {
                if product.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    fieldErrors.insert("product-\(index)-name")
                }
                if product.quantity <= 0 {
                    fieldErrors.insert("product-\(index)-quantity")
                }
            }
            
            // 4. Validate add-ons (optional - bisa diisi atau tidak)
            // Skip validation untuk add-ons jika mau optional
            
            // 5. Validate other fields
            for (index, field) in otherFields.enumerated() {
                if field.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    fieldErrors.insert("other-\(index)")
                }
            }
            
            return fieldErrors.isEmpty
        }
    
    // MARK: - Invoice-related methods (from ConfirmInvoiceViewModel)
    func fetchOrderAndItems(orderId: UUID) async {
        do {
            if let userIdString = userId, let userUUID = UUID(uuidString: userIdString) {
                if let user = try await SupabaseManager.shared.fetchUser(by: userUUID) {
                    self.userRecord = user
                    let order = try await SupabaseManager.shared.fetchOrder(id: orderId)
                    let items = try await SupabaseManager.shared.fetchOrderItem(orderId: orderId)
                    
                    self.orderRecord = order
                    self.orderItems = items
                    
                    await fillFromOrder(order: order, items: items, user: user)
                } else {
                    errorMessage = "User not found"
                }
            }
        } catch {
            print("❌ Error fetching order or items: \(error)")
            errorMessage = "Failed to fetch order: \(error.localizedDescription)"
        }
    }
    
    func fillFromOrder(order: OrderRecord, items: [OrderItemRecord], user: UserRecord) async {
        self.orderRecord = order
        self.invoiceNumber = order.orderNumber
        
        let now = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        
        self.invoiceDate = DateFormatterHelper.isoDateString(from: now)
        self.invoiceDueDate = order.invoiceDueDate ?? DateFormatterHelper.formatIndonesianDate(now)
        
        self.shippingCostText = order.shippingCost.formatted()
        self.downPaymentText = order.downPayment?.formatted() ?? "0"
        self.orderItems = items
        
        // Convert OrderItemRecord to ProductItem
        let tempProducts: [ProductItem] = items.map { item in
            ProductItem(
                id: item.id,
                name: item.productName,
                quantity: item.quantity,
                productPrice: item.productPrice,
                discount: item.productDiscount,
                productType: item.productType,
                createdAt: item.createdAt ?? "",
                updatedAt: item.updatedAt ?? ""
            )
        }
        
        if let userId, let uuid = UUID(uuidString: userId) {
            await autoMapOrderedItemsToMenu(orderedItems: tempProducts, for: uuid)
        } else {
            self.products = tempProducts
        }
    }
    
    func autoMapOrderedItemsToMenu(
        orderedItems: [ProductItem],
        for userId: UUID
    ) async {
        do {
            let menuProducts = try await SupabaseManager.shared.fetchProducts(for: userId)

            let mappedProducts: [ProductItem] = orderedItems.map { ordered in
                if let matchingMenu = bestMatch(for: ordered.name, in: menuProducts) {
                    return ProductItem(
                        id: ordered.id,
                        name: matchingMenu.name,
                        quantity: ordered.quantity,
                        productPrice: matchingMenu.price,
                        discount: ordered.discount,
                        productType: matchingMenu.productType ?? "",
                        createdAt: ordered.createdAt,
                        updatedAt: ordered.updatedAt
                    )
                } else {
                    print("No match for '\(ordered.name)'")
                    return ordered
                }
            }
            self.products = mappedProducts
        } catch {
            print("❌ Error fetching products or mapping:", error)
            self.errorMessage = "Failed to fetch menu/match products"
        }
    }
    
    private func bestMatch(for orderedName: String, in menu: [ProductRecord]) -> ProductRecord? {
        let orderedNorm = orderedName.normalizedForMenuMatch()
        let orderedWords = Set(orderedNorm.split(separator: " ").map { String($0) })
        
        // 1. Exact, normalized
        if let exact = menu.first(where: { $0.name.normalizedForMenuMatch() == orderedNorm }) {
            return exact
        }
        // 2. Contains all ordered keywords
        if let allKeyWords = menu.first(where: {
            let nameNorm = $0.name.normalizedForMenuMatch()
            let menuWords = Set(nameNorm.split(separator: " ").map { String($0) })
            return orderedWords.isSubset(of: menuWords)
        }) {
            return allKeyWords
        }
        // 3. Ordered phrase in menu name substring
        if let contains = menu.first(where: { $0.name.normalizedForMenuMatch().contains(orderedNorm) }) {
            return contains
        }
        // 4. Menu keywords in ordered name (for short menu names)
        if let revContains = menu.first(where: {
            let nameNorm = $0.name.normalizedForMenuMatch()
            let menuWords = Set(nameNorm.split(separator: " ").map { String($0) })
            return menuWords.isSubset(of: orderedWords)
        }) {
            return revContains
        }
        // 5. Ordered name in menu keywords substring
        if let contains2 = menu.first(where: { orderedNorm.contains($0.name.normalizedForMenuMatch()) }) {
            return contains2
        }
        // 6. Fuzzy fallback
        let sorted = menu.sorted {
            levenshtein($0.name.normalizedForMenuMatch(), orderedNorm)
            < levenshtein($1.name.normalizedForMenuMatch(), orderedNorm)
        }
        if let best = sorted.first, levenshtein(best.name.normalizedForMenuMatch(), orderedNorm) <= 7 {
            return best
        }
        return nil
    }
    
    func makeOrderItemRecordsForSave() -> [OrderItemRecord] {
        guard let orderIdString = orderIdNow,
              let orderUUID = UUID(uuidString: orderIdString) else {
            return []
        }
        return products.map { p in
            OrderItemRecord(
                id: p.id,
                orderId: orderUUID,
                productId: UUID(),
                productName: p.name,
                productPrice: p.productPrice,
                productType: p.productType,
                productDiscount: p.discount,
                quantity: p.quantity,
                subtotal: p.subtotalAfterDiscount,
                createdAt: p.createdAt,
                updatedAt: ISO8601DateFormatter().string(from: Date())
            )
        }
    }
    
    func saveProductItems() async throws {
        guard let orderIdString = orderIdNow,
              let orderUUID = UUID(uuidString: orderIdString) else {
            errorMessage = "Order ID tidak valid."
            return
        }
        
        let itemsToSave = makeOrderItemRecordsForSave()
        
        do {
            let updatedRecord = try await SupabaseManager.shared.updateOrderItems(
                id: orderUUID,
                order: itemsToSave
            )
            self.orderItems = updatedRecord
            self.errorMessage = nil
        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func saveOrderDetails(hasDownPayment: Bool) async throws {
        guard let orderIdString = orderIdNow,
              let orderUUID = UUID(uuidString: orderIdString) else {
            errorMessage = "Order ID tidak valid."
            return
        }
        
        let shippingCost = Decimal(string: shippingCostText) ?? 0
        let finalDownPayment = hasDownPayment ? downPayment : 0
        
        let updatedOrder = try await SupabaseManager.shared.updateOrder(
            orderId: orderUUID,
            invoiceDueDate: invoiceDueDate,
            subtotal: totalProductSubtotal,
            shippingCost: shippingCost,
            totalAmount: totalAfterDiscount,
            downPayment: finalDownPayment
        )
        self.orderRecord = updatedOrder
    }
    
    func deleteCurrentOrder() async {
        guard let orderIdString = orderIdNow,
              let orderUUID = UUID(uuidString: orderIdString) else {
            errorMessage = "Order ID tidak valid."
            return
        }

        do {
            try await SupabaseManager.shared.deleteOrderCompletely(orderId: orderUUID)
            print("🧽 Order successfully cleaned up")
        } catch {
            errorMessage = "Gagal menghapus order: \(error.localizedDescription)"
            print("❌ Delete error:", error)
        }
    }
}

extension String {
    func normalizedForMenuMatch() -> String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9 ]", with: "", options: .regularExpression)
    }
}

func levenshtein(_ aStr: String, _ bStr: String) -> Int {
    let a = Array(aStr)
    let b = Array(bStr)
    var dist = Array(repeating: Array(repeating: 0, count: b.count + 1), count: a.count + 1)
    for i in 0...a.count { dist[i][0] = i }
    for j in 0...b.count { dist[0][j] = j }
    for i in 1...a.count {
        for j in 1...b.count {
            if a[i-1] == b[j-1] {
                dist[i][j] = dist[i-1][j-1]
            } else {
                dist[i][j] = min(dist[i-1][j] + 1, dist[i][j-1] + 1, dist[i-1][j-1] + 1)
            }
        }
    }
    return dist[a.count][b.count]
}
