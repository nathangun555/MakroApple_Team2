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
    var order: OrderRecord?
    var items: [OrderItemRecord] = []
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
    
    var totalProductSubtotal: Decimal {
        products.reduce(0) { $0 + $1.subtotal }
    }

    var total: Decimal {
        totalProductSubtotal + (Decimal(string: shippingCostText) ?? 0)
    }

    func fetchOrderAndItems(orderId: UUID) async {
        do {
            let order = try await SupabaseManager.shared.fetchOrder(id: orderId)
            let items = try await SupabaseManager.shared.fetchOrderItem(orderId: orderId)
            self.fillFromOrder(order: order, items: items)
        } catch {
            print("❌ Error fetching order or items: \(error)")
        }
    }
    
    func fillFromOrder(order: OrderRecord, items: [OrderItemRecord]) {
        self.order = order
        self.invoiceNumber = order.orderNumber
        
        let now = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        
        self.invoiceDate = order.invoiceDueDate ?? DateFormatterHelper.isoDateString(from: now)
        self.invoiceDueDate = order.invoiceDueDate ?? DateFormatterHelper.isoDateString(from: tomorrow)
        
        self.accountName = order.customFields?["account_name"]?.value as? String ?? "Michelle Michiko"
        self.accountNumber = order.customFields?["account_number"]?.value as? String ?? "12345678910"
        self.bankName = order.customFields?["bank_name"]?.value as? String ?? "Bank Tranfer - BCA"
        self.customerName = order.customerOrderName
        self.customerPhone = order.customerOrderPhone ?? ""
        self.subtotalText = order.subtotal.formatted()
        self.shippingCostText = order.shippingCost.formatted()
        self.totalText = total.formatted()
        self.receiverName = order.customerReceiverName ?? ""
        self.receiverPhone = order.customerReceiverPhone ?? ""
        self.shippingAddress = order.shippingAddress ?? ""
        
        let (tanggalPesanan, jamKirim) = DateFormatterHelper.indonesianDateAndTime(from: order.orderDdayDate ?? "")
        self.orderDate = tanggalPesanan
        self.deliveryTime = jamKirim

        self.shippingOption = order.opsiPengiriman ?? ""
        self.notes = order.notes ?? ""
        self.downPaymentText = order.customFields?["down_payment"]?.value as? String ?? ""
        self.photoUrl1 = order.photoUrl1 ?? ""
        self.items = items
        self.products = items.map { item in
            EditableProductItem(
                id: item.id,
                productName: item.productName,
                productPrice: item.productPrice,
                productType: item.productType,
                quantity: item.quantity,
                createdAt: item.createdAt ?? "",
                updatedAt: item.updatedAt ?? ""
            )
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
                productId: UUID(uuidString: "e5819927-6930-4b71-ad93-188be0f72a9a"),
                productName: p.productName,
                productPrice: p.productPrice,
                productType: p.productType,
                quantity: p.quantity,
                subtotal: p.subtotal,
                createdAt: p.createdAt,
                updatedAt: ISO8601DateFormatter().string(from: Date())
            )
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
            self.items = updatedRecord
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
            subtotal: totalProductSubtotal,
            shippingCost: shippingCost,
            totalAmount: total
        )
        self.order = updatedOrder
    }
}

struct EditableProductItem: Identifiable {
    var id: UUID
    var productName: String
    var productPrice: Decimal
    var productType: String
    var quantity: Int
    var createdAt: String
    var updatedAt: String
    
    var subtotal: Decimal {
        productPrice * Decimal(quantity)
    }
}
