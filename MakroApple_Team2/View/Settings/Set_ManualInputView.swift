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
    @StateObject private var vm = Set_MenuDetailsViewModel()
    @Environment(\.dismiss) private var dismiss

    @Binding var isDismissed: Bool

    // State utk alert lokal
    @State private var showUnsavedAlert = false
    @State private var showDeleteAlert = false
    @State private var itemToDelete: (sIndex: Int, pIndex: Int)? = nil

    var body: some View {
        ZStack {
            NavigationStack {
                VStack(spacing: 12) {
                    // Header: search + plus
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
                                showUnsavedAlert = true
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
            
            // === Overlay Unsaved Alert lokal ===
            if showUnsavedAlert {
                CustomUnsavedAlertComponent(
                    title: "Perubahan Belum Disimpan",
                    message: "Apakah Anda yakin ingin membatalkan?",
                    cancelTitle: "Tidak",
                    confirmTitle: "Ya",
                    onCancel: { showUnsavedAlert = false },
                    onConfirm: {
                        showUnsavedAlert = false
                        dismiss()
                    }
                )
                .zIndex(999)
                .transition(.opacity.combined(with: .scale))
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showUnsavedAlert)
            }
            
            // === Overlay Delete Alert lokal ===
            if showDeleteAlert {
                CustomDeleteAlertComponent(
                    title: "Hapus",
                    message: "Apakah Anda yakin ingin menghapus produk ini?",
                    cancelTitle: "Tidak",
                    confirmTitle: "Ya",
                    onCancel: { showDeleteAlert = false },
                    onConfirm: {
                        if let del = itemToDelete {
                            withAnimation {
                                vm.deleteTemporaryProduct(from: del.sIndex, at: del.pIndex)
                            }
                        }
                        showDeleteAlert = false
                        itemToDelete = nil
                    }
                )
                .zIndex(999)
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showDeleteAlert)
            }
        }
        .onTapGesture { hideKeyboard() }
        .task {
            vm.configure(userId: session.userId)
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
                            itemToDelete = (ref.sectionIndex, ref.productIndex)
                            showDeleteAlert = true
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
}

#Preview {
    let session = SessionManager()
    session.isSignedIn = true
    session.userId = "083dc90d-ca03-4f45-a631-06fe21fe750f"

    return Set_ManualInputView(isDismissed: .constant(false))
        .environmentObject(session)
}
