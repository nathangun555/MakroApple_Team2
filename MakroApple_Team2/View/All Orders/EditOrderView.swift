//
//  EditOrderView.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 30/10/25.
//

import SwiftUI
import PhotosUI
import Foundation

enum ProductField: Hashable {
    case price(UUID)
    case discount(UUID)
    case quantity(UUID)
    case shipping
    case downPayment
}

struct EditOrderView: View {
    
    var parsedOrderData: [String: Any]
    
    @Binding var selectedImages: [UIImage?]
    @Binding var selectedItems: [PhotosPickerItem?]
    
    @Binding var isDismissed: Bool
    @State private var viewModel = EditOrderViewModel()
    
    @State private var lastOrderId: String = ""
    @FocusState private var focusedField: String?
    @State private var firstErrorId: String?
    
    @State private var navigateToInvoicePreview = false
    
    // ✅ TAMBAH: State untuk delete alert
    @State private var showDeleteProductAlert = false
    @State private var deleteProductIndex: Int?
    
    // Invoice-related states
    @State private var hasDownPayment = false
    @State private var hasDueDate: Bool = true
    @State private var showValidationError = false
    
    // Product editing states
    @State private var showEditProduct = false
    @State private var showProductSelection = false
    @State private var selectedProductIndex: Int = 0
    
    @FocusState private var invoiceFocusedField: ProductField?

    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var deleteBus: DeleteOverlayBus
    @Environment(\.dismiss) var dismiss
    
