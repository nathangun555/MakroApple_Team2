//
//  OrderCardViewModel.swift
//  MakroApple_Team2
//
//  Created by Edward Suwandi on 13/10/25.
//

import SwiftUI

// MARK: - Order Status Color Extension
import SwiftUI

extension OrderRecord {
    var statusColor: Color {
        switch status {
        case "Belum Terbayar": return .belumBayar
        case "Diproses": return .diproses
        case "Terkirim": return .terkirim
        case "Selesai": return .selesai
        case "Dibatalkan": return .dibatalkan
        default: return .gray
        }
    }
}

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
                .foregroundColor(order.statusColor)
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
                
                Spacer()
                
                HStack {
                    // Pesanan
                    Text(orderItem.productName)
                        .font(Font.title3.bold())
                    
                    Spacer()
                    
                    if order.downPayment != nil {
                        Text("DP")
                            .font(.caption)
                            .bold()
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(order.statusColor.opacity(0.7)))
                    }
                }
                
               
                // Tambahan
//                Text("+ 3 more")
//                    .font(Font.subheadline)
//                    .foregroundColor(.secondary)
                
            }
            .padding()
        }
        
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.white.opacity(0.15), order.statusColor.opacity(0.15)]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(10)
        .frame(height: 85)
        .padding(.horizontal, 20)
        
        
       
        
    }
}

#Preview {
    // Create a stub session
    let session = SessionManager()
    session.isSignedIn = true
    session.userId = "083dc90d-ca03-4f45-a631-06fe21fe750f"
    
    // Create the view
    let view = AllOrdersView()
    
    // Inject the environment object
    return view.environmentObject(session)
}
