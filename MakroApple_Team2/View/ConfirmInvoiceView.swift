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
    @State private var hasDownPayment = false
    @State private var selectedDueDate: Date?
    @State private var expandedProducts = Set<UUID>()
    
    let orderId: String
    @Binding var path: NavigationPath
    @EnvironmentObject var session: SessionManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Rincian Invoice
                InvoiceSectionHeader(title: "Rincian Invoice")
                
                VStack(alignment: .leading, spacing: 12) {
                    InvoiceRowField(label: "No. Invoice", value: $viewModel.invoiceNumber)
                    InvoiceRowField(label: "Tanggal", value: $viewModel.invoiceDate)
                    
                    // Date Picker for Due Date
                    HStack {
                        Text("Tanggal Jatuh Tempo :")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { selectedDueDate ?? Date() },
                                set: { newDate in
                                    selectedDueDate = newDate
                                    let formatter = DateFormatter()
                                    formatter.dateFormat = "dd/MM/yyyy"
                                    viewModel.invoiceDueDate = formatter.string(from: newDate)
                                }
                            ),
                            displayedComponents: .date
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                    }
                }
                .padding()

                // MARK: - Informasi Pembayaran
                InvoiceSectionHeader(title: "Informasi Pembayaran")
                
                VStack(alignment: .leading, spacing: 12) {
                    InvoiceRowField(label: "Nama Akun", value: $viewModel.accountName)
                    InvoiceRowField(label: "Nomor Rekening", value: $viewModel.accountNumber)
                    InvoiceRowField(label: "Nama Bank", value: $viewModel.bankName)
                }
                .padding()

                // MARK: - Tagihan Untuk
                InvoiceSectionHeader(title: "Tagihan Untuk")
                
                VStack(alignment: .leading, spacing: 12) {
                    InvoiceRowField(label: "Nama Pemesan", value: $viewModel.customerName)
                    InvoiceRowField(label: "No Telp Pemesan", value: $viewModel.customerPhone)
                }
                .padding()

                // MARK: - Rincian Pesanan
                InvoiceSectionHeader(title: "Rincian Pesanan")
                
                VStack(alignment: .leading, spacing: 12) {
                    ForEach($viewModel.products) { $item in
                        VStack(alignment: .leading, spacing: 0) {
                            // Collapsible Header
                            Button(action: {
                                withAnimation {
                                    if expandedProducts.contains(item.id) {
                                        expandedProducts.remove(item.id)
                                    } else {
                                        expandedProducts.insert(item.id)
                                    }
                                }
                            }) {
                                HStack {
                                    Text($item.productName.wrappedValue)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: expandedProducts.contains(item.id) ? "chevron.up" : "chevron.down")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                            }
                            
                            // Expanded Content
                            if expandedProducts.contains(item.id) {
                                VStack(alignment: .leading, spacing: 12) {
                                    InvoiceRowField(label: "Jumlah Produk", value: Binding(
                                        get: { String($item.quantity.wrappedValue) },
                                        set: { newValue in
                                            $item.quantity.wrappedValue = Int(newValue) ?? 0
                                        }
                                    ), keyboardType: .numberPad)
                                    
                                    InvoiceRowField(label: "Harga (Rp)", value: Binding(
                                        get: { "\($item.productPrice.wrappedValue)" },
                                        set: { newValue in
                                            $item.productPrice.wrappedValue = Decimal(string: newValue.filter("0123456789.".contains)) ?? 0
                                        }
                                    ), keyboardType: .decimalPad)
                                    
                                    InvoiceRowField(label: "Diskon (Rp)", value: Binding(
                                        get: { "\($item.discount.wrappedValue)" },
                                        set: { newValue in
                                            $item.discount.wrappedValue = Decimal(string: newValue.filter("0123456789.".contains)) ?? 0
                                        }
                                    ), keyboardType: .decimalPad)
                                    
                                    HStack {
                                        Text("Jumlah (Rp) :")
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Text("Rp \($item.wrappedValue.subtotalAfterDiscount.formatted())")
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray5))
                            }
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)

                // MARK: - Rincian Biaya
                InvoiceSectionHeader(title: "Rincian Biaya")
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Subtotal :")
                            .font(.subheadline)
                        Spacer()
                        Text("Rp \(viewModel.totalProductSubtotal.formatted())")
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    
                    InvoiceRowField(label: "Biaya Kirim", value: $viewModel.shippingCostText, keyboardType: .decimalPad)
                    
                    Divider()
                    
                    HStack {
                        Text("Total :")
                            .font(.headline)
                        Spacer()
                        Text("Rp \(viewModel.totalAfterDiscount.formatted())")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Text("Down Payment :")
                            .font(.subheadline)
                        Spacer()
                        TextField("Rp 0,00", text: $viewModel.downPaymentText)
                            .disabled(!hasDownPayment)
                            .frame(width: 120)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                        Toggle("", isOn: $hasDownPayment)
                            .labelsHidden()
                    }
                }
                .padding()

                // MARK: - Rincian Tambahan
                InvoiceSectionHeader(title: "Rincian Tambahan")
                
                VStack(alignment: .leading, spacing: 12) {
                    InvoiceRowField(label: "Nama Penerima", value: $viewModel.receiverName)
                    InvoiceRowField(label: "No Telp Penerima", value: $viewModel.receiverPhone)
                    InvoiceRowField(label: "Alamat Kirim", value: $viewModel.shippingAddress)
                }
                .padding()

                // MARK: - Jadwal Pesanan
                InvoiceSectionHeader(title: "Jadwal Pesanan")
                
                VStack(alignment: .leading, spacing: 12) {
                    InvoiceRowField(label: "Tanggal Pesanan", value: $viewModel.orderDate)
//                    InvoiceRowField(label: "Jam Kirim", value: $viewModel.deliveryTime)
                }
                .padding()

//                // MARK: - Lain - Lain
//                InvoiceSectionHeader(title: "Lain - Lain")
//                
//                VStack(alignment: .leading, spacing: 12) {
//                    InvoiceRowField(label: "Pengiriman", value: $viewModel.shippingOption)
//                    InvoiceRowField(label: "Notes", value: $viewModel.notes)
//                }
//                .padding()

                // MARK: - Referensi Foto
                if !viewModel.photoUrl1.isEmpty {
                    InvoiceSectionHeader(title: "Referensi Foto")
                    
                    AsyncImage(url: URL(string: viewModel.photoUrl1)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.2)
                    }
                    .frame(height: 200)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Rincian Invoice")
        .navigationBarTitleDisplayMode(.inline)
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
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.blue)
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
        .onChange(of: viewModel.didSave) { newValue in
            if newValue {
                path.append(OrderDestination.invoicePreview(orderId: orderId))
            }
        }
    }
}

struct InvoiceSectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
            Spacer()
        }
        .padding(.horizontal)
    }
}

struct InvoiceRowField: View {
    let label: String
    @Binding var value: String
    var keyboardType: UIKeyboardType = .default
    var hasError: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 12) {
                Text("\(label) :")
                    .frame(width: 140, alignment: .trailing)
                    .font(.body)
                    .foregroundColor(.primary)
                
                TextField("Silakan isi kolom", text: $value)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.white))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                hasError ? Color.red : Color(.systemGray4),
                                lineWidth: hasError ? 2 : 1
                            )
                    )
                    .keyboardType(keyboardType)
            }
            
            if hasError {
                HStack {
                    Spacer().frame(width: 140)
                    Text("Field ini wajib diisi")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.leading, 12)
                    Spacer()
                }
            }
        }
        .padding(.horizontal)
    }
}



//#Preview {
//    let session = SessionManager()
//    session.isSignedIn = true
//    session.userId = "083dc90d-ca03-4f45-a631-06fe21fe750f"
//    
//    return NavigationStack {
//        ConfirmInvoiceView(orderId: "82536742-DDC4-481C-B63A-87400194D0AA")
//            .environmentObject(session)
//    }
//}