    var hasEmptyFields: Bool {
        if viewModel.customerFields.contains(where: { $0.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) { return true }
        if viewModel.scheduleFields.contains(where: { $0.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) { return true }
        if viewModel.otherFields.contains(where: { $0.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) { return true }

        if viewModel.products.contains(where: { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) { return true }
        if viewModel.products.contains(where: { $0.quantity <= 0 }) { return true }

        return false
    }

    var body: some View {
        ZStack {
            if viewModel.isLoading {
                LoadingView(context: "pesanan")
                    .navigationBarHidden(true)
            } else {
                List {
                            // Rincian Pelanggan
                    Section("Rincian Pelanggan") {
                        ForEach(Array(viewModel.customerFields.enumerated()), id: \.offset) { index, field in
                            let key = "customer-\(index)"
                            OrderFieldRow(
                                field: Binding(
                                    get: { viewModel.customerFields[index] },
                                    set: { viewModel.customerFields[index] = $0 }
                                ),
                                fieldKey: key,
                                fieldErrors: viewModel.fieldErrors,
                                focusedField: $focusedField
                            )
                            .id(key)
                        }
                    }
                    
                    // Jadwal Pesanan
                    Section("Jadwal Pesanan") {
                        ForEach(Array(viewModel.scheduleFields.enumerated()), id: \.offset) { index, field in
                            let key = "schedule-\(index)"
                            OrderFieldRow(
                                field: Binding(
                                    get: { viewModel.scheduleFields[index] },
                                    set: { viewModel.scheduleFields[index] = $0 }
                                ),
                                fieldKey: key,
                                fieldErrors: viewModel.fieldErrors,
                                focusedField: $focusedField
                            )
                            .id(key)
                        }
                    }
                    
                    // Detail Invoice
                    Section("Detail Invoice") {
                        HStack {
                            Text("No. Invoice")
                            Spacer()
                            Text(viewModel.invoiceNumber)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Tanggal")
                            Spacer()
                            Text(viewModel.invoiceDate)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Jatuh Tempo Pembayaran")
                            Spacer()
                            
                            DatePicker(
                                "",
                                selection: Binding(
                                    get: {
                                        if let dueDateStr = viewModel.invoiceDueDate,
                                           let date = DateFormatterHelper.parseIndonesianDate(dueDateStr) {
                                            return Calendar.current.startOfDay(for: date)
                                        }
                                        return Calendar.current.startOfDay(for: Date())
                                    },
                                    set: { newDate in
                                        viewModel.invoiceDueDate = DateFormatterHelper.formatIndonesianDate(newDate)
                                    }
                                ),
                                in: Date()...,
                                displayedComponents: .date
                            )
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .disabled(!hasDueDate)
                            .opacity(hasDueDate ? 1.0 : 0.7)
                            
                            Toggle("", isOn: $hasDueDate)
                                .labelsHidden()
                                .tint(.primaryButton)
                                .onChange(of: hasDueDate) { newValue in
                                    if !newValue {
                                        viewModel.invoiceDueDate = nil
                                    } else {
                                        let today = Date()
                                        viewModel.invoiceDueDate = DateFormatterHelper.formatIndonesianDate(today)
                                    }
                                }
                        }
                    }
                    
                    // Rincian Pesanan
                    Section {
                        ForEach(Array(viewModel.products.enumerated()), id: \.offset) { index, product in
                            Button {
                                selectedProductIndex = index
                                showEditProduct = true
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(product.name.isEmpty ? "Produk \(index + 1)" : product.name)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        
                                        Text("\(product.quantity) Produk")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete { indexSet in
                            if let index = indexSet.first, viewModel.products.count > 1 {
                                    deleteProductIndex = index
                                    showDeleteProductAlert = true
                            }
                        }
                    } header: {
                        HStack {
                            Text("Rincian Pesanan")
                            Spacer()
                            Button {
                                showProductSelection = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.primaryButton)
                            }
                        }
                    }
                    
                    // Rincian Biaya
                    Section("Rincian Biaya") {
                        HStack {
                            Text("Subtotal")
                            Spacer()
                            Text("Rp \(viewModel.totalProductSubtotal.formatted())")
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Text("Biaya Kirim")
                            Spacer()
                            TextField("Rp 0,00", text: Binding(
                                get: {
                                    let val = Decimal(string: viewModel.shippingCostText) ?? 0
                                    if invoiceFocusedField == .shipping {
                                        return val == 0 ? " Rp " : " \(val.formatted(.currency(code: "IDR")))"
                                    } else {
                                        return val == 0 ? "" : " \(val.formatted(.currency(code: "IDR")))"
                                    }
                                },
                                set: { newValue in
                                    let clean = newValue.filter("0123456789".contains)
                                    viewModel.shippingCostText = clean
                                }
                            ))
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .focused($invoiceFocusedField, equals: .shipping)
                        }
                        
                        HStack {
                            Text("Total")
                                .font(.headline)
                            Spacer()
                            Text("Rp \(viewModel.totalAfterDiscount.formatted())")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        
                        HStack {
                            Text("Down Payment")
                            Spacer()
                            
                            TextField("Rp 0,00", text: Binding(
                                get: {
                                    let val = Decimal(string: viewModel.downPaymentText) ?? 0
                                    if invoiceFocusedField == .downPayment {
                                        return val == 0 ? " Rp " : " \(val.formatted(.currency(code: "IDR")))"
                                    } else {
                                        return val == 0 ? "" : " \(val.formatted(.currency(code: "IDR")))"
                                    }
                                },
                                set: { newValue in
                                    let clean = newValue.filter("0123456789".contains)
                                    viewModel.downPaymentText = clean
                                }
                            ))
                            .disabled(!hasDownPayment)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .focused($invoiceFocusedField, equals: .downPayment)
                            
                            Toggle("", isOn: $hasDownPayment)
                                .labelsHidden()
                                .tint(.primaryButton)
                        }
                    }
                    
                    // Lain - Lain
                    Section("Lain - Lain") {
                        ForEach(Array(viewModel.otherFields.enumerated()), id: \.offset) { index, field in
                            let key = "other-\(index)"
                            OrderFieldRow(
                                field: Binding(
                                    get: { viewModel.otherFields[index] },
                                    set: { viewModel.otherFields[index] = $0 }
                                ),
                                fieldKey: key,
                                fieldErrors: viewModel.fieldErrors,
                                focusedField: $focusedField
                            )
                            .id(key)
                        }
                    }
                    
                    // Referensi Foto
                    Section("Referensi Foto") {
                            PhotoSection(
                                selectedItems: $selectedItems,
                                selectedImages: $selectedImages
                            )
                            .padding(.horizontal)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.insetGrouped)
                .disabled(showDeleteProductAlert)
                .scrollDismissesKeyboard(.interactively)
                    .onChange(of: viewModel.fieldErrors) { _, newErrors in
                        if let first = firstErrorKey(from: newErrors) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation {
                                focusedField = first
                            }
                            }
                        }
                    }
                    .onChange(of: firstErrorId) { _, newVal in
                        if let id = newVal {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation {
                                focusedField = id
                            }
                        }
                    }
                }
            }
            
            if showDeleteProductAlert {
                CustomDeleteAlertComponent(
                    title: "Hapus Produk",
                    message: "Apakah Anda yakin ingin menghapus produk ini?",
                    cancelTitle: "Batal",
                    confirmTitle: "Hapus",
                    onCancel: {
                        showDeleteProductAlert = false
                        deleteProductIndex = nil
                    },
                    onConfirm: {
                        if let index = deleteProductIndex {
                            viewModel.deleteProduct(at: index)
                        }
                        showDeleteProductAlert = false
                        deleteProductIndex = nil
                    }
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(999)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    if !showDeleteProductAlert {
                        dismiss()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(showDeleteProductAlert ? .gray : .primaryButton)
                }
                .disabled(showDeleteProductAlert)
            }
            
            ToolbarItem(placement: .principal) {
                Text("Tinjauan Pesanan").font(.title2.bold())
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if !showDeleteProductAlert {
                        // Validate invoice products
                        if viewModel.hasInvalidProduct {
                            withAnimation {
                                showValidationError = true
                            }
                            return
                        }
                        
                            if viewModel.validateAllFields() {
                                Task {
                                    let order = await viewModel.saveOrder(photos: selectedImages.compactMap { $0 })
                                    if let order = order {
                                        lastOrderId = order.id.uuidString
                                    
                                    do {
                                        try await viewModel.saveOrderDetails(hasDownPayment: hasDownPayment)
                                        viewModel.didSave = true
                                    } catch {
                                        print("Failed to save invoice details: \(error)")
                                    }
                                    }
                                }
                            } else {
                                firstErrorId = firstErrorKey(from: viewModel.fieldErrors)
                            }
                        }
                    } label: {
                        if viewModel.isLoading || viewModel.isUploadingPhotos {
                            ProgressView()
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.title3)
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.glassProminent)
                .disabled(viewModel.isLoading || showDeleteProductAlert)
                .tint(.primaryButton)
            }
        }
        .task {
            let unwrappedImages = selectedImages.compactMap { $0 }
            viewModel.configure(userId: session.userId, parsedOrderData: parsedOrderData, selectedPhotos: unwrappedImages)
            
            if viewModel.invoiceDate.isEmpty {
                let now = Date()
                viewModel.invoiceDate = DateFormatterHelper.isoDateString(from: now)
                let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
                viewModel.invoiceDueDate = DateFormatterHelper.formatIndonesianDate(tomorrow)
            }
            
            // Generate invoice number if not set
            if viewModel.invoiceNumber.isEmpty, let userId = session.userId, let uuid = UUID(uuidString: userId) {
                do {
                    let orderYear = Calendar.current.component(.year, from: Date())
                    let orderCount = try await SupabaseManager.shared.getOrderCountForYear(userId: uuid, year: orderYear)
                    viewModel.invoiceNumber = DateFormatterHelper.generateInvoiceNumber(orderDate: Date(), orderCount: orderCount)
                } catch {
                    print("❌ Error generating invoice number: \(error)")
                    // Fallback to a default invoice number
                    let orderYear = Calendar.current.component(.year, from: Date())
                    viewModel.invoiceNumber = DateFormatterHelper.generateInvoiceNumber(orderDate: Date(), orderCount: 0)
                }
            }
        }
        .alert("Berhasil!", isPresented: $viewModel.didSave) {
            Button("OK") {
                navigateToInvoicePreview = true
            }
        } message: {
            Text("Pesanan berhasil disimpan!")
        }
        .navigationDestination(isPresented: $navigateToInvoicePreview) {
            InvoicePreviewView(orderId: lastOrderId, isDismissed: $isDismissed)
        }
        .sheet(isPresented: $showEditProduct) {
            EditProductView(product: Binding(
                get: { viewModel.products[selectedProductIndex] },
                set: { viewModel.products[selectedProductIndex] = $0 }
            ))
        }
        .sheet(isPresented: $showProductSelection) {
            ProductSelectionView(
                existingProducts: viewModel.products,
                onProductSelected: { newProduct in
                    viewModel.products.append(newProduct)
                }
            )
            .environmentObject(session)
        }
        .onDisappear {
            if !hasDownPayment {
                viewModel.downPaymentText = ""
            }
        }
    }



    private func firstErrorKey(from errors: Set<String>) -> String? {
        let sections = ["customer", "schedule", "product", "other"]
        for section in sections {
            if let match = errors.sorted().first(where: { $0.hasPrefix(section + "-") }) {
                return match
            }
        }
        return errors.sorted().first
    }
}


struct ProductsSection: View {
    @Binding var products: [ProductItem]
    let onAdd: () -> Void
    let onDelete: (Int) -> Void
    let fieldErrors: Set<String>
    var onProductTap: ((Int) -> Void)? = nil
    var onAddProduct: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Rincian Pesanan")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Button(action: {
                    if let onAddProduct = onAddProduct {
                        onAddProduct()
                    } else {
                        onAdd()
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(.primaryButton)
                }
            }
            .padding(.horizontal)

            VStack(spacing: 0) {
            ForEach(Array(products.enumerated()), id: \.offset) { index, product in
                    Button {
                        if let onProductTap = onProductTap {
                            onProductTap(index)
                        }
                    } label: {
                        HStack {
                        VStack(alignment: .leading, spacing: 4) {
                                Text(product.name.isEmpty ? "Produk \(index + 1)" : product.name)
                                    .font(.body)
                                .foregroundColor(.primary)
                                
                                Text("\(product.quantity) Produk")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                        .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(.deadlineCard))
                    }
                    .buttonStyle(.plain)
                    
                    if index < products.count - 1 {
                        Divider()
                    }
                }
            }
            .cornerRadius(10)
                            .overlay(
                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                        fieldErrors.contains(where: { $0.hasPrefix("product-") }) ? Color.red : Color.clear,
                        lineWidth: 2
                    )
            )
            .padding(.horizontal)
        }
    }
}

struct OrderFieldRow: View {
    @Binding var field: OrderField
    let fieldKey: String
    let fieldErrors: Set<String>
    @FocusState.Binding var focusedField: String?
    
