//
//  OrderCardViewModel.swift
//  MakroApple_Team2
//
//  Created by Edward Suwandi on 13/10/25.
//

import SwiftUI

struct OrderCard: View {
    
    let order: OrderRecord
    @State private var viewModel = AllOrdersViewModel()
    let orderItem: [OrderItemRecord]
    
    var firstItem: OrderItemRecord? {
        orderItem.first
    }

    var remainingCount: Int {
        max(orderItem.count - 1, 0)
    }

//    let order : Order
    var body: some View {
        
        
        HStack{

            // Indikator
            RoundedRectangle(cornerRadius: 10)
                .frame(width: 6)
                .foregroundColor(statusColors[order.status] )
                .padding(.vertical, 3)
            
            // Card
            VStack(alignment: .leading){
                
                // Row 1
                HStack{
                    
                    // Nama Customer
                    Text(order.customerOrderName ?? "Unknown Customer")
                    
                    Spacer()
                    
                    // Tanggal Pesan
                    Text(DateFormatterHelper.formattedDate(order.orderDdayDate ?? "g", showTime: true))
                    
                    
                    Image(systemName: "chevron.right")
                    
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                
                Spacer()
                
                HStack {
                    // Pesanan
                    Text(firstItem?.productName ?? "-")
                        .font(Font.body.bold())
                    
                    Spacer()
                    
                    if order.downPayment != nil && (order.downPayment!) > 0 {
                        Text("DP")
                            .font(.caption)
                            .bold()
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(statusColors[order.status] ?? .gray .opacity(0.7)))
                    }
                }
                
               
                // Tambahan
                if remainingCount > 0 {
                    Text("+ \(remainingCount) produk lainnya")
                        .font(.caption)
                }
                
                
            }
            .padding()
        }
        .onAppear{
            
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.white.opacity(0.15),  (statusColors[order.status] ?? .gray).opacity(0.15)]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(10)
        .frame(height: 85)
        .padding(.horizontal, 20)
        
        
       
        
    }
}

