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
    let orderItem: OrderItemRecord
    
//    let order : Order
    var body: some View {
        HStack{

            // Indikator
            RoundedRectangle(cornerRadius: 10)
                .frame(width: 6)
                .foregroundColor(.yellow)
                .padding(.vertical, 3)
            
            // Card
            VStack(alignment: .leading){
                
                // Row 1
                HStack{
                    
                    // Nama Customer
                    Text(order.customerOrderName ?? "Unknown Customer")
                    
                    Spacer()
                    
                    // Tanggal Pesan
                    Text(DateFormatterHelper.formattedDate(order.orderDdayDate!, showTime: true))
                    
                    
                    Image(systemName: "chevron.right")
                    
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                
                // Pesanan
                Text(orderItem.productName)
                    .font(Font.body.bold())
                
                // Tambahan
                Text("+ 3 more")
                    .font(Font.subheadline)
                    .foregroundColor(.secondary)
                
            }
            .padding()
        }
        
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.white.opacity(0.15), Color.orange.opacity(0.15)]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(10)
        .frame(height: 100)
        .padding(.horizontal, 20)
        
        
       
        
    }
}

//#Preview {
//    mainta()
//}


