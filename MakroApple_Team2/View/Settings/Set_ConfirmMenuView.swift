//
//  Set_ConfirmMenuView.swift
//  MakroApple_Team2
//
//  Created for Settings flow - Confirm scanned menu
//

import SwiftUI
import Combine

struct Set_ConfirmMenuView: View {
    
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var deleteBus: DeleteOverlayBus
    @EnvironmentObject var unsavedBus: UnsavedOverlayBus
    @StateObject private var vm = Set_MenuDetailsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @Binding var isDismissed: Bool
    let scannedCategories: [MenuCategory]
    
    // Simpan konteks item yang dihapus (eksekusi via bus)
    @State private var itemToDelete: (type: DeleteType, sIndex: Int, pIndex: Int?)? = nil
    enum DeleteType { case category, product }
    
    var body: some View {
        ZStack {
            NavigationStack {
                VStack(spacing: 12) {
                    // Info banner hasil scan (di atas search)
                    if vm.isLoadedFromScan {
                        scanInfoBanner
                    }
                    
                    // Header: search + plus di kanan
                    searchHeader
                    
                    // Konten daftar produk flat
                    contentFlatView
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Konfirmasi Hasil Scan")
                            .font(.title2.bold())
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            if vm.hasPendingChanges {
                                unsavedBus.request(
                                    title: "Perubahan Belum Disimpan",
                                    message: "Apakah Anda yakin ingin membatalkan?",
                                    cancelTitle: "Tidak",
                                    confirmTitle: "Ya",
                                    onCancel: { /* stay */
                                    unsavedBus.close(false)
                                    },
                                    onConfirm: {
                                        unsavedBus.close(false)        
                                        dismiss() }
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
                        let button = Button {
                            Task {
                                await vm.saveAll {
                                    // Dismiss semua sheet (kembali ke SettingsView)
                                    isDismissed = true
                                    dismiss()
                                }
                            }
                        } label: {
                            if vm.isLoading {
                                ProgressView()
                            } else {
                                Image(systemName: "checkmark")
                                    .font(.title2)
                                    .foregroundColor(vm.hasPendingChanges ? .white : .gray)
                            }
                        }
                        .disabled(!vm.hasPendingChanges || vm.isLoading)

                        if vm.hasPendingChanges {
                            button.buttonStyle(BorderedProminentButtonStyle()).tint(.primaryButton)
                        } else {
                            button.buttonStyle(BorderlessButtonStyle())
                        }
                    }
                }
            }

            // ⬇️ Overlay UNSAVED (di atas fullScreenCover ini)
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

            // ⬇️ Overlay DELETE
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
        .task {
            vm.configure(userId: session.userId)
            await vm.loadFromScan(categories: scannedCategories)
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
    
    // MARK: - Header Search + Plus
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
    
    // MARK: - Flat list (filter dari vm.visibleFlat)
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
    
    // MARK: - Delete handlers
    func handleDeleteProduct(sIndex: Int, pIndex: Int) {
        itemToDelete = (.product, sIndex, pIndex)
        deleteBus.request(message: "Apakah Anda yakin ingin menghapus produk ini?") {
            // Eksekusi actual delete di executeDelete()
        }
    }
    
    func executeDelete() {
        if let item = itemToDelete, item.type == .product, let pIndex = item.pIndex {
            withAnimation {
                vm.deleteTemporaryProduct(from: item.sIndex, at: pIndex)
            }
        }
        itemToDelete = nil
    }
}

#Preview {
    let session = SessionManager()
    session.isSignedIn = true
    session.userId = "083dc90d-ca03-4f45-a631-06fe21fe750f"
    
    let mockCategories = [
        MenuCategory(categoryName: "Custom Cake", products: [
            MenuProduct(name: "Custom Cake 12cm", price: 110000, notes: nil, productType: "Custom Cake"),
            MenuProduct(name: "Custom Cake 16cm", price: 190000, notes: nil, productType: "Custom Cake")
        ])
    ]
    
    return Set_ConfirmMenuView(isDismissed: .constant(false), scannedCategories: mockCategories)
        .environmentObject(session)
        .environmentObject(DeleteOverlayBus())
        .environmentObject(UnsavedOverlayBus())
}
