//
//  ConfirmInvoiceView.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 04/11/25.
//

import SwiftUI
import Foundation
import PhotosUI

struct ConfirmInvoiceView: View {
    @State private var viewModel = ConfirmInvoiceViewModel()
    @State private var hasDownPayment = true
    
    let orderId: String
    @EnvironmentObject var session: SessionManager
    
    func supabasePublicUrl(for path: String) -> String {
        "https://<your-project-ref>.supabase.co/storage/v1/object/public/\(path)"
    }
    
    var body: some View {
        
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                GroupBox(label: Text("Rincian Invoice").font(.headline)) {
                    InvoiceRow(title: "No. Invoice", value: $viewModel.invoiceNumber)
                    InvoiceRow(title: "Tanggal", value: $viewModel.invoiceDate)
                    InvoiceRow(title: "Tanggal Jatuh Tempo", value: $viewModel.invoiceDueDate)
                }

                GroupBox(label: Text("Informasi Pembayaran").font(.headline)) {
                    InvoiceRow(title: "Nama Akun", value: $viewModel.accountName)
                    InvoiceRow(title: "Nomor Rekening", value: $viewModel.accountNumber)
                    InvoiceRow(title: "Nama Bank", value: $viewModel.bankName)
                }

                GroupBox(label: Text("Tagihan Untuk").font(.headline)) {
                    InvoiceRow(title: "Nama Pemesan", value: $viewModel.customerName)
                    InvoiceRow(title: "No Telp Pemesan", value: $viewModel.customerPhone)
                }

                GroupBox(label: Text("Rincian Pesanan").font(.headline)) {
                    ForEach($viewModel.products) { $item in
                        VStack(alignment: .leading, spacing: 6) {
                            InvoiceRow(title: "Nama Produk", value: $item.productName)
                            InvoiceRow(title: "Jumlah Produk", value: Binding(
                                get: { String($item.quantity.wrappedValue) },
                                set: { newValue in
                                    $item.quantity.wrappedValue = Int(newValue) ?? 0
                                }
                            ))
                            InvoiceRow(title: "Harga (Rp)", value: Binding(
                                get: { "\($item.productPrice.wrappedValue)" },
                                set: { newValue in
                                    $item.productPrice.wrappedValue = Decimal(string: newValue.filter("0123456789.".contains)) ?? 0
                                }
                            ))
                            InvoiceRow(title: "Diskon (Rp)", value: .constant("0"))
                            HStack {
                                Text("Subtotal (Rp) :")
                                Spacer()
                                Text($item.wrappedValue.subtotal.formatted())
                                    .font(.body)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                        .padding(.vertical, 4)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                    }

                    // ADD ONS
//                            GroupBox(label: Text("Adds On").font(.headline)) {
//                                if viewModel.addOn.isEmpty {
//                                    Text("Tidak ada add-on.")
//                                        .foregroundColor(.secondary)
//                                        .italic()
//                                        .padding(.vertical, 8)
//                                } else {
//                                    ForEach($viewModel.addOn) { $addOn in
//                                        VStack(alignment: .leading, spacing: 6) {
//                                            InvoiceRow(title: "Nama Add On", value: $addOn.name)
//                                            InvoiceRow(title: "Jumlah Add On", value: .constant("\($addOn.quantity.wrappedValue)"))
//                                        }
//                                        .padding(.vertical, 4)
//                                        .background(Color(.systemGray5))
//                                        .cornerRadius(8)
//                                    }
//                                }
//                            }
                }

                
                GroupBox(label: Text("Rincian Biaya").font(.headline)) {
                    InvoiceRow(title: "Subtotal (Rp)", value: .constant(viewModel.totalProductSubtotal.formatted()))
                    InvoiceRow(title: "Biaya Kirim (Rp)", value: $viewModel.shippingCostText)
                    InvoiceRow(title: "Total (Rp)", value: .constant(viewModel.total.formatted()))

                    HStack {
                        Text("Down Payment :")
                        Spacer()
                        TextField("Rp 0,00", text: $viewModel.downPaymentText)
                            .disabled(!hasDownPayment)
                            .frame(width: 120)
                            .textFieldStyle(.roundedBorder)
                        Toggle("", isOn: $hasDownPayment)
                            .labelsHidden()
                    }
                }

                GroupBox(label: Text("Rincian Tambahan").font(.headline)) {
                    InvoiceRow(title: "Nama Penerima", value: $viewModel.receiverName)
                    InvoiceRow(title: "No Telp Penerima", value: $viewModel.receiverPhone)
                    InvoiceRow(title: "Alamat Kirim", value: $viewModel.shippingAddress)
                }

                GroupBox(label: Text("Jadwal Pesanan").font(.headline)) {
                    InvoiceRow(title: "Tanggal Pesanan", value: $viewModel.orderDate)
                    InvoiceRow(title: "Jam Kirim", value: $viewModel.deliveryTime)
                }

                GroupBox(label: Text("Lain - Lain").font(.headline)) {
                    InvoiceRow(title: "Add-on", value: $viewModel.addOn)
                    InvoiceRow(title: "Pengiriman", value: $viewModel.shippingOption)
                    InvoiceRow(title: "Notes", value: $viewModel.notes)
                }

                if !viewModel.photoUrl1.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Referensi Foto")
                        AsyncImage(url: URL(string: supabasePublicUrl(for: viewModel.photoUrl1))) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray.opacity(0.2)
                        }
                        .frame(height: 120)
                        .cornerRadius(10)
                    }
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle("Rincian Invoice")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        do {
                            try await viewModel.onConfirmInvoice(hasDownPayment: hasDownPayment)
                        } catch {
                            print("Failed to confirm invoice: \(error)")
                        }
                    }
                } label: {
                    Image(systemName: "arrow.right")
                        .padding(8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
            }
        }
        .task {
            viewModel.configure(userId: session.userId, orderId: orderId)
            if let uuid = UUID(uuidString: orderId) {
                await viewModel.fetchOrderAndItems(orderId: uuid)
            }
        }
        .onDisappear {
            if !hasDownPayment {
                viewModel.downPaymentText = ""
            }
        }
        .navigationDestination(isPresented: $viewModel.didSave) {
            InvoicePreviewView(orderId: orderId)
        }
    }
}

// MARK: - UI Rows
struct InvoiceRow: View {
    let title: String
    @Binding var value: String
    var body: some View {
        HStack {
            Text("\(title) :")
            Spacer()
            HStack(spacing: 12) {
                TextField("", text: $value)
                    .frame(width: 140, alignment: .trailing)
                    .font(.body)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
            }
        }
    }
}

struct InvoiceMultiRow: View {
    let title: String
    let value: String
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(title) :")
            if !value.isEmpty {
                Text(value)
                    .font(.callout)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
        }
    }
}

#Preview {
    let session = SessionManager()
    session.isSignedIn = true
    session.userId = "083dc90d-ca03-4f45-a631-06fe21fe750f"
    
    return ConfirmInvoiceView(orderId: "")
        .environmentObject(session)
}

