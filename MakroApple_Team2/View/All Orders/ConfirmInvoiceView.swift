    //
    //  ConfirmInvoiceView.swift
    //  MakroApple_Team2
    //
    //  Created by Alfred Hans Witono on 04/11/25.
    //

    import SwiftUI
    import Foundation
    import PhotosUI

    private enum ProductField: Hashable {
        case price(UUID)
        case discount(UUID)
        case quantity(UUID)
        case shipping
        case downPayment
    }


    struct ConfirmInvoiceView: View {
        @State private var viewModel = ConfirmInvoiceViewModel()
        @State private var hasDownPayment = false
        @State private var selectedDueDate: Date?
        @State private var expandedProducts = Set<UUID>()
        
        @FocusState private var focusedField: ProductField?

        
        let orderId: String
        @Binding var isDismissed: Bool
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
                                .frame(width: 140, alignment: .leading)
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            DatePicker(
                                "",
                                selection: Binding(
                                    get: { selectedDueDate ?? Date() },
                                    set: { newDate in
                                        selectedDueDate = newDate
                                        viewModel.invoiceDueDate = DateFormatterHelper.isoDateString(from: newDate)
                                    }
                                ),
                                displayedComponents: .date
                            )
                            .labelsHidden()
                            .datePickerStyle(.compact)
                        }
    //                    .padding(.horizontal)
                    }
                    .padding(.horizontal)

                    // MARK: - Informasi Pembayaran
                    InvoiceSectionHeader(title: "Informasi Pembayaran")
                    
                    VStack(alignment: .leading, spacing: 12) {
                        InvoiceRowField(label: "Nama Akun", value: $viewModel.accountName)
                        InvoiceRowField(label: "Nomor Rekening", value: $viewModel.accountNumber)
                        InvoiceRowField(label: "Nama Bank", value: $viewModel.bankName)
                    }
                    .padding(.horizontal)

                    // MARK: - Tagihan Untuk
                    InvoiceSectionHeader(title: "Tagihan Untuk")
                    
                    VStack(alignment: .leading, spacing: 12) {
                        InvoiceRowField(label: "Nama Pemesan", value: $viewModel.customerName)
                        InvoiceRowField(label: "No Telp Pemesan", value: $viewModel.customerPhone)
                    }
                    .padding(.horizontal)

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
                                        InvoiceRowField(
                                            label: "Jumlah Produk",
                                            value: Binding(
                                                get: {
                                                    // kalau sedang fokus dan nilai 0, tampilkan string kosong
                                                    if focusedField == .quantity(item.id), $item.quantity.wrappedValue == 0 {
                                                        return ""
                                                    }
                                                    return String($item.quantity.wrappedValue)
                                                },
                                                set: { newValue in
                                                    $item.quantity.wrappedValue = Int(newValue) ?? 0
                                                }
                                            ),
                                            keyboardType: .numberPad
                                        )
                                        .focused($focusedField, equals: .quantity(item.id))
                                        .onTapGesture { focusedField = .quantity(item.id) }
                                        
                                        
                                        // Harga
                                        InvoiceRowField(
                                            label: "Harga",
                                            value: Binding(
                                                get: {
                                                    let val = $item.productPrice.wrappedValue
                                                    if focusedField == .price(item.id) {
                                                        return val == 0 ? " Rp " : " \(val.formatted(.currency(code: "IDR")))"
                                                    } else {
                                                        return " \(val.formatted(.currency(code: "IDR")))"
                                                    }
                                                },
                                                set: { newValue in
                                                    let clean = newValue.filter("0123456789".contains)
                                                    $item.productPrice.wrappedValue = Decimal(string: clean) ?? 0
                                                }
                                            ),
                                            keyboardType: .numberPad
                                        )
                                        .focused($focusedField, equals: .price(item.id))
                                        .onTapGesture { focusedField = .price(item.id) }

                                        // Diskon
                                        InvoiceRowField(
                                            label: "Diskon",
                                            value: Binding(
                                                get: {
                                                    let val = $item.discount.wrappedValue
                                                    if focusedField == .discount(item.id) {
                                                        return val == 0 ? " Rp " : " \(val.formatted(.currency(code: "IDR")))"
                                                    } else {
                                                        return " \(val.formatted(.currency(code: "IDR")))"
                                                       
                                                    }
                                                },
                                                set: { newValue in
                                                    let clean = newValue.filter("0123456789".contains)
                                                    $item.discount.wrappedValue = Decimal(string: clean) ?? 0
                                                }
                                            ),
                                            keyboardType: .numberPad
                                        )
                                        .focused($focusedField, equals: .discount(item.id))
                                        .onTapGesture { focusedField = .discount(item.id) }


                                        
                                        
                                    }
                                    .padding()
                                    .background(Color(.systemGray5))
                                }
                            }
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
    //                .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // MARK: - Rincian Biaya
                    InvoiceSectionHeader(title: "Rincian Biaya")
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Subtotal :")
                                .frame(width: 140, alignment: .leading)
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            Text("Rp \(viewModel.totalProductSubtotal.formatted())")
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        
                        // Biaya Kirim
                        InvoiceRowField(
                            label: "Biaya Kirim",
                            value: Binding(
                                get: {
                                    let val = Decimal(string: viewModel.shippingCostText) ?? 0
                                    if focusedField == .shipping { // dummy UUID untuk fokus
                                        return val == 0 ? " Rp " : " \(val.formatted(.currency(code: "IDR")))"
                                    } else {
                                        return " \(val.formatted(.currency(code: "IDR")))"
                                    }
                                },
                                set: { newValue in
                                    let clean = newValue.filter("0123456789".contains)
                                    viewModel.shippingCostText = clean
                                }
                            ),
                            keyboardType: .numberPad
                        )
                        .focused($focusedField, equals: .shipping)
                        .onTapGesture { focusedField = .shipping }

                        
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
                                .font(.body)
                            
                            Spacer()
                            
                            TextField("Rp 0,00",
                                      text: Binding(
                                        get: {
                                            let val = Decimal(string: viewModel.downPaymentText) ?? 0
                                            if focusedField == .downPayment { // gunakan UUID statis atau case tanpa UUID
                                                return val == 0 ? " Rp " : " \(val.formatted(.currency(code: "IDR")))"
                                            } else {
                                                return " \(val.formatted(.currency(code: "IDR")))"
                                            }
                                        },
                                        set: { newValue in
                                            let clean = newValue.filter("0123456789".contains)
                                            viewModel.downPaymentText = clean
                                        }
                                      )
                            )
                            .disabled(!hasDownPayment)
                            .frame(width: 120)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .downPayment)
                            .onTapGesture { focusedField = .downPayment }
                            
                            Toggle("", isOn: $hasDownPayment)
                                .labelsHidden()
                        }

                    }
                    .padding(.horizontal)

                    // MARK: - Rincian Tambahan
                    InvoiceSectionHeader(title: "Rincian Tambahan")
                    
                    VStack(alignment: .leading, spacing: 12) {
                        InvoiceRowField(label: "Nama Penerima", value: $viewModel.receiverName)
                        InvoiceRowField(label: "No Telp Penerima", value: $viewModel.receiverPhone)
                        InvoiceRowField(label: "Alamat Kirim", value: $viewModel.shippingAddress)
                    }
                    .padding(.horizontal)

                    // MARK: - Jadwal Pesanan
                    InvoiceSectionHeader(title: "Jadwal Pesanan")
                    
                    VStack(alignment: .leading, spacing: 12) {
                        InvoiceRowField(label: "Tanggal Pesanan", value: $viewModel.orderDate)
    //                    InvoiceRowField(label: "Jam Kirim", value: $viewModel.deliveryTime)
                    }
                    .padding(.horizontal)

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
                .padding(.horizontal)
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
                        Image(systemName: "chevron.right")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.primaryButton)
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
                InvoicePreviewView(orderId: orderId, isDismissed: $isDismissed)
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
    //        .padding(.horizontal)
        }
    }

    struct InvoiceRowField: View {
        let label: String
        @Binding var value: String
        var keyboardType: UIKeyboardType = .default
        var hasError: Bool = false
        
        var body: some View {
            VStack(alignment: .leading) {
                HStack {
                    Text("\(label) :")
                        .frame(width: 140, alignment: .leading)
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
    //        .padding(.horizontal)
        }
    }


    #Preview {
        let session = SessionManager()
        session.isSignedIn = true
        session.userId = "083dc90d-ca03-4f45-a631-06fe21fe750f"

        return NavigationStack {
            ConfirmInvoiceView(
                orderId: "82536742-DDC4-481C-B63A-87400194D0AA",
                isDismissed: .constant(false)
            )
            .environmentObject(session)
        }
    }

