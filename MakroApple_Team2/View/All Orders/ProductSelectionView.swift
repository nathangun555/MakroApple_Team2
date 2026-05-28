//
//  ProductSelectionView.swift
//  MakroApple_Team2
//
//  Created by Assistant
//

import SwiftUI

struct ProductSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var session: SessionManager
    
    let existingProducts: [ProductItem]
    let onProductSelected: (ProductItem) -> Void
    
    @State private var products: [ProductRecord] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchText: String = ""
    
    var filteredProducts: [ProductRecord] {
        if searchText.isEmpty {
            return products
        }
        return products.filter { product in
            product.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    ProgressView("Memuat produk...")
                } else if let error = errorMessage {
                    VStack {
                        Text("❌ Error")
                            .font(.headline)
                        Text(error)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button("Coba Lagi") {
                            Task {
                                await loadProducts()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    VStack(spacing: 0) {
                        // Search bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            TextField("Cari produk...", text: $searchText)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .padding(.top)
                        
                        if filteredProducts.isEmpty {
                            Spacer()
                            VStack {
                                Image(systemName: "tray")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                                Text(searchText.isEmpty ? "Tidak ada produk" : "Tidak ada produk yang cocok")
                                    .foregroundColor(.gray)
                                    .padding(.top)
                            }
                            Spacer()
                        } else {
                            List {
                                ForEach(filteredProducts) { product in
                                    ProductSelectionRow(
                                        product: product,
                                        isAlreadyAdded: existingProducts.contains(where: { $0.name == product.name })
                                    ) {
                                        selectProduct(product)
                                    }
                                }
                            }
                            .listStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("Pilih Produk")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(.primaryButton)
                    }
                }
            }
            .task {
                await loadProducts()
            }
        }
    }
    
    private func loadProducts() async {
        guard let userId = session.userId, let uuid = UUID(uuidString: userId) else {
            errorMessage = "User belum login"
            return
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            products = try await SupabaseManager.shared.fetchProducts(for: uuid)
        } catch {
            errorMessage = "Gagal memuat produk: \(error.localizedDescription)"
            print("❌ Error loading products: \(error)")
        }
    }
    
    private func selectProduct(_ productRecord: ProductRecord) {
        // Check if product already exists
        if existingProducts.contains(where: { $0.name == productRecord.name }) {
            // Product already exists, don't add again
            return
        }
        
        // Create new ProductItem from ProductRecord
        let nowString = ISO8601DateFormatter().string(from: Date())
        let newProduct = ProductItem(
            name: productRecord.name,
            quantity: 1,
            productPrice: productRecord.price,
            discount: 0,
            productType: productRecord.productType ?? "",
            createdAt: nowString,
            updatedAt: nowString
        )
        
        onProductSelected(newProduct)
        dismiss()
    }
}

struct ProductSelectionRow: View {
    let product: ProductRecord
    let isAlreadyAdded: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    if let productType = product.productType, !productType.isEmpty {
                        Text(productType)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Rp \(product.price.formatted())")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if isAlreadyAdded {
                        Text("Sudah ditambahkan")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.vertical, 8)
            .opacity(isAlreadyAdded ? 0.6 : 1.0)
        }
        .disabled(isAlreadyAdded)
    }
}
