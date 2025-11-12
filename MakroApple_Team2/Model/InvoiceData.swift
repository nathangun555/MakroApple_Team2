//
//  InvoiceData.swift
//  MakroApple_Team2
//
//  Created by Edward Suwandi on 12/11/25.
//
import SwiftUI

struct InvoiceData {
    var invoiceNumber: String = ""
    var invoiceDate: String = ""
    var invoiceDueDate: String = ""
    var accountName: String = ""
    var accountNumber: String = ""
    var bankName: String = ""
    var customerName: String = ""
    var customerPhone: String = ""
    var recipientName: String = ""
    var recipientPhone: String = ""
    var deliveryAddress: String = ""
    var orderDate: String = ""
    var deliveryTime: String = ""
    var deliveryMethod: String = ""
    var addOns: String = ""
    var notes: String = ""
    var subtotal: Decimal = 0
    var shippingCost: Decimal = 0
    var discountAmount: Decimal = 0
    var total: Decimal = 0
    var downPayment: Decimal = 0
    var photoUrl1: String = ""
    var businessName: String = ""
    var businessPhone: String = ""
    var businessAddress: String = ""
    var businessLogoUrl: String = ""
    var businessEmail: String = ""
    var displayOrderItems: [InvoiceOrderItem] = []
}
