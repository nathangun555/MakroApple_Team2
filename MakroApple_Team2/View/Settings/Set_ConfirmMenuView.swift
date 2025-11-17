//
//  Set_ConfirmMenuView.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 16/11/25.
//

import SwiftUI

struct Set_ConfirmMenuView: View {
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var deleteBus: DeleteOverlayBus     // Global delete
    @EnvironmentObject var unsavedBus: UnsavedOverlayBus   // Global unsaved
    @StateObject private var vm = Set_MenuDetailsViewModel()
    @Environment(\.dismiss) private var dismiss

    // Data hasil extract dari Set_InputMenuView
    let scannedCategories: [MenuCategory]
    var onAfterSave: (() -> Void)? = nil

    // Simpan konteks id item yang akan dihapus (eksekusi via bus)
    @State private var pendingDeleteProductId: UUID? = nil

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                // Header: search + plus di kanan
                searchHeader
                // Konten daftar produk (flat, identik dengan MenuDetails)
                contentFlatView
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Rincian Menu / Katalog")
                        .font(.title2.bold())
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    let button = Button {
                        Task {
                            await vm.saveAll {
                                onAfterSave?()
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
        .toolbar(.hidden, for: .tabBar)
        .task {
            vm.configure(userId: session.userId)
            await vm.loadFromScan(categories: scannedCategories)
        }
    }

    // MARK: - Header Search + Plus di kanan
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

    // MARK: - Flat list tanpa kategori
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
                            isEditing: true,                 // tetap editable
                            sectionIndex: ref.sectionIndex,  // indeks asli
                            productIndex: ref.productIndex,  // indeks asli
                            validationErrors: vm.validationErrors,
                            onChanged: { vm.markChanged() }
                        )

                        Button {
                            handleDeleteProductById(ref.item.id)
                            print("▶️ Tap delete id =", ref.item.id)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .padding(.top, 8)
                        }
                    }
                    .id(ref.item.id)                         // pastikan re-render
                    .padding(.horizontal)
                }

                Spacer(minLength: 100)
            }
            .padding(.top)
        }
        .scrollContentBackground(.hidden)
        .background(Color.white)
    }

    // MARK: - Delete lewat bus global (by ID)
    private func handleDeleteProductById(_ id: UUID) {
        pendingDeleteProductId = id
        deleteBus.request(message: "Apakah Anda yakin ingin menghapus produk ini?") {
            print("✅ Confirm delete id =", pendingDeleteProductId as Any)
            guard let deletingId = pendingDeleteProductId else { return }
            withAnimation {
                vm.deleteTemporaryProductById(deletingId)
                vm.markChanged()
            }
            pendingDeleteProductId = nil
        }
    }
}
