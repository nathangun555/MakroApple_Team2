//
//  InvoicePreviewView.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 24/10/25.
//

import SwiftUI

struct InvoicePreviewView: View {
    @State var viewModel = InvoicePreviewViewModel()
    @EnvironmentObject var session: SessionManager
    @Environment(\.dismiss) var dismiss
    
    let orderId: String?
    
    @State private var isSaving = false
    @State private var showSuccessAlert = false
    
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
                        
                        Button("Coba Lagi") {
                            Task {
                                await viewModel.loadInvoiceData()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    VStack(spacing: 0) {
                        ScrollView {
                            InvoiceContentView(viewModel: viewModel)
                                .padding(20)
                                .background(Color.white)
                        }
                        .background(Color(.systemGray6))
                        
                        if !viewModel.isPreviewMode {
                            VStack(spacing: 0) {
                                Divider()
                                
                                Button {
                                    Task {
                                        await saveInvoiceAndDismiss()
                                    }
                                } label: {
                                    if isSaving {
                                        HStack {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle())
                                            Text("Menyimpan...")
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                    } else {
                                        Text("Simpan Invoice")
                                            .font(.headline)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                    }
                                }
                                .disabled(isSaving)
                                .background(isSaving ? Color.gray : Color.blue)
                                .foregroundColor(.white)
                            }
                            .background(Color(.systemBackground))
                        }
                    }
                }
            }
            .navigationTitle(viewModel.isPreviewMode ? "Preview Invoice" : "Invoice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(action: {
                            viewModel.exportFormat = .pdf
                            exportAndShare()
                        }) {
                            Label("Export as PDF", systemImage: "doc.fill")
                        }
                        
                        Button(action: {
                            viewModel.exportFormat = .image
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
            viewModel.configure(userId: session.userId, orderId: orderId)
            await viewModel.loadInvoiceData()
        }
    }
    
    // MARK: - Save Invoice and Dismiss
    func saveInvoiceAndDismiss() async {
        isSaving = true
        defer { isSaving = false }
        
        let invoiceView = InvoiceContentView(viewModel: viewModel)
            .padding(20)
            .background(Color.white)
            .frame(width: 595)
        
        guard let image = viewModel.exportAsImage(view: invoiceView) else {
            viewModel.errorMessage = "Gagal membuat gambar invoice"
            return
        }
        
        do {
            let url = try await viewModel.saveAndUploadInvoice(image: image)
            print("✅ Invoice saved to: \(url)")
            
            dismiss()
            
        } catch {
            viewModel.errorMessage = "Gagal menyimpan invoice: \(error.localizedDescription)"
            print("❌ Error saving invoice: \(error)")
        }
    }
    
    // MARK: - Export Functions
    func exportAndShare() {
        switch viewModel.exportFormat {
        case .pdf:
            exportAsPDF()
        case .image:
            exportAsImage()
        }
    }
    
    func exportAsPDF() {
        let invoiceView = InvoiceContentView(viewModel: viewModel)
            .padding(20)
            .background(Color.white)
            .frame(width: 595)
        
        if let pdfData = viewModel.exportAsPDF(view: invoiceView) {
            let invoiceCode = viewModel.invoiceNumber.isEmpty ? "Invoice" : viewModel.invoiceNumber
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(invoiceCode.replacingOccurrences(of: "/", with: "_")).pdf")
            
            do {
                try pdfData.write(to: tempURL)
                viewModel.shareInvoice(items: [tempURL]) { success in
                    if success {
                        print("✅ PDF shared successfully")
                    }
                }
            } catch {
                print("❌ Error saving PDF: \(error)")
            }
        }
    }

    func exportAsImage() {
        let invoiceView = InvoiceContentView(viewModel: viewModel)
            .padding(20)
            .background(Color.white)
            .frame(width: 595)
        
        if let image = viewModel.exportAsImage(view: invoiceView) {
            viewModel.shareInvoice(items: [image]) { success in
                if success {
                    print("✅ Image shared successfully")
                }
            }
        }
    }
}

#Preview {
    let session = SessionManager()
    session.isSignedIn = true
    session.userId = "083dc90d-ca03-4f45-a631-06fe21fe750f"
    
    return InvoicePreviewView(orderId: nil)
        .environmentObject(session)
}
