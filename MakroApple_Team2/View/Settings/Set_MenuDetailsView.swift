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
                            Text("Rincian Isi Catalog")
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
                                    .foregroundColor(.blue)
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
                                        .foregroundColor(vm.hasPendingChanges ? .blue : .gray)
                                }
                            }

                            if vm.hasPendingChanges {
                                button.buttonStyle(BorderedProminentButtonStyle())
                            } else {
                                button.buttonStyle(BorderlessButtonStyle())
                            }
                        }
                        
                    }
            }
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
                                        Text(section.isEditing ? "Selesai" : "Edit")
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                    }
                                }
                                
                                // Error nama kategori (UUID-based)
                                if vm.validationErrors.contains("\(section.id.uuidString)-cat") {
                                    HStack(spacing: 0) {
                                        Text("Nama kategori tidak boleh kosong")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                            .padding(.leading, 3)
                                        Spacer()
                                    }
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
                                    .foregroundColor(.blue)
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
                .background(Color.blue)
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

// MARK: - Custom Alert (unsaved)
struct CustomUnsavedAlert: View {
    var title: String
    var message: String
    var cancelTitle: String
    var confirmTitle: String
    var onCancel: () -> Void
    var onConfirm: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { onCancel() }
            
            VStack(spacing: 20) {
                Image(systemName: "gear.badge.xmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(Color.blue)
                    .padding(.top, 8)
                
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(.system(size: 15))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom, 6)
                
                HStack(spacing: 16) {
                    Button(action: onCancel) {
                        Text(cancelTitle)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.9))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray3))
                            .clipShape(Capsule())
                    }
                    
                    Button(action: onConfirm) {
                        Text(confirmTitle)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 8)
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 20)
            .background(Color.white)
            .cornerRadius(20)
            .padding(.horizontal, 40)
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
        }
        .transition(.opacity .combined(with: .scale))
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: UUID())
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