    var body: some View {
        if field.label.lowercased().contains("tanggal pesanan") {
            DatePicker(
                field.label,
                selection: Binding(
                    get: {
                        DateFormatterHelper.parseIndonesianDate(field.value) ?? Date()
                    },
                    set: {
                        field.value = DateFormatterHelper.formatIndonesianDate($0)
                    }
                ),
                in: Date()...,
                displayedComponents: .date
            )
            .onAppear {
                if field.value.isEmpty {
                    field.value = DateFormatterHelper.formatIndonesianDate(Date())
                }
            }
        } else if field.label.lowercased().contains("jam kirim") {
            HStack {
                Text(field.label)
                Spacer()
                
                DatePicker(
                    "",
                    selection: Binding(
                        get: {
                            DateFormatterHelper.parseTime(field.value) ?? Date()
                        },
                        set: {
                            if field.useTime {
                                field.value = DateFormatterHelper.formatTime($0)
                            }
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .datePickerStyle(.compact)
                .disabled(!field.useTime)
                .opacity(!field.useTime ? 0.7 : 1.0)
                
                Toggle("", isOn: Binding(
                    get: { field.useTime },
                    set: { newValue in
                        field.useTime = newValue
                        if newValue && field.value.isEmpty {
                            field.value = DateFormatterHelper.formatTime(Date())
                        }
                        if !newValue {
                            field.value = ""
                        }
                    }
                ))
                .labelsHidden()
            }
        } else {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(field.label)
                    Spacer()
                    TextField("Silakan isi kolom", text: Binding(
                        get: { field.value },
                        set: { field.value = $0 }
                    ))
                    .keyboardType(field.label.lowercased().contains("telp") ? .numbersAndPunctuation : .default)
                    .multilineTextAlignment(.trailing)
                    .focused($focusedField, equals: fieldKey)
                    .foregroundColor(fieldErrors.contains(fieldKey) && !isOptionalField(field.label) ? .red : .primary)
                }
                
                if fieldErrors.contains(fieldKey) && !isOptionalField(field.label) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.system(size: 12, weight: .semibold))
                        Text("Field ini wajib diisi")
                            .font(.caption)
                            .foregroundStyle(.red)
                        Spacer()
                    }
                }
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



// MARK: - Add-Ons Section
struct AddOnsSection: View {
    @Binding var addOns: [AddOnItem]
    let onAdd: () -> Void
    let onDelete: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Adds On")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)

            ForEach(Array(addOns.enumerated()), id: \.offset) { index, addOn in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Adds On")
                            .font(.headline)
                        Spacer()
                        if addOns.count > 1 {
                            Button { onDelete(index) } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Nama Produk :")
                            .font(.subheadline)
                            .foregroundColor(.primary)

                        TextField("Nama Produk", text: Binding(
                            get: { addOns[index].name },
                            set: { addOns[index].name = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Jumlah Produk :")
                            .font(.subheadline)
                            .foregroundColor(.primary)

                        TextField("0", text: Binding(
                            get: { String(addOns[index].quantity) },
                            set: { addOns[index].quantity = Int($0) ?? 0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }
}
//#Preview {
//    // Dummy bindings
//    @State var selectedImages: [UIImage?] = [nil]
//    @State var selectedItems: [PhotoSection?] = [nil]
//    @State var isDismissed = false
//
//    // Dummy parsedOrderData
//    let dummyParsedData: [String: Any] = [:]
//
//    // Dummy environment objects
//    let session = SessionManager()
//    let deleteBus = DeleteOverlayBus()
//
//    return NavigationStack {
//        EditOrderView(
//            parsedOrderData: dummyParsedData,
//            selectedImages: $selectedImages,
//            selectedItems: $selectedItems,
//            isDismissed: $isDismissed
//        )
//        .environmentObject(session)
//        .environmentObject(deleteBus)
//    }
//}
