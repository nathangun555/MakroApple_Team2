//
//  OrderItemsTableView.swift
//  MakroApple_Team2
//
//  Created by Edward Suwandi on 12/11/25.
//

import SwiftUI

struct OrderItemsTableView: View {
    
    var displayOrderItem : [InvoiceOrderItem]
    
    var body: some View {
        VStack(spacing: 0) {
            // Table Header
            HStack {
                Text("Deskripsi Barang")
                    .font(.system(size: 10, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Harga satuan")
                    .font(.system(size: 10, weight: .bold))
                    .frame(width: 70)
                
                Text("Jumlah")
                    .font(.system(size: 10, weight: .bold))
                    .frame(width: 50)
                
                Text("Diskon")
                    .font(.system(size: 10, weight: .bold))
                    .frame(width: 70)
                
                Text("Total Harga")
                    .font(.system(size: 10, weight: .bold))
                    .frame(width: 70, alignment: .trailing)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
            .background(Color(.systemGray5))
            
            ForEach(displayOrderItem) { item in
                VStack(spacing: 0) {
                    HStack {
                        Text(item.description)
                            .font(.system(size: 10))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("Rp. \(item.unitPrice.formatted())")
                            .font(.system(size: 10))
                            .frame(width: 70)
                        
                        Text("\(item.quantity)")
                            .font(.system(size: 10))
                            .frame(width: 50)
                        
                        Text("Rp. \(item.discount.formatted())")
                            .font(.system(size: 10))
                            .frame(width: 70)
                        
                        Text("Rp. \(item.total.formatted())")
                            .font(.system(size: 10))
                            .frame(width: 70, alignment: .trailing)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 6)
                    
                    Divider()
                }
            }
        }
    }
}

#Preview {
    let sampleItems = [
        InvoiceOrderItem(description: "Produk A", unitPrice: 50000, quantity: 2, discount: 5000, total: 95000),
        InvoiceOrderItem(description: "Produk B", unitPrice: 75000, quantity: 1, discount: 0, total: 75000),
        InvoiceOrderItem(description: "Produk C", unitPrice: 100000, quantity: 3, discount: 15000, total: 285000)
    ]
    
    OrderItemsTableView(displayOrderItem: sampleItems)
        .padding()
        .previewLayout(.sizeThatFits)
}
