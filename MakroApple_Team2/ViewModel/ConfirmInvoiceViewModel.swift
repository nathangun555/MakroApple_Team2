//
//  ConfirmInvoiceViewModel.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 04/11/25.
//

import SwiftUI
import Foundation
import Observation

@Observable
class ConfirmInvoiceViewModel {
    var userRecord: UserRecord?
    var orderRecord: OrderRecord?
    var orderItems: [OrderItemRecord] = []
    var products: [EditableProductItem] = []
    var downPaymentText: String = ""
    var errorMessage: String?
    var didSave: Bool = false

    var downPayment: Decimal {
        Decimal(string: downPaymentText) ?? 0
    }
    
    private(set) var userId: String?
    private var orderId: String?
    
    func configure(userId: String?, orderId: String?) {
        self.userId = userId
        self.orderId = orderId
    }
    
    var invoiceNumber: String = ""
    var invoiceDate: String = ""
    var invoiceDueDate: String = ""
    var accountName: String = ""
    var accountNumber: String = ""
    var bankName: String = ""
    var customerName: String = ""
    var customerPhone: String = ""
    var subtotalText: String = ""
    var shippingCostText: String = ""
    var totalText: String = ""
    var receiverName: String = ""
    var receiverPhone: String = ""
    var shippingAddress: String = ""
    var orderDate: String = ""
    var deliveryTime: String = ""
    var shippingOption: String = ""
    var notes: String = ""
    var photoUrl1: String = ""
    var addOn: String = ""
    var businessName: String = ""
    var businessPhone: String = ""
    var businessAddress: String = ""
    var businessLogoUrl: String = ""
    var businessEmail: String = ""
    
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
        }
    }
    
    func fillFromOrder(order: OrderRecord, items: [OrderItemRecord], user: UserRecord) async {
        self.orderRecord = order
        self.invoiceNumber = order.orderNumber
        
        let now = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        
        self.invoiceDate = DateFormatterHelper.isoDateString(from: now)
        self.invoiceDueDate = order.invoiceDueDate ?? DateFormatterHelper.isoDateString(from: tomorrow)
        
        self.businessName = user.businessName ?? "AIVA Bakery"
        self.businessAddress = user.businessAddress ?? "Orchard Road"
        self.businessPhone = user.businessPhone ?? "08123456789"
        self.businessEmail = user.businessEmail ?? "hello@aivabakery.com"
        self.businessLogoUrl = user.businessLogoUrl ?? ""
        self.accountName = user.bankAccountName ?? "Michelle Michiko"
        self.accountNumber = user.bankAccountNumber ?? "12345678910"
        self.bankName = user.bankName ?? "Bank Transfer - BCA"
        self.customerName = order.customerOrderName
        self.customerPhone = order.customerOrderPhone ?? ""
        self.subtotalText = order.subtotal.formatted()
        self.shippingCostText = order.shippingCost.formatted()
        self.totalText = total.formatted()
        self.receiverName = order.customerReceiverName ?? ""
        self.receiverPhone = order.customerReceiverPhone ?? ""
        self.shippingAddress = order.shippingAddress ?? ""
        
        self.orderDate = DateFormatterHelper.formattedDate(order.orderDdayDate ?? DateFormatterHelper.isoDateString(from: now), showTime: false)
        self.deliveryTime = DateFormatterHelper.formattedTime(order.orderDdayDate ?? "23:59")
        self.shippingOption = order.opsiPengiriman ?? ""
        self.notes = order.notes ?? ""
        self.downPaymentText = order.downPayment?.formatted() ?? 0.00.formatted()
        self.photoUrl1 = order.photoUrl1 ?? ""
        self.orderItems = items
        let tempEditableItems: [EditableProductItem] = items.map { item in
            EditableProductItem(
                id: item.id,
                productName: item.productName,
                productPrice: item.productPrice,
                productType: item.productType,
                quantity: item.quantity,
                discount: item.productDiscount,
                createdAt: item.createdAt ?? "",
                updatedAt: item.updatedAt ?? ""
            )
        }
        if let userId, let uuid = UUID(uuidString: userId) {
            await autoMapOrderedItemsToMenu(orderedItems: tempEditableItems, for: uuid)
        } else {
            self.products = tempEditableItems
        }
        self.addOn = order.addOn ?? ""
    }
    
    func onConfirmInvoice(hasDownPayment: Bool) async throws {
        if !hasDownPayment { downPaymentText = "" }
        do {
            try await saveProductItems()  
            try await saveOrderDetails()
            print("✅ Invoice confirmed and saved!")
            didSave = true
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error confirming invoice: \(error)")
        }
    }
    
    func makeOrderItemRecordsForSave() -> [OrderItemRecord] {
        guard let orderIdString = orderId,
              let orderUUID = UUID(uuidString: orderIdString) else {
            return []
        }
        return products.map { p in
            OrderItemRecord(
                id: p.id,
                orderId: orderUUID,
                productId: UUID(),
                productName: p.productName,
                productPrice: p.productPrice,
                productType: p.productType,
                productDiscount: p.discount,
                quantity: p.quantity,
                subtotal: p.subtotalAfterDiscount,
                createdAt: p.createdAt,
                updatedAt: ISO8601DateFormatter().string(from: Date()),
                productDiscount: p.discount
            )
            
        }
       
    }
    
    func autoMapOrderedItemsToMenu(
        orderedItems: [EditableProductItem],
        for userId: UUID
    ) async {
        do {
            let menuProducts = try await SupabaseManager.shared.fetchProducts(for: userId)

            let mappedProducts: [EditableProductItem] = orderedItems.map { ordered in
                if let matchingMenu = bestMatch(for: ordered.productName, in: menuProducts) {
                    return EditableProductItem(
                        id: ordered.id,
                        productName: matchingMenu.name,
                        productPrice: matchingMenu.price,
                        productType: matchingMenu.productType ?? "",
                        quantity: ordered.quantity,
                        discount: ordered.discount,
                        createdAt: ordered.createdAt,
                        updatedAt: ordered.updatedAt
                    )
                } else {
                    print("No match for '\(ordered.productName)'")
                    return EditableProductItem(
                        id: ordered.id,
                        productName: ordered.productName,
                        productPrice: ordered.productPrice,
                        productType: ordered.productType,
                        quantity: ordered.quantity,
                        discount: ordered.discount,
                        createdAt: ordered.createdAt,
                        updatedAt: ordered.updatedAt
                    )
                }
            }
            self.products = mappedProducts
        } catch {
            print("❌ Error fetching products or mapping:", error)
            self.errorMessage = "Failed to fetch menu/match products"
        }
    }

    
    func saveProductItems() async throws {
        guard let orderIdString = orderId,
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
        }
    }
    
    func saveOrderDetails() async throws {
        guard let orderIdString = orderId,
              let orderUUID = UUID(uuidString: orderIdString) else {
            errorMessage = "Order ID tidak valid."
            return
        }
        
        let shippingCost = Decimal(string: shippingCostText) ?? 0
        
        let updatedOrder = try await SupabaseManager.shared.updateOrder(
            orderId: orderUUID,
            invoiceDate: invoiceDate,
            invoiceDueDate: invoiceDueDate,
            subtotal: totalProductSubtotal,
            shippingCost: shippingCost,
            totalAmount: totalAfterDiscount,
            downPayment: downPayment
        )
        self.orderRecord = updatedOrder
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

}

struct EditableProductItem: Identifiable {
    var id: UUID
    var productName: String
    var productPrice: Decimal
    var productType: String
    var quantity: Int
    var discount: Decimal = 0
    var createdAt: String
    var updatedAt: String
    
    var subtotal: Decimal {
        productPrice * Decimal(quantity)
    }
    
    var subtotalAfterDiscount: Decimal {
       subtotal - discount
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
