////
////  WidgetViews.swift
////  MakroApple_Team2
////
////  Created by Edward Suwandi on 20/11/25.
////

import SwiftUI
import WidgetKit



struct CustomerMediumWidgetView: View {
    let orders: [OrderRecord]
    let orderItems: [OrderItemRecord]

    let dateFormatterHelper = DateFormatterHelper()
    
    var body: some View {
        let filtered = orders.filteredOrders
        let leftOrder = filtered.first
        let rightOrders = Array(filtered.dropFirst().prefix(2))
        let remainingCount = max(filtered.count - 3, 0)
        
        if filtered.isEmpty {
            VStack (alignment: .leading){
                
                HStack {
                    Text(dateComponents.day)
                        .font(.largeTitle.bold())
                        .foregroundColor(.primaryButton)
                    
                    Text(dateComponents.monthYear)
                        .font(.footnote.bold())
                        .foregroundColor(.primary)
                    
                    
                }
                
                HStack{
                    Image(systemName: "book.pages.fill")
                        .font(.title)
                        .foregroundColor(.primaryButton)
                        .padding(12)
                        .background(
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                        )
                    
                    VStack(alignment: .leading){
                        Text("Belum Ada Pesanan")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Belum ada pesanan yang tercatat.\nTambah pesanan baru untuk mulai kelola penjualanmu dengan mudah.")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.leading)
                        
                    }
                    
                }
                
            }
            .containerBackground(for: .widget) {
                Color(.systemBackground)
            }
        }
        else {
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
}

struct CustomerLargeWidgetView : View {
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
                VStack {
                    Image(systemName: "book.pages.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                        .padding(12)
                        .background(
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                        )
                    
                    Text("Belum Ada Pesanan")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Belum ada pesanan yang tercatat.\nTambah pesanan baru untuk mulai kelola penjualanmu dengan mudah.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
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
            
            Spacer()
        }
        .padding(.top, 10)
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
    
}


struct OrderLargeWidgetView : View {
    let orders: [OrderRecord]
    let orderItems: [OrderItemRecord]
    
    var body: some View {
        
        let groupedItems = Dictionary(grouping: orderItems) { $0.productName }
        
        let sortedTypes = groupedItems.keys.sorted()
        
        let displayedTypes = Array(sortedTypes.prefix(4))
        let remainingCount = max(sortedTypes.count - 4, 0)
        
        VStack(alignment: .leading) {
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
            
            ForEach(displayedTypes, id: \.self) { type in
                
                if let items = groupedItems[type] {
                    
                    // ORDER LIST
                    HStack(spacing: 12) {
                        
                        // Jumlah Pesanan Produk
                        Text("\(items.count)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primaryButton)
                        
                            .padding(4)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.white)
                            )
                        
                        
                        // Nama Produk
                        Text(type)
                            .font(.headline)
                        
                        Spacer()
                        
                        
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color("DeadlineCard"))
                    )
                    
                    
                  
                }
            }
            
            // + MORE
            if remainingCount > 0 {
                Text("+ \(remainingCount) Produk")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primaryButton)
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
            }
            
            
            Spacer()
            
                .containerBackground(for: .widget) {
                    Color(.systemBackground)
                }
            
        }
    }
}
