//
//  Set_NewTemplateFormView.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 10/11/25.
//

import SwiftUI
import Foundation

struct Set_NewTemplateFormView: View {
    @State private var formPesanan = ""
    @State private var viewModel = Set_NewTemplateViewModel()
    @EnvironmentObject var session: SessionManager
    @Environment(\.dismiss) private var dismiss
    
    @Binding var isDismissed: Bool

//    var onAfterSave: (() -> Void)? = nil

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(alignment: .leading) {
                        
                        Text("Masukan/Buat Formulir Pesanan")
                            .font(.title3)
                            .fontWeight(.bold)

                        TextEditor(text: $formPesanan)
                            .padding(3)
                            .frame(height: geometry.size.height / 3)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(5), lineWidth: 0.5)
                            )
                            .overlay(
                                Group {
                                    if formPesanan.isEmpty {
                                        Text("""
Paste or write your Form Order here ✨(e.g. for your F&B or custom order form)

Example:
Nama Pemesan:
No. Telp Pemesan:
Nama Penerima:
No. Telp Penerima:
Alamat Kirim:
Tanggal Pesanan:
Jam Kirim:
Pesanan:
Adds-on:
Wish / Greeting:
Pengiriman: Kurir / Pickup
Notes:
Foto Referensi (optional):
""")
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 12)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .allowsHitTesting(false)
                                    }
                                }
                            )

//                        if let json = viewModel.resultJSON {
//                            Text("✅ Template JSON:")
//                                .font(.headline)
//                                .padding(.top)
//                            ScrollView {
//                                Text(json)
//                                    .font(.system(.caption, design: .monospaced))
//                                    .padding()
//                                    .background(Color(.secondarySystemBackground))
//                                    .cornerRadius(10)
//                            }
//                        }

                        if let error = viewModel.errorMessage {
                            Text("❌ Error: \(error)")
                                .foregroundColor(.red)
                                .padding(.top)
                        }
                    }
                    .padding()
                }

                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            Task {
                                await viewModel.generateTemplate(from: formPesanan)
                            }
                        } label: {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .frame(width: 32, height: 32)
                                    .background(
                                        Circle().fill(Color.blue)
                                    )
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(
                                        Circle().fill(Color.blue)
                                    )
                            }
                        }
                        .buttonStyle(.glassProminent)
                        .tint(.primaryButton)
                        .disabled(formPesanan.isEmpty || viewModel.isLoading)
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            isDismissed = true
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                                .foregroundColor(.primaryButton)
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $viewModel.didSave) {
                Set_EditTemplateFormView(isDismissed: $isDismissed)
            }
        }
            
        .task { viewModel.configure(userId: session.userId) }
    }
}

//#Preview {
//    let session = SessionManager()
//    session.isSignedIn = true
//    session.userId = "083dc90d-ca03-4f45-a631-06fe21fe750f"
//
//    return NavigationStack {
//        Set_NewTemplateFormView()
//            .environmentObject(session)
//    }
//}
