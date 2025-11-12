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
                        
                        Text(item.unitPrice.formatted())
                            .font(.system(size: 10))
                            .frame(width: 70)
                        
                        Text("\(item.quantity)")
                            .font(.system(size: 10))
                            .frame(width: 50)
                        
                        Text(item.total.formatted())
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
