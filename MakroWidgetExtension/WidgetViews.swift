////
////  WidgetViews.swift
////  MakroApple_Team2
////
////  Created by Edward Suwandi on 20/11/25.
////

import SwiftUI
import WidgetKit

let widgetStatusColors: [String: Color] = [
    "Belum Terbayar": .belumBayar,
    "Diproses": .diproses,
    "Terkirim": .terkirim,
    "Selesai": .selesai,
    "Dibatalkan": .dibatalkan
]

extension Array where Element == OrderRecord {
    /// Filter status tertentu dan urutkan berdasarkan jam
    var filteredOrders: [OrderRecord] {
        self
            .filter { !["Belum Terbayar", "Dibatalkan"].contains($0.status) } // filter status
            .sorted {
                let date0 = ISO8601DateFormatter().date(from: $0.orderDdayDate ?? "") ?? Date.distantPast
                let date1 = ISO8601DateFormatter().date(from: $1.orderDdayDate ?? "") ?? Date.distantPast
                return date0 < date1
            }
    }
}



@ViewBuilder
func mediumWidgetOrderCard(time: String, title: String, color: Color) -> some View {
    HStack(spacing: 4) {
        RoundedRectangle(cornerRadius: 3)
            .frame(width: 6)
            .foregroundColor(color)
        
        VStack(alignment: .leading, spacing: 2) {
            Text(time)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.caption.bold())
                .lineLimit(1)
        }
        
        Spacer()
    }
    .padding(.vertical, 4)
    .padding(.horizontal, 4)
    .frame(maxWidth: .infinity, maxHeight: 50)
    .background(
        LinearGradient(colors: [Color.white.opacity(0.15), color.opacity(0.20)],
                       startPoint: .leading,
                       endPoint: .trailing)
    )
    .clipShape(RoundedRectangle(cornerRadius: 10))
}


@ViewBuilder
func largeWidgetOrderCard(name: String, title: String, time: String, color: Color, extraCount: Int) -> some View {
    HStack(spacing: 10) {

        RoundedRectangle(cornerRadius: 3)
            .frame(width: 6)
            .foregroundColor(color)

        VStack(alignment: .leading, spacing: 6) {
            
            HStack{
                
                Text(name)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                Spacer()
                Text(time)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Text(title)
                .font(.system(size: 15, weight: .semibold))
            
            if extraCount > 0 {
                Text("+\(extraCount) more")
                    .font(Font.caption2.bold())
                    .foregroundColor(.secondary)
            }
            
        }
        .padding(.vertical,10)

        Spacer()

       
    }
    .frame(maxHeight: 70)
//    .padding(.vertical, 6)
    .padding(.horizontal, 6)
    
    .background(
        LinearGradient(
            colors: [Color.white.opacity(0.15), color.opacity(0.15)],
            startPoint: .leading,
            endPoint: .trailing
        )
    )
    .clipShape(RoundedRectangle(cornerRadius: 16))
}

var dateComponents: (day: String, monthYear: String) {
    let date = Date()
    let day = Calendar.current.component(.day, from: date).description

    let formatter = DateFormatter()
    formatter.dateFormat = "MMMM yyyy"
    let monthYear = formatter.string(from: date)

    return (day, monthYear)
}

struct MediumWidgetView: View {
    let orders: [OrderRecord]
    let orderItems: [OrderItemRecord]

    let dateFormatterHelper = DateFormatterHelper()
    
    
    var body: some View {
        let filtered = orders.filteredOrders
        let leftOrder = filtered.first
        let rightOrders = Array(filtered.dropFirst().prefix(2))
        let remainingCount = max(filtered.count - 3, 0)
        
        
        
        HStack(alignment: .top, spacing: 15) {
            
            // LEFT SIDE
            VStack(alignment: .leading, spacing: 8) {
                Text(dateComponents.day)
                    .font(.largeTitle.bold())
                    .foregroundColor(.primaryButton)
                
                Text(dateComponents.monthYear)
                    .font(.footnote.bold())
                    .foregroundColor(.primary)
                
                
                if let order = leftOrder {
                           let items = orderItems.filter { $0.orderId == order.id }
                    mediumWidgetOrderCard(
                               time: DateFormatterHelper.formattedTime(order.orderDdayDate ?? "-"),
                               title: items.first?.productName ?? "-",
                               color: widgetStatusColors[order.status] ?? .gray.opacity(0.5)
                           )
                       }
            }
            
            // RIGHT SIDE
            VStack(alignment: .leading, spacing: 8) {
                ForEach(rightOrders) { order in
                            let items = orderItems.filter { $0.orderId == order.id }
                    mediumWidgetOrderCard(
                                time: DateFormatterHelper.formattedTime(order.orderDdayDate ?? "-"),
                                title: items.first?.productName ?? "-",
                                color: widgetStatusColors[order.status] ?? .gray.opacity(0.5)
                            )
                        }

                        // Sisa pesanan
                        if remainingCount > 0 {
                            Text("+ \(remainingCount) Pesanan")
                                .font(.caption.bold())
                                .foregroundColor(.primaryButton)
                        }
            }
            
            
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}

struct LargeWidgetView : View {
    let orders: [OrderRecord]
    let orderItems: [OrderItemRecord]
    

    
    var body : some View {
        let filteredOrders = orders.filteredOrders
        let remainingCount = max(filteredOrders.count - 3, 0)
        
        
        VStack(alignment: .leading, spacing: 8) {
            // HEADER
            HStack(alignment: .bottom) {
                Text(dateComponents.day)
                    .font(.largeTitle.bold())
                    .foregroundColor(.primaryButton)
                
                Text(dateComponents.monthYear)
                    .font(.default.bold())
                    .padding(.bottom, 8)
                
                Spacer()
            }
            
            // ORDER LIST
            
            if filteredOrders.isEmpty {
                Spacer()
                Text("No Orders Today")
                    .frame(maxWidth:.infinity,alignment: .center)
                    .foregroundColor(.secondary)
                Spacer()
            }
            else {
                ForEach(filteredOrders.prefix(3)) { order in
                    
                    let items = orderItems.filter { $0.orderId == order.id }
                    let extraCount = max(items.count - 1, 0)
                    
                    largeWidgetOrderCard(
                        name: order.customerOrderName,
                        title: items.first?.productName ?? "-",
                        time: DateFormatterHelper.formattedTime(order.orderDdayDate ?? "-"),
                        color: widgetStatusColors[order.status] ?? .gray.opacity(0.5),
                        extraCount: extraCount
                    )
                }
                
                if remainingCount > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        
                        Text("+ \(remainingCount) Pesanan")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .padding(.top, 4)
                    .foregroundColor(.primaryButton)
                    .padding(.horizontal, 16)
                }
            }
            
            // EXTRA ORDERS
            Spacer()
        }
        .padding(.top, 10)
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
    
}
