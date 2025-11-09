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
    
    @Binding var parsedOrderData: [String: Any]
    
    @Binding var selectedImages: [UIImage?]
    @Binding var path: NavigationPath
    @State private var viewModel = EditOrderViewModel()
    @State private var selectedItems: [PhotosPickerItem?] = [nil, nil, nil]
    
    @State private var lastOrderId: String = ""

    // Fokus untuk memindahkan caret ke field error
    @FocusState private var focusedField: String?
    // Simpan id error pertama untuk trigger scroll
    @State private var firstErrorId: String?

    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var deleteBus: DeleteOverlayBus
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView("Menyimpan pesanan...")
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 24) {
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
                                    deleteBus.request { viewModel.deleteProduct(at: index) }
                                },
                                fieldErrors: viewModel.fieldErrors
                            )
                            // Adds On
                            AddOnsSection(
                                addOns: $viewModel.addOns,
                                onAdd: { viewModel.addAddOn() },
                                onDelete: { index in
                                    deleteBus.request { viewModel.deleteAddOn(at: index) }
                                }
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
                    // Ketika set error berubah, scroll ke error pertama dan fokuskan
                    .onChange(of: viewModel.fieldErrors) { _, newErrors in
                        if let first = firstErrorKey(from: newErrors) {
                            withAnimation(.easeInOut) {
                                proxy.scrollTo(first, anchor: .center)
                                focusedField = first
                            }
                        }
                    }
                    // Jika firstErrorId di-set manual saat tap Next, lakukan scroll
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
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Tinjauan Pesanan").font(.title2.bold())
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if viewModel.validateAllFields() {
                        Task {
                            let order = await viewModel.saveOrder(photos: selectedImages.compactMap { $0 })
                            if let order = order {
                                lastOrderId = order.id.uuidString
                                viewModel.didSave = true
                            }
                        }
                    } else {
                        // set id error pertama untuk memicu scroll
                        firstErrorId = firstErrorKey(from: viewModel.fieldErrors)
                    }
                } label: {
                    if viewModel.isLoading || viewModel.isUploadingPhotos {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.right")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                }
                .disabled(viewModel.isLoading)
            }
        }
        .alert("Berhasil!", isPresented: $viewModel.didSave) {
            Button("OK") {
                path.append(OrderDestination.confirmInvoice(orderId: lastOrderId))
            }
        } message: {
            Text("Pesanan berhasil disimpan!")
        }
        .task {
            let unwrappedImages = selectedImages.compactMap { $0 }
            viewModel.configure(userId: session.userId, parsedOrderData: parsedOrderData, selectedPhotos: unwrappedImages)
        }
    }

    // Urutkan prioritas: customer -> schedule -> product -> other
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


// MARK: - Products Section
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
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)

            ForEach(Array(products.enumerated()), id: \.offset) { index, product in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(product.category.isEmpty ? "Kategori Produk" : product.category)
                            .font(.headline)
                            .foregroundColor(product.category.isEmpty ? .secondary : .primary)
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
                            Text("Nama produk wajib diisi")
                                .font(.caption)
                                .foregroundStyle(.red)
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
                            Text("Jumlah harus lebih dari 0")
                                .font(.caption)
                                .foregroundStyle(.red)
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
//    let session = SessionManager()
//    session.isSignedIn = true
//    session.userId = "083dc90d-ca03-4f45-a631-06fe21fe750f"
//    
//    let sampleData: [String: Any] = [
//        "Nama Pemesan": "Nadia Prameswari",
//        "No. Telp Pemesan": "0812-5566-2233",
//        "Nama Penerima": "Rafi Setiawan",
//        "No. Telp Penerima": "0813-7788-9922",
//        "Tanggal Pesanan": "20 Oktober 2025",
//        "Jam Kirim": "15.30 WIB",
//        "Alamat Kirim": "Jl. Dharmahusada Indah Barat No. 27",
//        "Pesanan": [
//            "[[{\"item\": \"Strawberry Fresh Cream Cake – ukuran 18 cm\", \"quantity\": 1}]]"
//        ],
//        "Adds-on": [
//            "[[{\"item\": \"Lilin angka \\\"30\\\"\", \"quantity\": 1}, {\"item\": \"pita dekorasi merah\", \"quantity\": 1}]]"
//        ],
//        "Notes": "Mohon kue dikirim dalam kondisi dingin"
//    ]
//    
//    let samplePhoto = UIImage(systemName: "photo.fill")!
//    @State var previewImages: [UIImage?] = [samplePhoto, samplePhoto, nil]
//
//    return NavigationStack {
//        EditOrderView(
//            parsedOrderData: sampleData,
//            selectedImages: $previewImages
//        )
//        .environmentObject(session)
//    }
//}

