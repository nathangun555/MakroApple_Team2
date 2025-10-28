//
//  Set_MenuDetailsView.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 17/10/25.
//

import SwiftUI

struct Set_MenuDetailsView: View {
    @EnvironmentObject var session: SessionManager
    @StateObject private var vm = Set_MenuDetailsViewModel()

    var body: some View {
        VStack {
            if let err = vm.errorMessage {
                Text(err)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }

            List {
                ForEach(vm.sections.indices, id: \.self) { sIndex in
                    let section = vm.sections[sIndex]
                    Section(
                        header:
                            HStack {
                                if section.isEditing {
                                    TextField("Kategori", text: $vm.sections[sIndex].title)
                                        .textFieldStyle(.roundedBorder)
                                        .font(.headline)
                                } else {
                                    Text(section.title.uppercased())
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Button {
                                    vm.toggleEdit(sectionIndex: sIndex)
                                } label: {
                                    Text(section.isEditing ? "Done" : "Edit")
                                        .font(.subheadline)
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 10)
                                        .background(.thinMaterial)
                                        .cornerRadius(12)
                                }
                            }
                            .padding(.vertical, 4)
                    ) {
                        ForEach(section.items) { item in
                            EditableProductRow(viewModel: item, isEditing: section.isEditing)
                        }
                        .listRowBackground(Color(uiColor: .secondarySystemBackground))
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Rincian Isi Katalog")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await vm.saveAll()
                        }
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                    }
                    .disabled(vm.isLoading)
                }
            }
        }
        .task {
            vm.configure(userId: session.userId)
            await vm.load()
        }
        // Floating + button (sementara nonaktif)
        .overlay(alignment: .bottomTrailing) {
            Button {
                // temporarily no-op
            } label: {
                Image(systemName: "plus")
                    .foregroundColor(.white)
                    .font(.title)
                    .padding()
                    .background(Circle().fill(Color.blue))
            }
            .padding()
            .disabled(true)
        }
    }
}

// MARK: - EditableProductRow
struct EditableProductRow: View {
    @ObservedObject var viewModel: EditableProduct
    var isEditing: Bool

    private var priceFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "IDR"
        f.maximumFractionDigits = 0
        return f
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Nama Produk
            HStack {
                Text("Nama Produk :")
                    .frame(width: 110, alignment: .leading)
                if isEditing {
                    TextField("Nama Produk", text: $viewModel.name)
                        .textFieldStyle(.roundedBorder)
                } else {
                    Text(viewModel.name)
                        .foregroundColor(.primary)
                }
            }

            // Harga Produk
            HStack {
                Text("Harga Produk :")
                    .frame(width: 110, alignment: .leading)
                if isEditing {
                    TextField(
                        "Harga",
                        value: Binding(
                            get: { Double(truncating: NSDecimalNumber(decimal: viewModel.price)) },
                            set: { newDouble in
                                viewModel.price = Decimal(string: String(format: "%.0f", newDouble)) ?? viewModel.price
                            }
                        ),
                        formatter: NumberFormatter()
                    )
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                } else {
                    Text(formatCurrency(viewModel.price))
                }
            }
        }
        .padding(.vertical, 8)
    }

    private func formatCurrency(_ d: Decimal) -> String {
        let n = NSDecimalNumber(decimal: d)
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "IDR"
        f.maximumFractionDigits = 0
        return f.string(from: n) ?? "Rp\(n)"
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
