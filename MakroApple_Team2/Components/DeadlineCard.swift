//
//  DeadlieCard.swift
//  MakroApple_Team2
//
//  Created by Edward Suwandi on 21/10/25.
//

import SwiftUI

struct DeadlineCard: View {
    var orders: [OrderRecord]
    
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
                Image(systemName: "bookmark.fill")
                    .font(.title3)
            }
            
            
            
            VStack(alignment: .leading) {
                Text("Deadline Hari Ini")
                    .font(.title2)
                .fontWeight(.bold)
                
                Spacer()
                Text("\(todayDeadlineCount) Pesanan yang perlu selesai")
                    .font(.body)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(.primaryButton)
        .background(.deadlineCard)
        .frame(height: 80)
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
