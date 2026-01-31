import SwiftUI
import PhotosUI
import Foundation

struct EditOrderDetailView: View {
    
    // 🔁 EDIT MODE
    let orderId: String
    let parsedOrderData: [String: Any]
    
    @Binding var selectedImages: [UIImage?]
    @Binding var selectedItems: [PhotosPickerItem?]
    @Binding var isDismissed: Bool
    
    @State private var viewModel = EditOrderViewModel()
    
    @State private var lastOrderId: String = ""
    @State private var firstErrorId: String?
    
    @FocusState private var focusedField: String?
    @FocusState private var invoiceFocusedField: ProductField?
    
    @State private var navigateToInvoicePreview = false
    
    // Delete product
    @State private var showDeleteProductAlert = false
    @State private var deleteProductIndex: Int?
    
    // Invoice states
    @State private var hasDownPayment = false
    @State private var hasDueDate = true
    @State private var showValidationError = false
    
    // Product editing
    @State private var showEditProduct = false
    @State private var showProductSelection = false
    @State private var selectedProductIndex = 0
    
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var deleteBus: DeleteOverlayBus
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack{
            ZStack {
                if viewModel.isLoading {
                    LoadingView(context: "pesanan")
                        .navigationBarHidden(true)
                } else {
                    List {
                        
                        // MARK: - Customer
                        Section("Rincian Pelanggan") {
                            ForEach(Array(viewModel.customerFields.enumerated()), id: \.offset) { index, _ in
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
                        
                        // MARK: - Schedule
                        Section("Jadwal Pesanan") {
                            ForEach(Array(viewModel.scheduleFields.enumerated()), id: \.offset) { index, _ in
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
                        
                        // MARK: - Invoice
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
                                            DateFormatterHelper.parseIndonesianDate(viewModel.invoiceDueDate ?? "") ?? Date()
                                        },
                                        set: {
                                            viewModel.invoiceDueDate = DateFormatterHelper.formatIndonesianDate($0)
                                        }
                                    ),
                                    displayedComponents: .date
                                )
                                .labelsHidden()
                                .disabled(!hasDueDate)
                                
                                Toggle("", isOn: $hasDueDate)
                                    .labelsHidden()
                                    .tint(.primaryButton)
                            }
                        }
                        
                        // MARK: - Products
                        Section {
                            ForEach(Array(viewModel.products.enumerated()), id: \.offset) { index, product in
                                Button {
                                    selectedProductIndex = index
                                    showEditProduct = true
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(product.name.isEmpty ? "Produk \(index + 1)" : product.name)
                                            Text("\(product.quantity) Produk")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .onDelete { indexSet in
                                if let index = indexSet.first {
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
                                        .foregroundColor(.primaryButton)
                                }
                            }
                        }
                        
                        // MARK: - Costs
                        Section("Rincian Biaya") {
                            HStack {
                                Text("Subtotal")
                                Spacer()
                                Text("Rp \(viewModel.totalProductSubtotal.formatted())")
                            }
                            
                            HStack {
                                Text("Biaya Kirim")
                                Spacer()
                                TextField("Rp 0", text: $viewModel.shippingCostText)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                            }
                            
                            HStack {
                                Text("Total")
                                    .font(.headline)
                                Spacer()
                                Text("Rp \(viewModel.totalAfterDiscount.formatted())")
                                    .font(.headline)
                            }
                            
                            HStack {
                                Text("Down Payment")
                                Spacer()
                                TextField("Rp 0", text: $viewModel.downPaymentText)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .disabled(!hasDownPayment)
                                
                                Toggle("", isOn: $hasDownPayment)
                                    .labelsHidden()
                                    .tint(.primaryButton)
                            }
                        }
                        
                        // MARK: - Other
                        Section("Lain - Lain") {
                            ForEach(Array(viewModel.otherFields.enumerated()), id: \.offset) { index, _ in
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
                        
                        // MARK: - Photos
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
                }
                
                if showDeleteProductAlert {
                    CustomDeleteAlertComponent(
                        title: "Hapus Produk",
                        message: "Yakin ingin menghapus produk ini?",
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
                }
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.primaryButton)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Edit Pesanan")
                        .font(.title2.bold())
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if viewModel.validateAllFields() {
                            Task {
                                // 🔁 EDIT MODE SAVE LOGIC
                                let order = await viewModel.saveOrder(photos: [])
                                if let order {
                                    lastOrderId = order.id.uuidString
                                    navigateToInvoicePreview = true
                                }
                            }
                        } else {
                            firstErrorId = firstErrorKey(from: viewModel.fieldErrors)
                        }
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.primaryButton)
                }
            }
            .task {
                viewModel.configure(
                    userId: session.userId,
                    parsedOrderData: parsedOrderData
                )
                viewModel.orderIdNow = orderId
                lastOrderId = orderId
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
                    onProductSelected: { viewModel.products.append($0) }
                )
                .environmentObject(session)
            }
        }
    }
    
    private func firstErrorKey(from errors: Set<String>) -> String? {
        let sections = ["customer", "schedule", "product", "other"]
        for section in sections {
            if let match = errors.first(where: { $0.hasPrefix(section) }) {
                return match
            }
        }
        return errors.first
    }
}
