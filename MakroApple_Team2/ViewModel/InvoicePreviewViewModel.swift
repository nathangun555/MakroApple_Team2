//
//  InvoicePreviewViewModel.swift
//  MakroApple_Team2
//
//  Created by Assistant on 24/10/25.
//

import SwiftUI
import UIKit
import Observation

@Observable
@MainActor
class InvoicePreviewViewModel {
    var userRecord: UserRecord?
    
    var customerName: String = ""
    var customerPhone: String = ""
    var recipientName: String = ""
    var recipientPhone: String = ""
    var deliveryAddress: String = ""
    var orderDate: String = ""
    var deliveryTime: String = ""
    var orderItems: [InvoiceOrderItem] = []
    var addOns: String = ""
    var wishGreeting: String = ""
    var deliveryMethod: String = ""
    var notes: String = ""
    
    var subtotal: Double = 0
    var shippingCost: Double = 0
    var total: Double = 0
    var downPayment: Double = 0
    
    var isLoading = false
    var errorMessage: String?
    
    var exportFormat: ExportFormat = .pdf
    
    private(set) var userId: String?
    
    func configure(userId: String?) {
        self.userId = userId
    }
    
    // MARK: - Load Invoice Data
    func loadInvoiceData() async {
        guard let userId, let uuid = UUID(uuidString: userId) else {
            errorMessage = "User belum login atau UID tidak valid."
            return
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            guard let record = try await SupabaseManager.shared.fetchUser(by: uuid) else {
                errorMessage = "Data user tidak ditemukan"
                return
            }
            
            // Store the entire record
            self.userRecord = record
            
            // Load template form data
            if let templateDict = record.templateFormat {
                loadTemplateData(from: templateDict)
            }
            
            // Generate mock invoice data for preview
            generateMockInvoiceData()
            
        } catch {
            errorMessage = "Gagal memuat data: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Parse Template Data
    private func loadTemplateData(from templateDict: [String: AnyCodable]) {
        // Map template fields to invoice fields
        customerName = (templateDict["Nama Pemesan"]?.value as? String) ?? ""
        customerPhone = (templateDict["No. Telp Pemesan"]?.value as? String) ?? ""
        recipientName = (templateDict["Nama Penerima"]?.value as? String) ?? ""
        recipientPhone = (templateDict["No. Telp Penerima"]?.value as? String) ?? ""
        deliveryAddress = (templateDict["Alamat Kirim"]?.value as? String) ?? ""
        orderDate = (templateDict["Tanggal Pesanan"]?.value as? String) ?? ""
        deliveryTime = (templateDict["Jam Kirim"]?.value as? String) ?? ""
        deliveryMethod = (templateDict["Pengiriman: Kurir / Pickup"]?.value as? String) ?? ""
        notes = (templateDict["Notes"]?.value as? String) ?? ""
        
        // Parse Adds-on
        if let addOnsArray = templateDict["Adds-on"]?.value as? [[String: Any]] {
            addOns = addOnsArray.compactMap { $0["item"] as? String }.joined(separator: ", ")
        }
        
        // Parse Wish/Greeting
        wishGreeting = (templateDict["Wish / Greeting"]?.value as? String) ?? ""
        
        // Parse Pesanan (order items)
        if let orderArray = templateDict["Pesanan"]?.value as? [[String: Any]] {
            orderItems = orderArray.compactMap { item in
                guard let itemName = item["item"] as? String else { return nil }
                let quantity = item["quantity"] as? Int ?? 1
                return InvoiceOrderItem(
                    description: itemName.isEmpty ? "Tiramisu" : itemName,
                    unitPrice: 0,
                    quantity: quantity,
                    total: 0
                )
            }
        }
    }
    
    // MARK: - Generate Mock Data
    private func generateMockInvoiceData() {
        // Generate mock data for preview
        if orderItems.isEmpty {
            orderItems = [
                InvoiceOrderItem(description: "Product 1", unitPrice: 0, quantity: 1, total: 0),
                InvoiceOrderItem(description: "Product 2", unitPrice: 0, quantity: 1, total: 0)
            ]
        }
        
        if customerName.isEmpty { customerName = "Nama Customer" }
        if customerPhone.isEmpty { customerPhone = "No Telp Customer" }
        if recipientName.isEmpty { recipientName = "Nama Penerima" }
        if recipientPhone.isEmpty { recipientPhone = "No telp" }
        if deliveryAddress.isEmpty { deliveryAddress = "Alamat kirim" }
        if orderDate.isEmpty { orderDate = "DD/MM/YY" }
        if deliveryTime.isEmpty { deliveryTime = "DD/MM/YY" }
    }
    
    // MARK: - Generate Invoice Code
    func generateInvoiceCode() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"
        let year = dateFormatter.string(from: Date())
        
        let randomNumber = Int.random(in: 10000...99999)
        return "INV/\(year)/\(String(format: "%05d", randomNumber))"
    }
    
    // MARK: - Export as Image
    @MainActor
    func exportAsImage(view: some View) -> UIImage? {
        let renderer = ImageRenderer(content: view)
        
        // Set scale for high quality
        renderer.scale = 3.0
        
        return renderer.uiImage
    }
    
    // MARK: - Export as PDF
    @MainActor
    func exportAsPDF(view: some View) -> Data? {
        let renderer = ImageRenderer(content: view)
        
        let pageSize = CGSize(width: 595, height: 842) // A4
        renderer.proposedSize = .init(pageSize)
        
        var pdfData = Data()
        
        guard let consumer = CGDataConsumer(data: pdfData as! CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: nil, nil) else {
            return nil
        }
        
        renderer.render { size, renderer in
            var mediaBox = CGRect(origin: .zero, size: pageSize)
            
            context.beginPage(mediaBox: &mediaBox)
            renderer(context)
            context.endPage()
        }
        
        context.closePDF()
        
        return pdfData
    }
    
    // MARK: - Share Invoice
    func shareInvoice(items: [Any], completion: @escaping (Bool) -> Void) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            completion(false)
            return
        }
        
        let activityVC = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        
        // For iPad
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = rootViewController.view
            popover.sourceRect = CGRect(x: rootViewController.view.bounds.midX,
                                       y: rootViewController.view.bounds.midY,
                                       width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        rootViewController.present(activityVC, animated: true) {
            completion(true)
        }
    }
}

enum ExportFormat {
    case pdf
    case image
}

// MARK: - Data Models
struct InvoiceOrderItem: Identifiable {
    let id = UUID()
    let description: String
    let unitPrice: Double
    let quantity: Int
    let total: Double
}
