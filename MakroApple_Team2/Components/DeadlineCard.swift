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
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd" // adjust to your actual format
        
        return orders.filter {
            guard let dateString = $0.orderDdayDate, // String
                  let date = dateFormatter.date(from: dateString) else {
                return false
            }
            return Calendar.current.isDate(date, inSameDayAs: today)
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
