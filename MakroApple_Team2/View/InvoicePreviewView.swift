//
//  InvoicePreviewView.swift
//  MakroApple_Team2
//
//  Created by Assistant on 24/10/25.
//

import SwiftUI

struct InvoicePreviewView: View {
    @State private var viewModel = InvoicePreviewViewModel()
    @EnvironmentObject var session: SessionManager
    @Environment(\.dismiss) var dismiss
    
    @State private var exportFormat: ExportFormat = .pdf
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading {
                    ProgressView("Memuat invoice...")
                } else if let errorMessage = viewModel.errorMessage {
                    VStack {
                        Text("❌ Error")
                            .font(.headline)
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                } else {
                    ScrollView {
                        invoiceContent
                            .padding(20)
                            .background(Color.white)
                    }
                    .background(Color(.systemGray6))
                }
            }
            .navigationTitle("Preview Invoice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(action: {
                            exportFormat = .pdf
                            exportAndShare()
                        }) {
                            Label("Export as PDF", systemImage: "doc.fill")
                        }
                        
                        Button(action: {
                            exportFormat = .image
                            exportAndShare()
                        }) {
                            Label("Export as Image", systemImage: "photo.fill")
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .task {
            viewModel.configure(userId: session.userId)
            await viewModel.loadInvoiceData()
        }
    }
    
    // MARK: - Invoice Content
    var invoiceContent: some View {
        VStack(spacing: 12) {
            // Header
            headerSection
            
            Divider()
            
            // Customer and Payment Info
            HStack(alignment: .top, spacing: 20) {
                billedToSection
                Spacer()
                paymentInfoSection
            }
            
            Divider()
            
            // Recipient and Date Info
            HStack(alignment: .top, spacing: 20) {
                recipientSection
                Spacer()
                dateInfoSection
            }
            
            Divider()
            
            // Order Items Table
            orderItemsTable
            
            Spacer(minLength: 30)
            
            // Totals
            totalsSection
            
            Spacer(minLength: 40)
            
            // Delivery Details
            deliveryDetailsSection
        }
    }
    
    // MARK: - Header Section
    var headerSection: some View {
        HStack(alignment: .top, spacing: 12) {
            // Logo
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray5))
                .frame(width: 60, height: 60)
                .overlay(
                    Text("LOGO")
                        .font(.system(size: 8))
                        .foregroundColor(.gray)
                )
            
            // Business Info
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.userRecord?.businessName ?? "TaskFlow Bakerydd")
                    .font(.system(size: 14, weight: .bold))
                
                if let address = viewModel.userRecord?.businessAddress, !address.isEmpty {
                    Text(address)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
                
                if let phone = viewModel.userRecord?.businessPhone, !phone.isEmpty {
                    Text(phone)
                        .font(.system(size: 9))
                }
                
                if let email = viewModel.userRecord?.businessEmail, !email.isEmpty {
                    Text(email)
                        .font(.system(size: 9))
                }
            }
            
            Spacer()
            
            // Invoice Title
            VStack(alignment: .trailing, spacing: 0) {
                Text("INVOICE")
                    .font(.system(size: 24, weight: .bold))
                    .tracking(1)
                
                Text("Invoice Code : \(viewModel.generateInvoiceCode())")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Billed To Section
    var billedToSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Ditagihkan Ke")
                .font(.system(size: 11, weight: .bold))
                .underline()
            
            Text(viewModel.customerName)
                .font(.system(size: 10))
                .italic()
            
            Text(viewModel.customerPhone)
                .font(.system(size: 10))
                .italic()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Payment Info Section
    var paymentInfoSection: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("Informasi Pembayaran")
                .font(.system(size: 11, weight: .bold))
                .underline()
            
            Text(viewModel.userRecord?.bankAccountName ?? "Nathana")
                .font(.system(size: 10))
            
            Text(viewModel.userRecord?.bankAccountNumber ?? "238904421")
                .font(.system(size: 10))
            
            Text(viewModel.userRecord?.bankName ?? "Boca")
                .font(.system(size: 10))
        }
    }
    
    // MARK: - Recipient Section
    var recipientSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Informasi Penerima")
                .font(.system(size: 11, weight: .bold))
                .underline()
            
            Text(viewModel.recipientName)
                .font(.system(size: 10))
                .italic()
            
            Text(viewModel.recipientPhone)
                .font(.system(size: 10))
                .italic()
            
            Text(viewModel.deliveryAddress)
                .font(.system(size: 10))
                .italic()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Date Info Section
    var dateInfoSection: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("Informasi Tanggal")
                .font(.system(size: 11, weight: .bold))
                .underline()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("Tanggal Invoice : \(viewModel.orderDate)")
                    .font(.system(size: 10))
                
                Text("Jatuh Tempo Pembayaran : \(viewModel.deliveryTime)")
                    .font(.system(size: 10))
            }
            
            Text("Pesanan akan otomatis dibatalkan jika melewati tanggal jatuh tempo.")
                .font(.system(size: 7))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 150)
        }
    }
    
    // MARK: - Order Items Table
    var orderItemsTable: some View {
        VStack(spacing: 0) {
            // Table Header
            HStack {
                Text("Deskripsi Barang")
                    .font(.system(size: 10, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Harga satuan")
                    .font(.system(size: 10, weight: .bold))
                    .frame(width: 70)
                
                Text("Jumlah")
                    .font(.system(size: 10, weight: .bold))
                    .frame(width: 50)
                
                Text("Total Harga")
                    .font(.system(size: 10, weight: .bold))
                    .frame(width: 70, alignment: .trailing)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
            .background(Color(.systemGray5))
            
            // Table Rows
            ForEach(viewModel.orderItems) { item in
                VStack(spacing: 0) {
                    HStack {
                        Text(item.description)
                            .font(.system(size: 10))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("")
                            .font(.system(size: 10))
                            .frame(width: 70)
                        
                        Text("")
                            .font(.system(size: 10))
                            .frame(width: 50)
                        
                        Text("")
                            .font(.system(size: 10))
                            .frame(width: 70, alignment: .trailing)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 6)
                    
                    Divider()
                }
            }
        }
    }
    
    // MARK: - Totals Section
    var totalsSection: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Subtotal")
                    .font(.system(size: 10))
                Spacer()
                Text("")
                    .font(.system(size: 10))
            }
            
            Divider()
            
            HStack {
                Text("Ongkir")
                    .font(.system(size: 10))
                Spacer()
                Text("")
                    .font(.system(size: 10))
            }
            
            Divider()
            
            HStack {
                Text("Total")
                    .font(.system(size: 10, weight: .bold))
                Spacer()
                Text("")
                    .font(.system(size: 10, weight: .bold))
            }
            
            Divider()
            
            HStack {
                Text("Down Payment")
                    .font(.system(size: 10))
                Spacer()
                Text("")
                    .font(.system(size: 10))
            }
        }
        .frame(maxWidth: 250)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.horizontal, 6)
    }
    
    // MARK: - Delivery Details Section
    var deliveryDetailsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Tanggal Kirim :")
                    .font(.system(size: 10))
                Text(viewModel.orderDate.isEmpty ? "" : viewModel.orderDate)
                    .font(.system(size: 10))
                    .underline()
            }
            
            HStack {
                Text("Jam Kirim :")
                    .font(.system(size: 10))
                Text(viewModel.deliveryTime.isEmpty ? "" : viewModel.deliveryTime)
                    .font(.system(size: 10))
                    .underline()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Export Functions
    private func exportAndShare() {
        switch exportFormat {
        case .pdf:
            exportAsPDF()
        case .image:
            exportAsImage()
        }
    }
    
    private func exportAsPDF() {
        let invoiceView = invoiceContent
            .padding(20)
            .background(Color.white)
            .frame(width: 595)
        
        if let pdfData = viewModel.exportAsPDF(view: invoiceView) {
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("Invoice_\(viewModel.generateInvoiceCode().replacingOccurrences(of: "/", with: "_")).pdf")
            
            do {
                try pdfData.write(to: tempURL)
                viewModel.shareInvoice(items: [tempURL]) { success in
                    if success {
                        print("PDF shared successfully")
                    }
                }
            } catch {
                print("Error saving PDF: \(error)")
            }
        }
    }
    
    private func exportAsImage() {
        let invoiceView = invoiceContent
            .padding(20)
            .background(Color.white)
            .frame(width: 595)
        
        if let image = viewModel.exportAsImage(view: invoiceView) {
            viewModel.shareInvoice(items: [image]) { success in
                if success {
                    print("Image shared successfully")
                }
            }
        }
    }
}

enum ExportFormat {
    case pdf
    case image
}

#Preview {
    let session = SessionManager()
    session.isSignedIn = true
    session.userId = "083dc90d-ca03-4f45-a631-06fe21fe750f"
    
    return InvoicePreviewView()
        .environmentObject(session)
}
