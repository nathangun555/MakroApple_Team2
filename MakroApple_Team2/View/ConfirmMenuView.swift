//
//  ConfirmMenuView.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 07/11/25.
//

import SwiftUI

struct ConfirmMenuView: View {
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var deleteBus: DeleteOverlayBus
    @EnvironmentObject var unsavedBus: UnsavedOverlayBus
    @StateObject private var vm = Set_MenuDetailsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var navigateToTemplateForm = false

    @Binding var isDismissed: Bool
    let scannedCategories: [MenuCategory]
    var manualInput: Bool

    @State private var productToDelete: (sectionIndex: Int, productIndex: Int)?
    
    var hasEmptyFields: Bool {
        for ref in vm.visibleFlat {
                let item = ref.item
                
                if item.name.trimmingCharacters(in: .whitespaces).isEmpty { return true }
                if item.price == 0 { return true }
            }
            return false
    }
    
    var body: some View {
        ZStack {
            NavigationStack {
                VStack(spacing: 12) {
                    if vm.isLoadedFromScan {
                        scanInfoBanner
                    }
                    
                    searchHeader
                    
                    contentFlatView
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Rincian Menu / Katalog")
                            .font(.title2.bold())
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            if vm.hasPendingChanges {
                                unsavedBus.request(
                                    title: "Perubahan Belum Disimpan",
                                    message: "Apakah Anda yakin ingin membatalkan perubahan?",
                                    cancelTitle: "Tidak",
                                    confirmTitle: "Ya",
                                    onCancel: {},
                                    onConfirm: { dismiss() }
                                )
                            } else {
                                dismiss()
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                                .foregroundColor(.primaryButton)
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if hasEmptyFields {
                            Button {
                                Task {
                                    await vm.saveAll {
                                        navigateToTemplateForm = true
                                    }
                                }
                            } label: {
                                if vm.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "chevron.right")
                                        .font(.title2)
                                        .foregroundColor(.primaryButton)
                                }
                            }
                            .buttonStyle(.glassProminent)
                            .tint(Color.white)
                            .disabled(!vm.hasPendingChanges || vm.isLoading)
                        } else {
                            Button {
                                Task {
                                    await vm.saveAll {
                                        navigateToTemplateForm = true
                                    }
                                }
                            } label: {
                                if vm.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "chevron.right")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                }
                            }
                            .buttonStyle(.glassProminent)
                            .tint(Color.primaryButton)
                            .disabled(!vm.hasPendingChanges || vm.isLoading)
                        }
                    }
                }
            }

            // Overlay for unsaved changes
            if unsavedBus.show {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(996)

                CustomUnsavedAlert(
                    title: unsavedBus.title,
                    message: unsavedBus.message,
                    cancelTitle: unsavedBus.cancelTitle,
                    confirmTitle: unsavedBus.confirmTitle,
                    onCancel: { unsavedBus.close(false) },
                    onConfirm: { unsavedBus.close(true) }
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(997)
            }
            
            // Overlay for delete confirmation
            if deleteBus.show {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(998)

                CustomDeleteAlertComponent(
                    title: "Hapus",
                    message: deleteBus.message,
                    cancelTitle: "Tidak",
                    confirmTitle: "Ya",
                    onCancel: { deleteBus.closeConfirm(false) },
                    onConfirm: {
                        deleteBus.closeConfirm(true)
                        executeDelete()
                    }
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(999)
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
        .task {
            vm.configure(userId: session.userId)
            
            if manualInput {
                initializeEmptyProducts()
            } else {
                // ✅ Load from scanned data instead of database
                if !scannedCategories.isEmpty {
                    await vm.loadFromScan(categories: scannedCategories)
                } else {
                    await vm.load()
                }
            }
        }
        .navigationDestination(isPresented: $navigateToTemplateForm) {
            NewTemplateFormView(isDismissed: $isDismissed)
        }
    }
    
    // MARK: - Info Banner
    private var scanInfoBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Katalog berhasil dipindai")
                    .font(.headline)
                Spacer()
            }
            
            HStack(spacing: 16) {
                Label("\(vm.sections.count) kategori", systemImage: "folder.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Label("\(vm.sections.flatMap { $0.items }.count) produk", systemImage: "tag.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("Periksa dan edit jika ada kesalahan sebelum menyimpan")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Search Header + Add Product Button
    private var searchHeader: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Cari produk", text: $vm.searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Button {
                withAnimation { vm.addTemporaryProductFlat() }
            } label: {
                Image(systemName: "plus")
                    .font(.title3.weight(.semibold))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.primaryButton))
                    .foregroundColor(.white)
            }
            .accessibilityLabel("Tambah Produk")
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    // MARK: - Flat Product List
    private var contentFlatView: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let err = vm.errorMessage {
                    Text(err)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                ForEach(vm.visibleFlat) { ref in
                    HStack(alignment: .top) {
                        EditableProductRow(
                            viewModel: ref.item,
                            isEditing: true,
                            sectionIndex: ref.sectionIndex,
                            productIndex: ref.productIndex,
                            validationErrors: vm.validationErrors,
                            onChanged: { vm.markChanged() }
                        )

                        Button {
                            handleDeleteProduct(sIndex: ref.sectionIndex, pIndex: ref.productIndex)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer(minLength: 100)
            }
            .padding(.top)
        }
        .scrollContentBackground(.hidden)
        .background(Color.white)
    }
    
    // MARK: - Delete Handlers
    func handleDeleteProduct(sIndex: Int, pIndex: Int) {
        productToDelete = (sectionIndex: sIndex, productIndex: pIndex)
        deleteBus.request(message: "Apakah Anda yakin ingin menghapus produk ini?") {
            // Will call executeDelete() on confirm
        }
    }
    
    func executeDelete() {
        if let prod = productToDelete {
            withAnimation {
                vm.deleteTemporaryProduct(from: prod.sectionIndex, at: prod.productIndex)
            }
        }
        productToDelete = nil
    }
    
    private func initializeEmptyProducts() {
        for _ in 0..<3 {
            vm.addTemporaryProductFlat()
        }
    }
}


//#Preview {
//    let session = SessionManager()
//    session.isSignedIn = true
//    session.userId = "083dc90d-ca03-4f45-a631-06fe21fe750f"
//    
//    // ✅ Mock scanned data for preview
//    let mockCategories = [
//        MenuCategory(categoryName: "Custom Cake", products: [
//            MenuProduct(name: "Custom Cake 12cm - Vanilla", price: 110000, notes: "2 layer vanilla sponge", productType: "Custom Cake"),
//            MenuProduct(name: "Custom Cake 16cm - Chococrunch", price: 190000, notes: "With chococrunch filling", productType: "Custom Cake")
//        ]),
//        MenuCategory(categoryName: "Signature Cake", products: [
//            MenuProduct(name: "Strawberry Shortcake 16cm", price: 240000, notes: "vanilla sponge, fresh strawberry", productType: "Signature Cake")
//        ])
//    ]
//    
//    return NavigationStack {
//        ConfirmMenuView(scannedCategories: mockCategories)
//            .environmentObject(session)
//    }
//}
