//
//  EditOrderView.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 30/10/25.
//

import SwiftUI
import PhotosUI
import Foundation

struct EditOrderView: View {
    
    var parsedOrderData: [String: Any]
    
    @Binding var selectedImages: [UIImage?]
    @Binding var selectedItems: [PhotosPickerItem?]
    
    @Binding var isDismissed: Bool
    @State private var viewModel = EditOrderViewModel()
    
    @State private var lastOrderId: String = ""
    @FocusState private var focusedField: String?
    @State private var firstErrorId: String?
    
    @State private var navigateToConfirmInvoice = false
    
    // ✅ TAMBAH: State untuk delete alert
    @State private var showDeleteProductAlert = false
    @State private var deleteProductIndex: Int?

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
                ProgressView("Menyimpan pesanan...")
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            // Rincian Pelanggan
                            OrderFormSection(
                                title: "Rincian Pelanggan",
                                fields: $viewModel.customerFields,
                                sectionType: "customer",
                                fieldErrors: viewModel.fieldErrors
                            )
                            // Jadwal
                            OrderFormSection(
                                title: "Jadwal Pesanan",
                                fields: $viewModel.scheduleFields,
                                sectionType: "schedule",
                                fieldErrors: viewModel.fieldErrors
                            )
                            // Produk
                            ProductsSection(
                                products: $viewModel.products,
                                onAdd: { viewModel.addProduct() },
                                onDelete: { index in
                                    deleteProductIndex = index
                                    showDeleteProductAlert = true
                                },
                                fieldErrors: viewModel.fieldErrors
                            )
                            // Foto
                            PhotoSection(
                                selectedItems: $selectedItems,
                                selectedImages: $selectedImages
                            )
                            .padding(.horizontal)
                            // Lain-lain
                            OrderFormSection(
                                title: "Lain - Lain",
                                fields: $viewModel.otherFields,
                                sectionType: "other",
                                fieldErrors: viewModel.fieldErrors
                            )
                        }
                        .padding(.vertical)
                    }
                    .disabled(showDeleteProductAlert)  // ✅ PINDAH: Disable hanya ScrollView
                    .onChange(of: viewModel.fieldErrors) { _, newErrors in
                        if let first = firstErrorKey(from: newErrors) {
                            withAnimation(.easeInOut) {
                                proxy.scrollTo(first, anchor: .center)
                                focusedField = first
                            }
                        }
                    }
                    .onChange(of: firstErrorId) { _, newVal in
                        if let id = newVal {
                            withAnimation(.easeInOut) {
                                proxy.scrollTo(id, anchor: .center)
                                focusedField = id
                            }
                        }
                    }
                }
            }
            
            // ✅ Delete alert (tidak ke-disable, tetap bisa interact)
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
        .onTapGesture {
            hideKeyboard()
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
                if hasEmptyFields {
                    Button {
                        if !showDeleteProductAlert {
                            if viewModel.validateAllFields() {
                                Task {
                                    let order = await viewModel.saveOrder(photos: selectedImages.compactMap { $0 })
                                    if let order = order {
                                        lastOrderId = order.id.uuidString
                                        viewModel.didSave = true
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
                                .foregroundColor(.primaryButton)
                        }
                    }
                    .buttonStyle(.glassProminent)
                    .disabled(viewModel.isLoading || showDeleteProductAlert)
                    .tint(.white)
                } else {
                    Button {
                        if !showDeleteProductAlert {
                            if viewModel.validateAllFields() {
                                Task {
                                    let order = await viewModel.saveOrder(photos: selectedImages.compactMap { $0 })
                                    if let order = order {
                                        lastOrderId = order.id.uuidString
                                        viewModel.didSave = true
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
                                .foregroundColor(showDeleteProductAlert ? .gray : .white)
                        }
                    }
                    .buttonStyle(.glassProminent)
                    .disabled(viewModel.isLoading || showDeleteProductAlert)
                    .tint(showDeleteProductAlert ? .gray : .primaryButton)
                }
            }
        }
        // ❌ HAPUS: .disabled(showDeleteProductAlert) dari sini
        .task {
            let unwrappedImages = selectedImages.compactMap { $0 }
            viewModel.configure(userId: session.userId, parsedOrderData: parsedOrderData, selectedPhotos: unwrappedImages)
        }
        .alert("Berhasil!", isPresented: $viewModel.didSave) {
            Button("OK") {
                navigateToConfirmInvoice = true
            }
        } message: {
            Text("Pesanan berhasil disimpan!")
        }
        .navigationDestination(isPresented: $navigateToConfirmInvoice) {
            ConfirmInvoiceView(orderId: lastOrderId, isDismissed: $isDismissed)
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

    @FocusState private var focusedField: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Rincian Pesanan")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(.primaryButton)
                }
            }
            .padding(.horizontal)

            ForEach(Array(products.enumerated()), id: \.offset) { index, product in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Spacer()
                        if products.count > 1 {
                            Button { onDelete(index) } label: {
                                Image(systemName: "trash").foregroundColor(.red)
                            }
                        }
                    }

                    let nameKey = "product-\(index)-name"
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Nama Produk :")
                            .font(.subheadline)
                            .foregroundColor(.primary)

                        TextField("Nama Produk", text: Binding(
                            get: { products[index].name },
                            set: { products[index].name = $0 }
                        ))
                        .focused($focusedField, equals: nameKey)
                        .textFieldStyle(.roundedBorder)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(
                                    fieldErrors.contains(nameKey) ? Color.red : Color.clear,
                                    lineWidth: fieldErrors.contains(nameKey) ? 2 : 0
                                )
                        )

                        if fieldErrors.contains(nameKey) {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                Text("Nama produk wajib diisi")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    .id(nameKey)

                    let qtyKey = "product-\(index)-quantity"
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Jumlah Produk :")
                            .font(.subheadline)
                            .foregroundColor(.primary)

                        TextField("0", text: Binding(
                            get: { String(products[index].quantity) },
                            set: { products[index].quantity = Int($0) ?? 0 }
                        ))
                        .focused($focusedField, equals: qtyKey)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(
                                    fieldErrors.contains(qtyKey) ? Color.red : Color.clear,
                                    lineWidth: fieldErrors.contains(qtyKey) ? 2 : 0
                                )
                        )

                        if fieldErrors.contains(qtyKey) {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                Text("Jumlah harus lebih dari 0")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    .id(qtyKey)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
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
