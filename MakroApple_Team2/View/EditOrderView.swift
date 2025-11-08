//
//  EditOrderView.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 30/10/25.
//

import SwiftUI
import Foundation
import PhotosUI

struct EditOrderView: View {
    let parsedOrderData: [String: Any]
    
    @Binding var selectedImages: [UIImage?]
    @State private var viewModel = EditOrderViewModel()
    @State private var selectedItems: [PhotosPickerItem?] = [nil, nil, nil]
    @State private var navigateToConfirm = false
    
    @State private var lastOrderId: String = ""
    
    @EnvironmentObject var session: SessionManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView("Menyimpan pesanan...")
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        OrderFormSection(
                            title: "Rincian Pelanggan",
                            fields: $viewModel.customerFields,
                            sectionType: "customer",  // ✅
                            fieldErrors: viewModel.fieldErrors  // ✅
                        )
                        
                        OrderFormSection(
                            title: "Jadwal Pesanan",
                            fields: $viewModel.scheduleFields,
                            sectionType: "schedule",  // ✅
                            fieldErrors: viewModel.fieldErrors  // ✅
                        )
                        
                        ProductsSection(
                            products: $viewModel.products,
                            onAdd: { viewModel.addProduct() },
                            onDelete: { index in viewModel.deleteProduct(at: index) },
                            fieldErrors: viewModel.fieldErrors  // ✅
                        )
                        
                        AddOnsSection(
                            addOns: $viewModel.addOns,
                            onAdd: { viewModel.addAddOn() },
                            onDelete: { index in viewModel.deleteAddOn(at: index) }
                        )
                        
                        PhotoSection(
                            selectedItems: $selectedItems,
                            selectedImages: $selectedImages
                        )
                        .padding(.horizontal)
                        
                        OrderFormSection(
                            title: "Lain - Lain",
                            fields: $viewModel.otherFields,
                            sectionType: "other",  // ✅
                            fieldErrors: viewModel.fieldErrors  // ✅
                        )
                    }
                    .padding(.vertical)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                    Text("Tinjauan Pesanan")
                        .font(.title2.bold())
                }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    // ✅ Validate dulu sebelum save
                    if viewModel.validateAllFields() {
                        Task {
                            let order = await viewModel.saveOrder(photos: selectedImages.compactMap { $0 })
                            if let order = order {
                                lastOrderId = order.id.uuidString
                                viewModel.didSave = true
                            }
                        }
                    }
                    // Kalau validation gagal, error akan muncul di UI
                }) {
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
                navigateToConfirm = true
            }
        } message: {
            Text("Pesanan berhasil disimpan!")
        }
        .task {
            let unwrappedImages = selectedImages.compactMap { $0 }
            viewModel.configure(userId: session.userId, parsedOrderData: parsedOrderData, selectedPhotos: unwrappedImages)
        }
        .navigationDestination(isPresented: $navigateToConfirm) {
            ConfirmInvoiceView(orderId: lastOrderId)
        }
    }
}

// MARK: - Products Section
struct ProductsSection: View {
    @Binding var products: [ProductItem]
    let onAdd: () -> Void
    let onDelete: (Int) -> Void
    let fieldErrors: Set<String>
    
    @State private var showDeleteAlert = false
    @State private var deleteIndex: Int? = nil
    
    var body: some View {
        ZStack {  // ✅ TAMBAH ZStack wrapper
            // Main content
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
                                Button(action: {
                                    deleteIndex = index
                                    showDeleteAlert = true
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        
                        // ... rest of fields (nama produk, jumlah)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Nama Produk :")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            
                            TextField("Nama Produk", text: Binding(
                                get: { products[index].name },
                                set: { products[index].name = $0 }
                            ))
                            .textFieldStyle(.roundedBorder)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(
                                        fieldErrors.contains("product-\(index)-name") ? Color.red : Color.clear,
                                        lineWidth: fieldErrors.contains("product-\(index)-name") ? 2 : 0
                                    )
                            )
                            
                            if fieldErrors.contains("product-\(index)-name") {
                                Text("Nama produk wajib diisi")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Jumlah Produk :")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            
                            TextField("0", text: Binding(
                                get: { String(products[index].quantity) },
                                set: { products[index].quantity = Int($0) ?? 0 }
                            ))
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(
                                        fieldErrors.contains("product-\(index)-quantity") ? Color.red : Color.clear,
                                        lineWidth: fieldErrors.contains("product-\(index)-quantity") ? 2 : 0
                                    )
                            )
                            
                            if fieldErrors.contains("product-\(index)-quantity") {
                                Text("Jumlah harus lebih dari 0")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
            
            // ✅ Custom Delete Alert - overlay di atas semua
            if showDeleteAlert {
                CustomDeleteAlertComponent(
                    title: "Hapus",
                    message: "Apakah Anda yakin ingin menghapus bagian ini?",
                    cancelTitle: "Tidak",
                    confirmTitle: "Ya"
                ) {
                    showDeleteAlert = false
                    deleteIndex = nil
                } onConfirm: {
                    if let index = deleteIndex {
                        onDelete(index)
                    }
                    showDeleteAlert = false
                    deleteIndex = nil
                }
                .zIndex(999)
                .transition(.opacity.combined(with: .scale))
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showDeleteAlert)
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
                            Button(action: { onDelete(index) }) {
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

#Preview {
    let session = SessionManager()
    session.isSignedIn = true
    session.userId = "083dc90d-ca03-4f45-a631-06fe21fe750f"
    
    let sampleData: [String: Any] = [
        "Nama Pemesan": "Nadia Prameswari",
        "No. Telp Pemesan": "0812-5566-2233",
        "Nama Penerima": "Rafi Setiawan",
        "No. Telp Penerima": "0813-7788-9922",
        "Tanggal Pesanan": "20 Oktober 2025",
        "Jam Kirim": "15.30 WIB",
        "Alamat Kirim": "Jl. Dharmahusada Indah Barat No. 27",
        "Pesanan": [
            "[[{\"item\": \"Strawberry Fresh Cream Cake – ukuran 18 cm\", \"quantity\": 1}]]"
        ],
        "Adds-on": [
            "[[{\"item\": \"Lilin angka \\\"30\\\"\", \"quantity\": 1}, {\"item\": \"pita dekorasi merah\", \"quantity\": 1}]]"
        ],
        "Notes": "Mohon kue dikirim dalam kondisi dingin"
    ]
    
    let samplePhoto = UIImage(systemName: "photo.fill")!
    @State var previewImages: [UIImage?] = [samplePhoto, samplePhoto, nil]

    return NavigationStack {
        EditOrderView(
            parsedOrderData: sampleData,
            selectedImages: $previewImages
        )
        .environmentObject(session)
    }
}

