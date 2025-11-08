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
    var orderRecord: OrderRecord?
    var orderItems: [OrderItemRecord] = []
    
    // ... all your display fields ...
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
    
    var isLoading = false
    var errorMessage: String?
    var exportFormat: ExportFormat = .pdf
    
    private(set) var userId: String?
    private(set) var orderId: String?
    
    var isPreviewMode: Bool {
        orderId == nil
    }
    
    func configure(userId: String?, orderId: String?) {
        self.userId = userId
        self.orderId = orderId
    }
    
    // MARK: - Load Data (Real or Mock)
    func loadInvoiceData() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        if let orderIdString = orderId, let orderUUID = UUID(uuidString: orderIdString) {
            // Load REAL data from database
            await loadRealOrderData(orderUUID: orderUUID)
        } else {
            // Load TEMPLATE/MOCK data for first-time users
            await loadTemplateData()
        }
    }
    
    // MARK: - Load Real Order Data
    private func loadRealOrderData(orderUUID: UUID) async {
        do {
            let order = try await SupabaseManager.shared.fetchOrder(id: orderUUID)
            let items = try await SupabaseManager.shared.fetchOrderItem(orderId: orderUUID)
            
            self.orderRecord = order
            self.orderItems = items
            
            populateFromOrder(order: order, items: items)
            
        } catch {
            errorMessage = "Gagal memuat data invoice: \(error.localizedDescription)"
            print("❌ Error loading invoice: \(error)")
        }
    }
    
    // MARK: - Load Template Data (First-Time Users)
    private func loadTemplateData() async {
        guard let userId, let uuid = UUID(uuidString: userId) else {
            errorMessage = "User belum login atau UID tidak valid."
            return
        }
        
        do {
            guard let record = try await SupabaseManager.shared.fetchUser(by: uuid) else {
                errorMessage = "Data user tidak ditemukan"
                return
            }
            
            self.userRecord = record
            
            // Load template form data if available
            if let templateDict = record.templateFormat {
                parseTemplateData(from: templateDict)
            }
            
            // Generate mock data for preview
            generateMockInvoiceData()
            
        } catch {
            errorMessage = "Gagal memuat data: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Populate from Real Order
    private func populateFromOrder(order: OrderRecord, items: [OrderItemRecord]) {
        invoiceNumber = order.orderNumber
        invoiceDate = order.invoiceDueDate ?? DateFormatterHelper.isoDateString(from: Date())
        invoiceDueDate = order.invoiceDueDate ?? DateFormatterHelper.isoDateString(from: Calendar.current.date(byAdding: .day, value: 1, to: Date())!)
        
        accountName = order.customFields?["account_name"]?.value as? String ?? "Michelle Michiko"
        accountNumber = order.customFields?["account_number"]?.value as? String ?? "12345678910"
        bankName = order.customFields?["bank_name"]?.value as? String ?? "Bank Transfer - BCA"
        
        customerName = order.customerOrderName
        customerPhone = order.customerOrderPhone ?? ""
        recipientName = order.customerReceiverName ?? ""
        recipientPhone = order.customerReceiverPhone ?? ""
        deliveryAddress = order.shippingAddress ?? ""
        
        let (tanggalPesanan, jamKirim) = DateFormatterHelper.indonesianDateAndTime(from: order.orderDdayDate ?? "")
        orderDate = tanggalPesanan
        deliveryTime = jamKirim
        
        deliveryMethod = order.opsiPengiriman ?? ""
        addOns = order.addOn ?? ""
        notes = order.notes ?? ""
        
        subtotal = order.subtotal
        shippingCost = order.shippingCost
        discountAmount = order.discountAmount
        total = order.totalAmount
        downPayment = Decimal(string: order.customFields?["down_payment"]?.value as? String ?? "") ?? 0
        
        photoUrl1 = order.photoUrl1 ?? ""
    }
    
    // MARK: - Parse Template Data
    private func parseTemplateData(from templateDict: [String: AnyCodable]) {
        customerName = (templateDict["Nama Pemesan"]?.value as? String) ?? ""
        customerPhone = (templateDict["No. Telp Pemesan"]?.value as? String) ?? ""
        recipientName = (templateDict["Nama Penerima"]?.value as? String) ?? ""
        recipientPhone = (templateDict["No. Telp Penerima"]?.value as? String) ?? ""
        deliveryAddress = (templateDict["Alamat Kirim"]?.value as? String) ?? ""
        orderDate = (templateDict["Tanggal Pesanan"]?.value as? String) ?? ""
        deliveryTime = (templateDict["Jam Kirim"]?.value as? String) ?? ""
        deliveryMethod = (templateDict["Pengiriman: Kurir / Pickup"]?.value as? String) ?? ""
        notes = (templateDict["Notes"]?.value as? String) ?? ""
        
        if let addOnsArray = templateDict["Adds-on"]?.value as? [[String: Any]] {
            addOns = addOnsArray.compactMap { $0["item"] as? String }.joined(separator: ", ")
        }
    }
    
    // MARK: - Generate Mock Data
    private func generateMockInvoiceData() {
        if customerName.isEmpty { customerName = "Nama Customer" }
        if customerPhone.isEmpty { customerPhone = "No Telp Customer" }
        if recipientName.isEmpty { recipientName = "Nama Penerima" }
        if recipientPhone.isEmpty { recipientPhone = "No telp" }
        if deliveryAddress.isEmpty { deliveryAddress = "Alamat kirim" }
        if orderDate.isEmpty { orderDate = "DD/MM/YY" }
        if deliveryTime.isEmpty { deliveryTime = "DD/MM/YY" }
        
        // Mock invoice number for preview
        invoiceNumber = generateInvoiceCode()
    }
    
    // MARK: - Get Invoice Items for Display
    var displayOrderItems: [InvoiceOrderItem] {
        if !orderItems.isEmpty {
            // Real data
            return orderItems.map { item in
                InvoiceOrderItem(
                    description: item.productName,
                    unitPrice: item.productPrice,
                    quantity: item.quantity,
                    total: item.subtotal
                )
            }
        } else {
            // Mock data for preview
            return [
                InvoiceOrderItem(description: "Product 1", unitPrice: 0, quantity: 1, total: 0),
                InvoiceOrderItem(description: "Product 2", unitPrice: 0, quantity: 1, total: 0)
            ]
        }
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
        // Define A4 size in points (72 DPI)
        let a4Size = CGSize(width: 595.2, height: 841.8) // A4 in points

        // 1) Create the SwiftUI view sized to A4
        let renderer = ImageRenderer(
            content: view
                .frame(width: a4Size.width, height: a4Size.height, alignment: .top)
        )

        // 2) Improve quality
        renderer.scale = UIScreen.main.scale

        // 3) Render to UIImage
        guard let uiImage = renderer.uiImage else { return nil }

        // 4) Create PDF context with A4 box
        let pdfData = NSMutableData()
        var mediaBox = CGRect(origin: .zero, size: a4Size)
        guard
            let consumer = CGDataConsumer(data: pdfData as CFMutableData),
            let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)
        else { return nil }

        context.beginPDFPage(nil)

        // 5) Draw the SwiftUI-rendered image into A4
        if let cgImage = uiImage.cgImage {
            context.draw(cgImage, in: mediaBox)
        }

        context.endPDFPage()
        context.closePDF()

        return pdfData as Data
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
    
    // MARK: - Save and Upload Invoice
    func saveAndUploadInvoice(pdfData: Data) async throws -> String {
        guard let orderIdString = orderId,
              let orderUUID = UUID(uuidString: orderIdString) else {
            throw NSError(domain: "InvoiceError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid order ID"])
        }
        
        let fileName = "\(invoiceNumber.replacingOccurrences(of: "/", with: "_")).pdf"

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName)
        
        try pdfData.write(to: tempURL)
        
        let publicURL = try await SupabaseManager.shared.uploadFile(
            tempURL,
            folder: "invoices"
        )
        
        // Update order with invoice URL
        _ = try await SupabaseManager.shared.updateOrderInvoiceURL(
            orderId: orderUUID,
            invoiceURL: publicURL
        )
        
        // Clean up temp file
        try? FileManager.default.removeItem(at: tempURL)
        
        print("✅ Invoice PDF uploaded and order updated: \(publicURL)")
        return publicURL
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
    let unitPrice: Decimal
    let quantity: Int
    let total: Decimal
}
