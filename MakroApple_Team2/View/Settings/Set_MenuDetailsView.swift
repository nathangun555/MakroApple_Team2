//
//  Set_MenuDetailsView.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 17/10/25.
//

import SwiftUI
import Combine

struct Set_MenuDetailsView: View {
    
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var deleteBus: DeleteOverlayBus       // Global delete
    @EnvironmentObject var unsavedBus: UnsavedOverlayBus     // Global unsaved
    @StateObject private var vm = Set_MenuDetailsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    // ✅ Hanya untuk menyimpan konteks item yang dihapus (eksekusi via bus)
    @State private var itemToDelete: (type: DeleteType, sIndex: Int, pIndex: Int?)? = nil
    
    enum DeleteType { case category, product }
    
    var body: some View {
        ZStack {
            NavigationStack {
                contentView
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarBackButtonHidden(true)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("Rincian Menu/Catalog")
                                .font(.title2.bold())
                        }
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                if vm.hasPendingChanges {
                                    // ✅ Panggil overlay global UnsavedOverlayBus
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
            .toolbar(.hidden, for: .tabBar)
        }
        .task {
            vm.configure(userId: session.userId)
            await vm.load()
        }
    }
    
    private var contentView: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 20) {
                    if let err = vm.errorMessage {
                        Text(err)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                    
                    ForEach(vm.sections.indices, id: \.self) { sIndex in
                        let section = vm.sections[sIndex]
                        
                        VStack(alignment: .leading, spacing: 12) {
                            // Header kategori
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    if section.isEditing {
                                        TextField(
                                            "Nama Kategori",
                                            text: Binding(
                                                get: {
                                                    let raw = section.title.trimmingCharacters(in: .whitespacesAndNewlines)
                                                    if raw.isEmpty { return "" }
                                                    if ["ZZZ", "Silakan isi nama kategori", "Nama Kategori"].contains(raw) {
                                                        return ""
                                                    }
                                                    return raw
                                                },
                                                set: { newValue in
                                                    vm.sections[sIndex].title = newValue
                                                }
                                            )
                                        )
                                        .font(.headline)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(10)
                                        .textInputAutocapitalization(.words)
                                        .autocorrectionDisabled(true)
                                        
                                    } else {
                                        Text(section.title)
                                            .font(.headline)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color(.systemGray4), lineWidth: 1)
                                                    .allowsHitTesting(false)
                                            )
                                            .cornerRadius(10)
                                    }
                                    
                                    Spacer()
                                    
                                    if section.isEditing {
                                        Button {
                                            handleDeleteCategory(sIndex: sIndex)
                                        } label: {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red)
                                                .padding(.trailing, 6)
                                        }
                                    }
                                    
                                    Button {
                                        withAnimation {
                                            vm.toggleEdit(sectionIndex: sIndex)
                                        }
                                    } label: {
                                        Text(section.isEditing ? "Done" : "Edit")
                                            .font(.subheadline)
                                            .foregroundColor(.primaryButton)
                                            .padding(.vertical, 6)
                                                    .padding(.horizontal, 12)
                                            .background(
                                                        Capsule().fill(Color(.systemGray6))  // light grey background
                                                    )
                                    }
                                    
                                }
                                
                                // Error nama kategori (UUID-based)
                                if vm.validationErrors.contains("\(section.id.uuidString)-cat") {
                                    HStack(spacing: 6) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.red)
                                            .font(.system(size: 12, weight: .bold))

                                        Text("Nama kategori tidak boleh kosong")
                                            .font(.caption)
                                            .foregroundColor(.red)

                                        Spacer()
                                    }
                                    .padding(.leading, 3)
                                    .fixedSize(horizontal: false, vertical: true)
                                }

                            }
                            
                            Divider()
                            
                            if section.isEditing {
                                Button {
                                    vm.addTemporaryProduct(to: sIndex)
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "plus")
                                        Text("Tambah Produk")
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(.primaryButton)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 14)
                                    .background(Capsule().fill(Color(.systemGray6)))
                                }
                            }
                            
                            VStack(spacing: 14) {
                                ForEach(section.items.indices, id: \.self) { pIndex in
                                    let item = section.items[pIndex]
                                    HStack(alignment: .top) {
                                        EditableProductRow(
                                            viewModel: item,
                                            isEditing: section.isEditing,
                                            sectionIndex: sIndex,
                                            productIndex: pIndex,
                                            validationErrors: vm.validationErrors
                                        )
                                        if section.isEditing {
                                            Button {
                                                handleDeleteProduct(sIndex: sIndex, pIndex: pIndex)
                                            } label: {
                                                Image(systemName: "trash")
                                                    .foregroundColor(.red)
                                                    .padding(.top, 8)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(14)
                        .background(Color.white)
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.top)
            }
            
            Button {
                withAnimation {
                    vm.addTemporaryCategory()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.title3)
                    Text("Tambah Kategori")
                        .fontWeight(.bold)
                }
                .padding(.horizontal, 60)
                .padding(.vertical, 14)
                .background(Color.primaryButton)
                .foregroundColor(.white)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 3)
            }
            .padding(.bottom, 20)
        }
    }
    
    func handleDeleteProduct(sIndex: Int, pIndex: Int) {
        // ✅ Trigger delete produk via bus global
        itemToDelete = (.product, sIndex, pIndex)
        deleteBus.request(message: "Apakah Anda yakin ingin menghapus produk ini?") {
            if let item = itemToDelete,
               item.type == .product,
               let pIndex = item.pIndex {
                withAnimation {
                    // ViewModel akan membersihkan validationErrors by UUID
                    vm.deleteTemporaryProduct(from: item.sIndex, at: pIndex)
                }
            }
            itemToDelete = nil
        }
    }
    
    func handleDeleteCategory(sIndex: Int) {
        // ✅ Trigger delete kategori via bus global
        itemToDelete = (.category, sIndex, nil)
        deleteBus.request(message: "Apakah Anda yakin ingin menghapus kategori ini?") {
            if let item = itemToDelete, item.type == .category {
                withAnimation {
                    // ViewModel akan membersihkan validationErrors by UUID
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
    }
}
