//
//  InvoicePreviewView.swift
//  MakroApple_Team2
//
//  Created by Assistant on 24/10/25.
//

import SwiftUI

struct InvoicePreviewView: View {
    @State var viewModel = InvoicePreviewViewModel()
    @EnvironmentObject var session: SessionManager
    @Environment(\.dismiss) var dismiss
    
    
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
            viewModel.configure(userId: session.userId)
            await viewModel.loadInvoiceData()
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

    func exportAsImage() {
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

#Preview {
    let session = SessionManager()
    session.isSignedIn = true
    session.userId = "083dc90d-ca03-4f45-a631-06fe21fe750f"
    
    return InvoicePreviewView()
        .environmentObject(session)
}
