//
//  InvoicePreviewView.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 24/10/25.
//

import SwiftUI

struct InvoicePreviewView: View {
    @State var viewModel = InvoicePreviewViewModel()
    @State var invoiceData = InvoiceData()
    @EnvironmentObject var session: SessionManager
    @Environment(\.dismiss) var dismiss
    
    @State var orderId: String?
    
    @State private var isLoading = false
    @State private var isSaving = false
    @State private var showSuccessAlert = false
    
    @State private var exportedPDFURL: URL?
    
    @Binding var isDismissed: Bool
    
    
    
    var body: some View {
        NavigationStack{
            
            ZStack {
                if viewModel.isLoading {
                    LoadingView(context: "invoice")
//                    ProgressView("Memuat invoice...")
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
                    ZStack(alignment: .bottom) {
                        if let pdfURL = exportedPDFURL {
                            // ✅ Show the exported PDF
                            PDFKitView(url: pdfURL)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            // 🔄 While PDF not generated yet, show loading or placeholder
                            ProgressView("Membuat preview invoice...")
                            //                                .onAppear {
                            //                                    if exportedPDFURL == nil {
                            //                                        exportedPDFURL = exportAsPDF()
                            //                                    }
                            //                                }
                        }
                        
                        if !viewModel.isPreviewMode {
                            VStack(spacing: 0) {
                                Button {
                                    Task {
                                        await saveInvoiceAndDismiss()
                                    }
                                } label: {
                                    if isSaving {
                                        HStack {
                                            ProgressView()
                                            Text("Menyimpan...")
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                    } else {
                                        Text("Selesai")
                                            .frame(maxWidth: .infinity)
                                            .bold()
                                            .padding()
                                            .foregroundColor(.white)
                                            .glassEffect(.clear.tint(.primaryButton), in: .rect(cornerRadius: 30))
                                            .padding(.horizontal)
                                            .padding(.bottom)
                                    }
                                }
                                .disabled(isSaving)
                            }
                        }
                    }
                    
                }
            }
            .onTapGesture {
                hideKeyboard()
            }
            .navigationTitle(viewModel.isPreviewMode ? "Preview Invoice" : "Invoice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !viewModel.isPreviewMode {
                        Button(action: {
                            viewModel.exportFormat = .pdf
                            if let pdfURL = exportedPDFURL {
                                viewModel.shareInvoice(items: [pdfURL]) { success in
                                    print("✅ PDF shared")
                                }
                            }
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(.primaryButton)
                    }
                    
                    else {
                        Button(action: {
                            isDismissed = true
                        }) {
                            Image(systemName: "checkmark")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(.primaryButton)
                    }
                }
            }
            
            
            .task {
                viewModel.configure(userId: session.userId, orderId: orderId)
                await viewModel.loadInvoiceData()
                
                exportedPDFURL = viewModel.tempPDFURL()
                
                invoiceData = viewModel.invoiceData
            }
        }
        
    }
    
    // MARK: - Save Invoice and Dismiss
    func saveInvoiceAndDismiss() async {
        isSaving = true
        defer { isSaving = false }
        
        let invoiceView = InvoiceContentView(viewModel: invoiceData)
            .padding(20)
            .background(Color.white)
            .frame(width: 595)
        
        guard let pdfData = viewModel.exportAsPDF(view: invoiceView) else {
            viewModel.errorMessage = "Gagal membuat PDF invoice"
            return
        }
        
        do {
            let url = try await viewModel.saveAndUploadInvoice(pdfData: pdfData)
            print("✅ Invoice saved to: \(url)")
            
            isDismissed = true
            
        } catch {
            viewModel.errorMessage = "Gagal menyimpan invoice: \(error.localizedDescription)"
            print("❌ Error saving invoice: \(error)")
        }
    }
    
    
//    func exportAsPDF() -> URL? {
//        let invoiceView = InvoiceContentView(viewModel: viewModel)
//            .padding(20)
//            .background(Color.white)
//            .frame(width: 595, height: 841)
//
//        guard let pdfData = viewModel.exportAsPDF(view: invoiceView) else {
//            return nil
//        }
//
//        let invoiceCode = viewModel.invoiceNumber.isEmpty ? "Invoice" : viewModel.invoiceNumber
//        let tempURL = FileManager.default.temporaryDirectory
//            .appendingPathComponent("\(invoiceCode.replacingOccurrences(of: "/", with: "_")).pdf")
//
//        do {
//            try pdfData.write(to: tempURL)
//            return tempURL
//        } catch {
//            print("❌ Error saving PDF: \(error)")
//            return nil
//        }
//    }
    
    
//    func sharePDF() {
//        if let pdfURL = exportAsPDF() {
//            viewModel.shareInvoice(items: [pdfURL]) { success in
//                if success {
//                    print("✅ PDF shared successfully")
//                }
//            }
//        } else {
//            print("❌ Failed to generate PDF for sharing")
//        }
//    }
    
}

//#Preview {
//    let session = SessionManager()
//    session.isSignedIn = true
//    session.userId = "083dc90d-ca03-4f45-a631-06fe21fe750f"
//
//    return InvoicePreviewView(orderId: "82536742-DDC4-481C-B63A-87400194D0AA")
//        .environmentObject(session)
//}
