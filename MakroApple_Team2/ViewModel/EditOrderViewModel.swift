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
    let id = UUID()
    var category: String
    var name: String
    var quantity: Int
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
    
    private(set) var userId: String?
    private var originalParsedData: [String: Any] = [:]
    
    func configure(userId: String?, parsedOrderData: [String: Any], selectedPhotos: [UIImage] = []) {
        print("parsedOrderData: \(parsedOrderData)")
        self.userId = userId
        self.originalParsedData = parsedOrderData
        self.selectedPhotos = selectedPhotos
        parseIntoSections(parsedOrderData)
    }
    
    private func parseIntoSections(_ data: [String: Any]) {
        var processedKeys: Set<String> = []
        
        // 1. Customer fields
        let customerKeys = ["Nama Pemesan", "No. Telp Pemesan", "No Telp Pemesan", "Nama Penerima", "No. Telp Penerima", "No Telp Penerima", "Alamat Kirim"]
        for key in customerKeys {
            if let value = data[key] as? String {
                customerFields.append(OrderField(label: "\(key) :", value: value))
                processedKeys.insert(key)
            }
        }
        
        // 2. Schedule fields
        let scheduleKeys = ["Tanggal Pesanan", "Jam Kirim"]
        for key in scheduleKeys {
            if let value = data[key] as? String {
                scheduleFields.append(OrderField(label: "\(key) :", value: value))
                processedKeys.insert(key)
            }
        }
        
        // 3. Products
        if let pesananValue = data["Pesanan"] {
            let pesananArray = JSONStringArrayParse(pesananValue)
            products = pesananArray.compactMap { item in
                guard let name = item["item"] as? String, !name.isEmpty else { return nil }
                let qty = item["quantity"] as? Int ?? 1
                return ProductItem(
                    category: item["category"] as? String ?? "Classic Cake",
                    name: name,
                    quantity: qty
                )
            }
            processedKeys.insert("Pesanan")
        }
        if products.isEmpty {
            products.append(ProductItem(category: "", name: "", quantity: 0))
        }

        // 4. Add-ons
        if let addonsValue = data["Adds-on"] {
            let addOnsArray = JSONStringArrayParse(addonsValue)
            addOns = addOnsArray.compactMap { item in
                guard let name = item["item"] as? String, !name.isEmpty else { return nil }
                let qty = item["quantity"] as? Int ?? 1
                return AddOnItem(name: name, quantity: qty)
            }
            processedKeys.insert("Adds-on")
        }
        if addOns.isEmpty {
            addOns.append(AddOnItem(name: "", quantity: 0))
        }

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
        
            otherFields.append(OrderField(label: "\(key):", value: stringValue))
        }
        
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
        products.append(ProductItem(category: "", name: "", quantity: 0))
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
            
            print("🔵 Saving order...")
            let order = try await SupabaseManager.shared.createOrder(
                userId: uuid,
                parsedOrder: orderData,
                photoURLs: uploadedPhotoURLs
            )
            
            print("✅ Order saved: \(order.id)")
            
            let orderItems = try await SupabaseManager.shared.createOrderItems(
                products: self.products,
                orderId: order.id
            )
            print("✅ Order items created count: \(orderItems.count)")
            
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
            let key = field.label.replacingOccurrences(of: " :", with: "").trimmingCharacters(in: .whitespaces)
            data[key] = field.value
        }
        
        // Schedule fields
        for field in scheduleFields {
            let key = field.label.replacingOccurrences(of: " :", with: "").trimmingCharacters(in: .whitespaces)
            data[key] = field.value
        }
        
        // Products
        let productsArray = products.filter { !$0.name.isEmpty }.map { product in
            [
                "category": product.category,
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
            let key = field.label.replacingOccurrences(of: ":", with: "").trimmingCharacters(in: .whitespaces)
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
                if field.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    fieldErrors.insert("schedule-\(index)")
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
}
