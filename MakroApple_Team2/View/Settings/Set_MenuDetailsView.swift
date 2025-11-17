import SwiftUI
import Combine

struct Set_MenuDetailsView: View {

    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var deleteBus: DeleteOverlayBus     // Global delete
    @EnvironmentObject var unsavedBus: UnsavedOverlayBus   // Global unsaved
    @StateObject private var vm = Set_MenuDetailsViewModel()
    @Environment(\.dismiss) private var dismiss
    

    // Simpan konteks item yang dihapus (eksekusi via bus)
    @State private var itemToDelete: (type: DeleteType, sIndex: Int, pIndex: Int?)? = nil

    enum DeleteType { case category, product }

    
    var body: some View {
        ZStack {
            NavigationStack {
                VStack(spacing: 12) {
                    // Header: search + plus di kanan
                    searchHeader
                    // Konten daftar produk
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
                                // Overlay global UnsavedOverlayBus (tetap)
                                unsavedBus.request(
                                    onCancel: { /* tutup saja */ },
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
                        let button = Button {
                            Task {
                                // Tetap panggil saveAll { dismiss() } → validasi lalu kembali
                                await vm.saveAll { dismiss() }
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
            // Hilangkan .searchable bawaan agar tidak bentrok dengan header kustom
            .toolbar(.hidden, for: .tabBar)
        }
        .task {
            vm.configure(userId: session.userId)
            await vm.load()
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

    // MARK: - Flat list tanpa kategori (filter mengacu ke vm.visibleFlat)
    private var contentFlatView: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let err = vm.errorMessage {
                    Text(err)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                // Tampilkan item dari vm.visibleFlat (sudah filter + sort di VM)
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

    // MARK: - Delete lewat bus global (pakai indeks asli)
    func handleDeleteProduct(sIndex: Int, pIndex: Int) {
        itemToDelete = (.product, sIndex, pIndex)
        deleteBus.request(message: "Apakah Anda yakin ingin menghapus produk ini?") {
            if let item = itemToDelete, item.type == .product, let pIndex = item.pIndex {
                withAnimation {
                    // ViewModel akan membersihkan validationErrors by UUID
                    vm.deleteTemporaryProduct(from: item.sIndex, at: pIndex)
                }
            }
            itemToDelete = nil
        }
    }

    // (Opsional) Masih tersedia bila dibutuhkan oleh alur lama
    func handleDeleteCategory(sIndex: Int) {
        itemToDelete = (.category, sIndex, nil)
        deleteBus.request(message: "Apakah Anda yakin ingin menghapus kategori ini?") {
            if let item = itemToDelete, item.type == .category {
                withAnimation {
                    vm.deleteTemporaryCategory(at: item.sIndex)
                }
            }
            itemToDelete = nil
        }
    }
}

#Preview {
    let session = SessionManager()
    session.isSignedIn = true
    session.userId = "083dc90d-ca03-4f45-a631-06fe21fe750f"

    return NavigationStack {
        Set_MenuDetailsView()
            .environmentObject(session)
            .environmentObject(DeleteOverlayBus())
            .environmentObject(UnsavedOverlayBus())
    }
}
