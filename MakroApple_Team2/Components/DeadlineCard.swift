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
    @Binding var isTutorial: Bool
    
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
        VStack {
            HStack {
                VStack {
                    Image(systemName: hastemplates ? "bookmark.fill" : "building.2.crop.circle.fill")
                        .font(.title3)
                }
                VStack(alignment: .leading) {
                    Text(hastemplates ? "Deadline Hari Ini" : "Lengkapi Data Bisnis Anda")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(hastemplates ? "\(todayDeadlineCount) Pesanan yang perlu selesai" : "Selesaikan data bisnis sebelum menambah pesanan.")
                        .font(.caption)
                }
            }
            if !hastemplates {
                Button(action: {
                    isTutorial = true
                }) {
                    Text("Atur Sekarang")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(.primaryButton)
                        .foregroundColor(.white)
                        .cornerRadius(30)
                }
                .padding(.top, 8)
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
