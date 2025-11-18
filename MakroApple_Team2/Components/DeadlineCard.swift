//
//  DeadlieCard.swift
//  MakroApple_Team2
//
//  Created by Edward Suwandi on 21/10/25.
//

import SwiftUI

struct DeadlineCard: View {
    var orders: [OrderRecord]
    var hastemplates: Bool
    
    private var todayDeadlineCount: Int {
        let today = Calendar.current.startOfDay(for: Date())
        
        let validStatuses = ["diproses", "terkirim", "selesai"]

        return orders.filter { order in
            // Filter berdasarkan status valid
            let status = order.status.lowercased()
            guard validStatuses.contains(status) else {
                return false
            }
            
            // Konversi dan bandingkan tanggal
            guard let date = DateFormatterHelper.toDate(order.orderDdayDate) else {
                return false
            }
            let parsedDayStart = Calendar.current.startOfDay(for: date)
            return parsedDayStart == today
        }.count
    }



    
    var body: some View {
        
        
        // Today's Deadline Card
        HStack {
            VStack {
                Image(systemName: hastemplates ? "bookmark.fill" : "building.2.crop.circle.fill")
                    .font(.title3)
            }
            VStack(alignment: .leading) {
                Text(hastemplates ? "Deadline Hari Ini" : "Data Bisnis Belum Dilengkapi")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(hastemplates ? "\(todayDeadlineCount) Pesanan yang perlu selesai" : "Untuk menambahkan pesanan pertama Anda, lengkapi terlebih dahulu data bisnis yang diperlukan.")
                    .font(.caption)
            }
            
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(.primaryButton)
        .background(.deadlineCard)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cornerRadius(10)
        .padding(.horizontal)
        
        
        
    }
    
}

//#Preview {
//    // Create a stub session
//    let session = SessionManager()
//    session.isSignedIn = true
//    session.userId = "083dc90d-ca03-4f45-a631-06fe21fe750f"
//    
//    // Create the view
//    let view = AllOrdersView()
//    
//    // Inject the environment object
//    return view.environmentObject(session)
//}
