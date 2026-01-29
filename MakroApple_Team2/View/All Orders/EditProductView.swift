//
//  EditProductView.swift
//  MakroApple_Team2
//
//  Created by Assistant
//

import SwiftUI

struct EditProductView: View {
    @Binding var product: ProductItem
    @Environment(\.dismiss) var dismiss
    
    @State private var productName: String = ""
    @State private var quantity: Int = 1
    @State private var unitPriceText: String = ""
    @State private var discountText: String = ""
    @State private var description: String = ""
    
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case name, quantity, price, discount, description
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Rincian Produk Header
                    HStack {
                        Text("Rincian Produk")
                            .font(.title3)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    .padding()
                    .background(Color.white)
                    
                    Divider()
                    
                    VStack(spacing: 0) {
                        // Nama Produk
                        ProductEditRow(
                            label: "Nama Produk",
                            value: $productName,
                            focusedField: $focusedField,
                            field: .name
                        )
                        
                        Divider()
                        
                        // Kuantitas
                        HStack {
                            Text("Kuantitas")
                                .frame(width: 140, alignment: .leading)
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            HStack(spacing: 12) {
                                Button {
                                    if quantity > 1 {
                                        quantity -= 1
                                    }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.primaryButton)
                                }
                                
                                Text("\(quantity)")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .frame(minWidth: 40)
                                
                                Button {
                                    quantity += 1
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.primaryButton)
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        
                        Divider()
                        
                        // Harga Satuan
                        ProductEditRow(
                            label: "Harga Satuan",
                            value: $unitPriceText,
                            focusedField: $focusedField,
                            field: .price,
                            isCurrency: true
                        )
                        
                        Divider()
                        
                        // Diskon
                        ProductEditRow(
                            label: "Diskon",
                            value: $discountText,
                            focusedField: $focusedField,
                            field: .discount,
                            isCurrency: true
                        )
                        
                        Divider()
                        
                        // Deskripsi
                        ProductEditRow(
                            label: "Deskripsi",
                            value: $description,
                            focusedField: $focusedField,
                            field: .description,
                            isMultiline: true
                        )
                    }
                    .background(Color.white)
                    .cornerRadius(10)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Edit Produk")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(.primaryButton)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        saveProduct()
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.title3)
                            .foregroundColor(.primaryButton)
                    }
                }
            }
            .onAppear {
                loadProduct()
            }
        }
    }
    
    private func loadProduct() {
        productName = product.name
        quantity = product.quantity
        unitPriceText = product.productPrice == 0 ? "" : product.productPrice.formatted()
        discountText = product.discount == 0 ? "" : product.discount.formatted()
        description = "" // ProductItem doesn't have description yet, but keeping for future
    }
    
    private func saveProduct() {
        product.name = productName
        product.quantity = quantity
        
        // Parse price
        let cleanPrice = unitPriceText.filter("0123456789".contains)
        product.productPrice = Decimal(string: cleanPrice) ?? 0
        
        // Parse discount
        let cleanDiscount = discountText.filter("0123456789".contains)
        let discountValue = Decimal(string: cleanDiscount) ?? 0
        product.discount = applyDiscountLimit(product.productPrice, quantity, discountValue)
        
        product.updatedAt = ISO8601DateFormatter().string(from: Date())
    }
    
    private func applyDiscountLimit(_ price: Decimal, _ qty: Int, _ newVal: Decimal) -> Decimal {
        let maxDiscount = price * Decimal(qty)
        return min(newVal, maxDiscount)
    }
}

struct ProductEditRow: View {
    let label: String
    @Binding var value: String
    @FocusState.Binding var focusedField: EditProductView.Field?
    let field: EditProductView.Field
    var isCurrency: Bool = false
    var isMultiline: Bool = false
    
    var body: some View {
        HStack(alignment: isMultiline ? .top : .center) {
            Text(label)
                .frame(width: 140, alignment: .leading)
                .font(.body)
                .foregroundColor(.primary)
                .padding(.top, isMultiline ? 12 : 0)
            
            Spacer()
            
            if isMultiline {
                TextField("Opsional", text: $value, axis: .vertical)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .focused($focusedField, equals: field)
                    .lineLimit(3...6)
                    .padding(.top, 12)
            } else if isCurrency {
                TextField("Rp 0,00", text: Binding(
                    get: {
                        if focusedField == field {
                            return value.isEmpty ? " Rp " : value
                        }
                        return value.isEmpty ? "" : value
                    },
                    set: { newValue in
                        if isCurrency {
                            let clean = newValue.filter("0123456789".contains)
                            if let decimal = Decimal(string: clean) {
                                value = decimal.formatted()
                            } else if clean.isEmpty {
                                value = ""
                            } else {
                                value = newValue
                            }
                        } else {
                            value = newValue
                        }
                    }
                ))
                .font(.body)
                .multilineTextAlignment(.trailing)
                .keyboardType(.numberPad)
                .focused($focusedField, equals: field)
            } else {
                TextField("", text: $value)
                    .font(.body)
                    .multilineTextAlignment(.trailing)
                    .focused($focusedField, equals: field)
            }
        }
        .padding()
        .background(Color.white)
    }
}
