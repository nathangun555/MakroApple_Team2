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
        
        @State private var showValidationError = false


        
        let orderId: String
        @Binding var isDismissed: Bool
        @EnvironmentObject var session: SessionManager
        

        
        var body: some View {
            ScrollView {
                VStack {
                    // MARK: - Rincian Invoice
                    InvoiceSectionHeader(title: "Rincian Invoice")
                    
                    VStack {
                        InvoiceRowField(label: "No. Invoice", value: $viewModel.invoiceNumber, isEditable: false)
                        InvoiceRowField(label: "Tanggal", value: $viewModel.invoiceDate, isEditable: false)
                        
                        // Date Picker for Due Date
                        HStack {
                            Text("Tanggal Jatuh Tempo")
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
                    }
                    .padding(.bottom)

                    // MARK: - Rincian Pesanan
                    InvoiceSectionHeader(title: "Rincian Pesanan")
                    
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach($viewModel.products) { $item in
                            VStack(alignment: .leading, spacing: 0) {

                                HStack {
                                    Text($item.productName.wrappedValue)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)

                                    Spacer()
                                }
                                .padding()
                                .background(.deadlineCard)
                                
                                Divider()
                                // Always-expanded content
                                VStack(alignment: .leading, spacing: 12) {

                                    InvoiceRowField(
                                        label: "Jumlah Produk",
                                        value: Binding(
                                            get: {
                                                if focusedField == .quantity(item.id), $item.quantity.wrappedValue == 0 {
                                                    return ""
                                                }
                                                return String($item.quantity.wrappedValue)
                                            },
                                            set: { newValue in
                                                $item.quantity.wrappedValue = Int(newValue) ?? 0
                                            }
                                        ),
                                        keyboardType: .numberPad,
                                        hasError: showValidationError && item.quantity == 0
                                    )
                                    .focused($focusedField, equals: .quantity(item.id))
                                    .onTapGesture { focusedField = .quantity(item.id) }

                                    // Harga
                                    InvoiceRowField(
                                        label: "Harga",
                                        value: Binding(
                                            get: {
                                                let val = $item.productPrice.wrappedValue
                                                return focusedField == .price(item.id)
                                                    ? (val == 0 ? " Rp " : " \(val.formatted(.currency(code: "IDR")))") :
                                                      " \(val.formatted(.currency(code: "IDR")))"
                                            },
                                            set: { newValue in
                                                let clean = newValue.filter("0123456789".contains)
                                                $item.productPrice.wrappedValue = Decimal(string: clean) ?? 0
                                            }
                                        ),
                                        keyboardType: .numberPad,
                                        hasError: showValidationError && item.productPrice == 0

                                    )
                                    .focused($focusedField, equals: .price(item.id))
                                    .onTapGesture { focusedField = .price(item.id) }

                                    // Diskon
                                    InvoiceRowField(
                                        label: "Diskon",
                                        value: Binding(
                                            get: {
                                                let val = $item.discount.wrappedValue
                                                return focusedField == .discount(item.id)
                                                    ? (val == 0 ? " Rp " : " \(val.formatted(.currency(code: "IDR")))") :
                                                      " \(val.formatted(.currency(code: "IDR")))"
                                            },
                                            set: { newValue in
                                                let clean = newValue.filter("0123456789".contains)
                                                let val = Decimal(string: clean) ?? 0
                                                let price = $item.productPrice.wrappedValue
                                                let qty = $item.quantity.wrappedValue

                                                $item.discount.wrappedValue = applyDiscountLimit(price, qty, val)
                                            }

                                        ),
                                        keyboardType: .numberPad
                                    )
                                    .focused($focusedField, equals: .discount(item.id))
                                    .onTapGesture { focusedField = .discount(item.id) }

                                }
                                .padding()
                                .background(.deadlineCard)
                            }
                        }
                    }
    //                .padding()
                    .cornerRadius(10)
                    .padding(.bottom)

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
                    .padding(.bottom)
                }
                .padding(.horizontal)
            }
            .navigationTitle("Rincian Invoice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if viewModel.hasInvalidProduct {
                            withAnimation {
                                showValidationError = true
                            }
                            return
                        }
                        
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

private func applyDiscountLimit(_ price: Decimal, _ qty: Int, _ newVal: Decimal) -> Decimal {
    let maxDiscount = price * Decimal(qty)
    return min(newVal, maxDiscount)
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
        }
    }

    struct InvoiceRowField: View {
        let label: String
        @Binding var value: String
        var keyboardType: UIKeyboardType = .default
        var hasError: Bool = false
        var isEditable: Bool = true
        
        var body: some View {
            VStack(alignment: .leading) {
                HStack {
                    Text("\(label)")
                        .frame(width: 140, alignment: .leading)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Text(":")

                    TextField("Silakan isi kolom", text: $value)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            isEditable
                                ? Color.white
                                : Color(.systemGray5)
                        )
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    hasError ? Color.red : Color(.systemGray4),
                                    lineWidth: hasError ? 2 : 1
                                )
                        )
                        .foregroundColor(isEditable ? .primary : .gray)
                        .keyboardType(keyboardType)
                        .disabled(!isEditable)
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

