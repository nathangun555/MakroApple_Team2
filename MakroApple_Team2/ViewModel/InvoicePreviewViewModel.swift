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
    
    var invoiceData : InvoiceData = InvoiceData()
    
    // ... all your display fields ...
//    var invoiceNumber: String = ""
//    var invoiceDate: String = ""
//    var invoiceDueDate: String = ""
//    var accountName: String = ""
//    var accountNumber: String = ""
//    var bankName: String = ""
//    var customerName: String = ""
//    var customerPhone: String = ""
//    var recipientName: String = ""
//    var recipientPhone: String = ""
//    var deliveryAddress: String = ""
//    var orderDate: String = ""
//    var deliveryTime: String = ""
//    var deliveryMethod: String = ""
//    var addOns: String = ""
//    var notes: String = ""
//    var subtotal: Decimal = 0
//    var shippingCost: Decimal = 0
//    var discountAmount: Decimal = 0
//    var total: Decimal = 0
//    var downPayment: Decimal = 0
//    var photoUrl1: String = ""
//    var businessName: String = ""
//    var businessPhone: String = ""
//    var businessAddress: String = ""
//    var businessLogoUrl: String = ""
//    var businessEmail: String = ""
    
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
    
    
    func tempPDFURL() -> URL? {
        let invoiceView = InvoiceContentView(viewModel: invoiceData)
            .padding(20)
            .background(Color.white)
            .frame(width: 595, height: 841)
        
        guard let pdfData = exportAsPDF(view: invoiceView) else { return nil }
        
        let invoiceCode = invoiceData.invoiceNumber.isEmpty ? "Invoice" : invoiceData.invoiceNumber
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(invoiceCode.replacingOccurrences(of: "/", with: "_")).pdf")
        
        do {
            try pdfData.write(to: tempURL)
            return tempURL
        } catch {
            print("❌ Error saving PDF: \(error)")
            return nil
        }
    }

    func loadUserProfileData() async {
        guard let userId, let uuid = UUID(uuidString: userId) else { return }
        do {
            let user = try await SupabaseManager.shared.fetchUser(by: uuid)
            self.userRecord = user
            self.invoiceData.businessName = user?.businessName ?? ""
            self.invoiceData.businessPhone = user?.businessPhone ?? ""
            self.invoiceData.businessAddress = user?.businessAddress ?? ""
            self.invoiceData.bankName = user?.bankName ?? ""
            self.invoiceData.accountNumber = user?.bankAccountNumber ?? ""
            self.invoiceData.accountName = user?.bankAccountName ?? ""
            self.invoiceData.businessLogoUrl = user?.businessLogoUrl ?? ""
            self.invoiceData.businessEmail = user?.businessEmail ?? ""
        } catch {
            errorMessage = "No user found"
        }
    }
    
    // MARK: - Load Data (Real or Mock)
    func loadInvoiceData() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        if let orderIdString = orderId, let orderUUID = UUID(uuidString: orderIdString) {
            // Load REAL data from database
            await loadRealOrderData(orderUUID: orderUUID)
        }
        else {
            // Load TEMPLATE/MOCK data for first-time users
            await loadTemplateData()
        }
    }
    
    // MARK: - Load Real Order Data
    private func loadRealOrderData(orderUUID: UUID) async {
        do {
            if let userIdString = userId, let userUUID = UUID(uuidString: userIdString) {
                if let user = try await SupabaseManager.shared.fetchUser(by: userUUID) {
                    self.userRecord = user
                    let order = try await SupabaseManager.shared.fetchOrder(id: orderUUID)
                    let items = try await SupabaseManager.shared.fetchOrderItem(orderId: orderUUID)
                    
                    self.orderRecord = order
                    self.orderItems = items
                    
                    await populateFromOrder(order: order, items: items, user: user)
                } else {
                    errorMessage = "User not found"
                }
            }
            
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
            await loadUserProfileData()
            generateMockInvoiceData()
            
        } catch {
            errorMessage = "Gagal memuat data: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Populate from Real Order
    private func populateFromOrder(order: OrderRecord, items: [OrderItemRecord], user: UserRecord) async {
        invoiceData.invoiceNumber = order.orderNumber
        invoiceData.invoiceDate = order.invoiceDate ?? "DD/MM/YYYY"
        invoiceData.invoiceDueDate = order.invoiceDueDate ?? "DD/MM/YYYY"
        
        invoiceData.businessName = user.businessName ?? "AIVA Bakery"
        invoiceData.businessAddress = user.businessAddress ?? "Orchard Road"
        invoiceData.businessPhone = user.businessPhone ?? "08123456789"
        invoiceData.businessEmail = user.businessEmail ?? "hello@aivabakery.com"
        invoiceData.businessLogoUrl = user.businessLogoUrl ?? ""
        invoiceData.accountName = user.bankAccountName ?? "Michelle Michiko"
        invoiceData.accountNumber = user.bankAccountNumber ?? "12345678910"
        invoiceData.bankName = user.bankName ?? "Bank Transfer - BCA"
        
        invoiceData.customerName = order.customerOrderName ?? "Customer Name"
        invoiceData.customerPhone = order.customerOrderPhone ?? "08123456789"
        invoiceData.recipientName = order.customerReceiverName ?? "Recipient Name"
        invoiceData.recipientPhone = order.customerReceiverPhone ?? "08123456789"
        
        invoiceData.orderDate = DateFormatterHelper.formattedDate(order.orderDdayDate ?? "DD/MM/YYYY")
        invoiceData.deliveryTime = DateFormatterHelper.formattedTime(order.orderDdayDate ?? "23:59")
        
        invoiceData.deliveryMethod = order.opsiPengiriman ?? ""
        invoiceData.addOns = order.addOn ?? ""
        invoiceData.notes = order.notes ?? ""
        
        invoiceData.subtotal = order.subtotal
        invoiceData.shippingCost = order.shippingCost
        invoiceData.total = order.totalAmount
        invoiceData.downPayment = order.downPayment ?? 0
        
        invoiceData.photoUrl1 = order.photoUrl1 ?? ""
        
        invoiceData.displayOrderItems = displayOrderItems

    }
    
    // MARK: - Parse Template Data
    private func parseTemplateData(from templateDict: [String: AnyCodable]) {
        invoiceData.customerName = (templateDict["Nama Pemesan"]?.value as? String) ?? ""
        invoiceData.customerPhone = (templateDict["No. Telp Pemesan"]?.value as? String) ?? ""
        invoiceData.recipientName = (templateDict["Nama Penerima"]?.value as? String) ?? ""
        invoiceData.recipientPhone = (templateDict["No. Telp Penerima"]?.value as? String) ?? ""
        invoiceData.deliveryAddress = (templateDict["Alamat Kirim"]?.value as? String) ?? ""
        invoiceData.orderDate = (templateDict["Tanggal Pesanan"]?.value as? String) ?? ""
        invoiceData.deliveryTime = (templateDict["Jam Kirim"]?.value as? String) ?? ""
        invoiceData.deliveryMethod = (templateDict["Pengiriman: Kurir / Pickup"]?.value as? String) ?? ""
        invoiceData.notes = (templateDict["Notes"]?.value as? String) ?? ""
        
        if let addOnsArray = templateDict["Adds-on"]?.value as? [[String: Any]] {
            invoiceData.addOns = addOnsArray.compactMap { $0["item"] as? String }.joined(separator: ", ")
        }
    }
    
    // MARK: - Generate Mock Data
    private func generateMockInvoiceData() {
        if invoiceData.customerName.isEmpty { invoiceData.customerName = "Nama Customer" }
        if invoiceData.customerPhone.isEmpty { invoiceData.customerPhone = "No Telp Customer" }
        if invoiceData.recipientName.isEmpty { invoiceData.recipientName = "Nama Penerima" }
        if invoiceData.recipientPhone.isEmpty { invoiceData.recipientPhone = "No telp" }
        if invoiceData.deliveryAddress.isEmpty { invoiceData.deliveryAddress = "Alamat kirim" }
        if invoiceData.orderDate.isEmpty { invoiceData.orderDate = "DD/MM/YY" }
        if invoiceData.deliveryTime.isEmpty { invoiceData.deliveryTime = "DD/MM/YY" }
        if invoiceData.invoiceDate.isEmpty { invoiceData.invoiceDate = "DD/MM/YY" }
        if invoiceData.invoiceDueDate.isEmpty { invoiceData.invoiceDueDate = "DD/MM/YY" }
        
        if invoiceData.displayOrderItems.isEmpty {
                invoiceData.displayOrderItems = [
                    InvoiceOrderItem(description: "Product 1", unitPrice: 0, quantity: 1, discount: 0, total: 0),
                    InvoiceOrderItem(description: "Product 2", unitPrice: 0, quantity: 1, discount: 0, total: 0)
                ]
            }
        
        // Mock invoice number for preview
        invoiceData.invoiceNumber = generateInvoiceCode()
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
                    discount: item.productDiscount,
                    total: item.subtotal
                    
                )
            }
        } else {
            // Mock data for preview
            return [
                InvoiceOrderItem(description: "Product 1", unitPrice: 0, quantity: 1, discount: 0, total: 0),
                InvoiceOrderItem(description: "Product 2", unitPrice: 0, quantity: 1, discount : 0,total: 0)
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
        print("📤 shareInvoice() called with items: \(items)")

        // 1️⃣ Find the topmost UIViewController — even inside SwiftUI sheet
        guard let rootVC = topMostViewController() else {
            print("❌ No root view controller found")
            completion(false)
            return
        }

        // 2️⃣ Create activity VC
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)

        // 3️⃣ iPad popover setup
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = rootVC.view
            popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        // 4️⃣ Present
        rootVC.present(activityVC, animated: true) {
            print("🚀 Presented share sheet from \(rootVC)")
            completion(true)
        }
    }

    // Helper to find the current visible UIViewController in SwiftUI
    private func topMostViewController(base: UIViewController? = nil) -> UIViewController? {
        let baseVC = base ?? UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?.rootViewController

        if let nav = baseVC as? UINavigationController {
            return topMostViewController(base: nav.visibleViewController)
        } else if let tab = baseVC as? UITabBarController {
            return topMostViewController(base: tab.selectedViewController)
        } else if let presented = baseVC?.presentedViewController {
            return topMostViewController(base: presented)
        }
        return baseVC
    }


    
    // MARK: - Save and Upload Invoice
    func saveAndUploadInvoice(pdfData: Data) async throws -> String {
        guard let orderIdString = orderId,
              let orderUUID = UUID(uuidString: orderIdString) else {
            throw NSError(domain: "InvoiceError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid order ID"])
        }
        
        let fileName = "\(invoiceData.invoiceNumber.replacingOccurrences(of: "/", with: "_")).pdf"

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
    let discount : Decimal
    let total: Decimal
}
