//
//  ConfirmMenuView.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 07/11/25.
//

import SwiftUI

struct ConfirmMenuView: View {
    
    @EnvironmentObject var session: SessionManager
    @StateObject private var vm = Set_MenuDetailsViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showUnsavedChangesAlert = false
    @State private var navigateToTemplateForm = false
    
    @Binding var isDismissed: Bool
    
    let scannedCategories: [MenuCategory] // ✅ Add this parameter
    
    var body: some View {
        ZStack {
            contentView
                .navigationTitle("Rincian Isi Katalog")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
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
                                Image(systemName: "checkmark")
                                    .font(.title3)
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!vm.hasPendingChanges || vm.isLoading)
                        .tint(.primaryButton)
                    }
                }
            .disabled(showUnsavedChangesAlert)
            
            if showUnsavedChangesAlert {
                Color.black
                    .opacity(showUnsavedChangesAlert ? 0.45 : 0)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.25), value: showUnsavedChangesAlert)
                    .zIndex(10)
                
                CustomUnsavedAlert(
                    title: "Perubahan Belum Disimpan",
                    message: "Apakah Anda yakin ingin membatalkan perubahan yang telah dibuat?",
                    cancelTitle: "Tidak",
                    confirmTitle: "Ya",
                    onCancel: { withAnimation { showUnsavedChangesAlert = false } },
                    onConfirm: { withAnimation { dismiss() } }
                )
                .zIndex(11)
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showUnsavedChangesAlert)
            }
        }
        .task {
            vm.configure(userId: session.userId)
            
            // ✅ Load from scanned data instead of database
            if !scannedCategories.isEmpty {
                await vm.loadFromScan(categories: scannedCategories)
            } else {
                await vm.load()
            }
        }
        .navigationDestination(isPresented: $navigateToTemplateForm) {
            NewTemplateFormView(isDismissed: $isDismissed)
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
                    
                    // ✅ Show scan info banner
                    if vm.isLoadedFromScan {
                        scanInfoBanner
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
                                    }
                                    
                                    Spacer()
                                    
                                    if section.isEditing {
                                        Button {
                                            withAnimation {
                                                vm.deleteTemporaryCategory(at: sIndex)
                                            }
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
                                
                                if vm.validationErrors.contains("\(sIndex)-cat") {
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
                                                withAnimation {
                                                    vm.deleteTemporaryProduct(from: sIndex, at: pIndex)
                                                }
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
            .padding(.bottom, 0)
        }
    }
    
    // ✅ Info banner showing scan results
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
            
            Text("Silakan periksa dan edit jika ada kesalahan sebelum menyimpan")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
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
