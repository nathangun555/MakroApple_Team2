//
//  Set_MenuDetailsView.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 17/10/25.
//

import SwiftUI

struct Set_MenuDetailsView: View {
    @EnvironmentObject var session: SessionManager
    @StateObject private var vm = Set_MenuDetailsViewModel()

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
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
                            // 🔹 Header kategori
                            HStack {
                                if section.isEditing {
                                    TextField("Nama Kategori", text: Binding(
                                        get: { section.title },
                                        set: { newValue in
                                            vm.sections[sIndex].title = newValue
                                        }
                                    ))
                                    .font(.headline)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                } else {
                                    Text(section.title)
                                        .font(.headline)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                }

                                Spacer()

                                // Tombol Delete Kategori
                                if section.isEditing {
                                    Button {
                                        withAnimation {
                                            vm.markCategoryDeleted(sectionIndex: sIndex)
                                        }
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
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

                            Divider()

                            // 🔹 Tombol tambah produk (muncul saat edit)
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

                            // 🔹 Daftar produk
                            VStack(spacing: 14) {
                                ForEach(section.items) { item in
                                    EditableProductRow(
                                        viewModel: item,
                                        isEditing: section.isEditing,
                                        onDelete: {
                                            withAnimation {
                                                vm.markProductDeleted(sectionIndex: sIndex, productId: item.id)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                        .padding(14)
                        .background(Color(.white))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 100)
                }
                .padding(.top)
            }

            // 🔹 Floating Button Tambah Kategori
            .overlay(alignment: .bottom){
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
        .navigationTitle("Rincian Isi Katalog")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task {
                        await vm.saveAll()
                    }
                } label: {
                    if vm.isLoading {
                        ProgressView()
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                    }
                }
                .disabled(vm.isLoading)
            }
        }
        .task {
            vm.configure(userId: session.userId)
            await vm.load()
        }
    }
}

struct EditableProductRow: View {
    @ObservedObject var viewModel: EditableProduct
    var isEditing: Bool
    var onDelete: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 10) {

                // 🔹 Nama Produk
                HStack(alignment: .center) {
                    Text("Nama Produk :")
                        .font(.subheadline)
                        .frame(width: 110, alignment: .leading)

                    TextField("Silakan Isi Nama Produk", text: $viewModel.name)
                        .disabled(!isEditing)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .background(Color(.white))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1))
                        .cornerRadius(8)
                        .frame(maxWidth: .infinity)
                        .opacity(isEditing ? 1 : 0.7)
                }

                // 🔹 Harga Produk
                HStack(alignment: .center) {
                    Text("Harga Produk :")
                        .font(.subheadline)
                        .frame(width: 110, alignment: .leading)

                    TextField(
                        "Rp 0",
                        value: Binding(
                            get: { Double(truncating: NSDecimalNumber(decimal: viewModel.price)) },
                            set: { newDouble in
                                viewModel.price = Decimal(string: String(format: "%.0f", newDouble)) ?? viewModel.price
                            }
                        ),
                        formatter: NumberFormatter.currencyFormatter()
                    )
                    .keyboardType(.numberPad)
                    .disabled(!isEditing)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background(Color(.white))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1))
                    .cornerRadius(8)
                    .frame(maxWidth: .infinity)
                    .opacity(isEditing ? 1 : 0.7)
                }
            }

            // 🔹 Tombol Hapus (muncul saat edit)
            if isEditing {
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .padding(.leading, 6)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        .frame(maxWidth: .infinity)
    }
}

// 🔹 Formatter helper
extension NumberFormatter {
    static func currencyFormatter() -> NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "IDR"
        f.maximumFractionDigits = 0
        return f
    }
}


#Preview {
    let session = SessionManager()
    session.isSignedIn = true
    session.userId = "083dc90d-ca03-4f45-a631-06fe21fe750f"

    return NavigationStack {
        Set_MenuDetailsView()
            .environmentObject(session)
    }
}
