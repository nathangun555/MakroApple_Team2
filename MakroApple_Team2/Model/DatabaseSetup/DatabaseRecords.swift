//
//  DatabaseRecords.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 15/10/25.
//

import Foundation

// MARK: - Users
struct UserRecord: Codable, Identifiable {
    let id: UUID
    let email: String
    let businessName: String?
    let businessPhone: String?
    let businessAddress: String?
    let businessLogoUrl: String?
    let subscriptionTier: String?
    let subscriptionExpiresAt: String?
    let templateFormat: [String: AnyCodable]?
    let invoiceVisibility: [String: AnyCodable]?
    let isActive: Bool?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, email
        case businessName = "business_name"
        case businessPhone = "business_phone"
        case businessAddress = "business_address"
        case businessLogoUrl = "business_logo_url"
        case subscriptionTier = "subscription_tier"
        case subscriptionExpiresAt = "subscription_expires_at"
        case templateFormat = "template_format"
        case invoiceVisibility = "invoice_visibility"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Products
struct ProductRecord: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let name: String
    let price: Decimal
    let notes: String?
    let isActive: Bool
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name, price, notes
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Orders
struct OrderRecord: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let orderNumber: String
    let status: String
    let orderDdayDate: String?
    let invoiceDueDate: String?
    let customerOrderName: String
    let customerOrderPhone: String?
    let customerReceiverName: String?
    let customerReceiverPhone: String?
    let addOn: String?
    let notes: String?
    let opsiPengiriman: String?
    let shippingAddress: String?
    let subtotal: Decimal
    let shippingCost: Decimal
    let discountAmount: Decimal
    let totalAmount: Decimal
    let invoiceUrl: String?
    let photoUrl1: String?
    let photoUrl2: String?
    let photoUrl3: String?
    let customFields: [String: AnyCodable]?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case orderNumber = "order_number"
        case status
        case orderDdayDate = "order_dday_date"
        case invoiceDueDate = "invoice_due_date"
        case customerOrderName = "customer_order_name"
        case customerOrderPhone = "customer_order_phone"
        case customerReceiverName = "customer_receiver_name"
        case customerReceiverPhone = "customer_receiver_phone"
        case addOn = "add_on"
        case notes
        case opsiPengiriman = "opsi_pengiriman"
        case shippingAddress = "shipping_address"
        case subtotal, shippingCost, discountAmount, totalAmount
        case invoiceUrl = "invoice_url"
        case photoUrl1 = "photo_url_1"
        case photoUrl2 = "photo_url_2"
        case photoUrl3 = "photo_url_3"
        case customFields = "custom_fields"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Order Items
struct OrderItemRecord: Codable, Identifiable {
    let id: UUID
    let orderId: UUID
    let productId: UUID?
    let productName: String
    let productPrice: Decimal
    let quantity: Int
    let subtotal: Decimal
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case orderId = "order_id"
        case productId = "product_id"
        case productName = "product_name"
        case productPrice = "product_price"
        case quantity, subtotal
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
