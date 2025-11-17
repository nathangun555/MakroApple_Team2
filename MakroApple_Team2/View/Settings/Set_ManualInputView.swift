//
//  Set_ManualInputView.swift
//  MakroApple_Team2
//
//  Created for Settings flow - Manual menu input
//

import SwiftUI
import Combine

struct Set_ManualInputView: View {
    
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var deleteBus: DeleteOverlayBus
    @EnvironmentObject var unsavedBus: UnsavedOverlayBus
    @StateObject private var vm = Set_MenuDetailsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @Binding var isDismissed: Bool
    
    // Simpan konteks item yang dihapus (eksekusi via bus)
    @State private var itemToDelete: (type: DeleteType, sIndex: Int, pIndex: Int?)? = nil
    enum DeleteType { case category, product }
    
    var body: some View {
        ZStack {
            NavigationStack {
                VStack(spacing: 12) {
                    // Header: search + plus di kanan
                    searchHeader
                    
                    // Konten daftar produk flat
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

            // ⬇️ Overlay UNSAVED di atas fullScreenCover ini
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
            // Langsung tambahkan 3 produk kosong
            initializeEmptyProducts()
        }
    }
    
    // MARK: - Initialize 3 empty products
    private func initializeEmptyProducts() {
        for _ in 0..<3 {
            vm.addTemporaryProductFlat()
        }
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
            // Eksekusi nyata di executeDelete()
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
    
    return Set_ManualInputView(isDismissed: .constant(false))
        .environmentObject(session)
        .environmentObject(DeleteOverlayBus())
        .environmentObject(UnsavedOverlayBus())
}
