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

struct AddOnItem: Identifiable {
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
    
    var isLoading = false
    var didSave = false
    var errorMessage: String?
    
    private(set) var userId: String?
    private var originalParsedData: [String: Any] = [:]
    
    func configure(parsedOrderData: [String: Any]) {
        self.originalParsedData = parsedOrderData
        
        // Parse the data into sections
        parseIntoSections(parsedOrderData)
    }
    
    private func parseIntoSections(_ data: [String: Any]) {
        // Track which keys have been processed
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
            var jsonString: String? = nil
            
            if let array = pesananValue as? [Any], let firstItem = array.first as? String {
                jsonString = firstItem
            }
            else if let str = pesananValue as? String {
                jsonString = str
            }
            
            if var jsonString = jsonString {
                print("🔵 Pesanan string: \(jsonString.prefix(100))...")
                
                if jsonString.hasPrefix("[[") && jsonString.hasSuffix("]]") {
                    jsonString.removeFirst()  // Remove first [
                    jsonString.removeLast()   // Remove last ]
                }
                
                print("✅ Cleaned: \(jsonString.prefix(100))...")
                
                if let jsonData = jsonString.data(using: .utf8) {
                    do {
                        if let pesananArray = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] {
                            products = pesananArray.compactMap { item in
                                guard let name = item["item"] as? String, !name.isEmpty else { return nil }
                                let qty = item["quantity"] as? Int ?? 1
                                return ProductItem(
                                    category: item["category"] as? String ?? "Classic Cake",
                                    name: name,
                                    quantity: qty
                                )
                            }
                            print("✅ Products parsed: \(products.count)")
                        }
                    } catch {
                        print("❌ JSON error: \(error)")
                        print("   String was: \(jsonString)")
                    }
                }
            }
            processedKeys.insert("Pesanan")
        }
        if products.isEmpty {
            products.append(ProductItem(category: "", name: "", quantity: 0))
        }

        // 4. Add-ons
        if let addonsValue = data["Adds-on"] {
            var jsonString: String? = nil
            
            if let array = addonsValue as? [Any], let firstItem = array.first as? String {
                jsonString = firstItem
            }
            else if let str = addonsValue as? String {
                jsonString = str
            }
            
            if var jsonString = jsonString {
                print("🔵 Adds-on string: \(jsonString.prefix(100))...")
                
                if jsonString.hasPrefix("[[") && jsonString.hasSuffix("]]") {
                    jsonString.removeFirst()
                    jsonString.removeLast()
                }
                
                print("✅ Cleaned: \(jsonString.prefix(100))...")
                
                if let jsonData = jsonString.data(using: .utf8) {
                    do {
                        if let addonsArray = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] {
                            addOns = addonsArray.compactMap { item in
                                guard let name = item["item"] as? String, !name.isEmpty else { return nil }
                                let qty = item["quantity"] as? Int ?? 1
                                return AddOnItem(name: name, quantity: qty)
                            }
                            print("✅ Add-ons parsed: \(addOns.count)")
                        }
                    } catch {
                        print("❌ JSON error: \(error)")
                        print("   String was: \(jsonString)")
                    }
                }
            }
            processedKeys.insert("Adds-on")
        }
        if addOns.isEmpty {
            addOns.append(AddOnItem(name: "", quantity: 0))
        }

        
//        // ✅ 5. Photo references
//        let photoKeys = ["Foto Referensi (optional)", "Foto Referensi", "Photo Reference"]
//        for key in photoKeys {
//            if let photoData = data[key] {
//                photoReferences[key] = photoData
//                processedKeys.insert(key)
//            }
//        }
        
        // 6. Add ALL remaining fields to otherFields
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
    
    // MARK: - Product Management
    func addProduct() {
        products.append(ProductItem(category: "", name: "", quantity: 0))
    }
    
    func deleteProduct(at index: Int) {
        guard products.count > 1 else { return }
        products.remove(at: index)
    }
    
    // MARK: - Add-On Management
    func addAddOn() {
        addOns.append(AddOnItem(name: "", quantity: 0))
    }
    
    func deleteAddOn(at index: Int) {
        guard addOns.count > 1 else { return }
        addOns.remove(at: index)
    }
    
    // MARK: - Save Order
    func saveOrder() async {
//        guard let userId, let uuid = UUID(uuidString: userId) else {
//            errorMessage = "User belum login"
//            return
//        }
//        
//        isLoading = true
//        defer { isLoading = false }
//        
//        do {
//            // Build updated order data
//            let orderData = buildOrderData()
//            
//            print("🔵 Saving order...")
//            let order = try await SupabaseManager.shared.createOrderWithItems(
//                userId: uuid,
//                parsedOrder: orderData
//            )
//            
//            print("✅ Order saved: \(order.id)")
//            didSave = true
//            
//        } catch {
//            print("❌ Error saving: \(error)")
//            errorMessage = error.localizedDescription
//        }
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
}
