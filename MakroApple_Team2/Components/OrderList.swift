//
//  OrderList.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 27/10/25.
//

import SwiftUI
import Foundation

// MARK: - Order List View
struct OrderListView: View {
    
    @EnvironmentObject var session: SessionManager
    
    let selectedDate: Date
    let calendar = Calendar.current
    var viewModel = AllOrdersViewModel()
    let sortOption: String
    
    var body: some View {
        let ordersForSelectedDate = viewModel.ordersForDate(for: selectedDate)
        
        if ordersForSelectedDate.isEmpty {
            VStack {
                Image(systemName: "doc.text.fill")
                    .font(.title)
                    .foregroundColor(.blue)
                    .padding(12) // jarak dari icon ke tepi circle
                    .background(
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                    )

                        Text("Belum Ada Pesanan")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Text("Belum ada pesanan yang tercatat.\nTambah pesanan baru untuk mulai kelola penjualanmu dengan mudah.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
            .frame(maxWidth: .infinity, minHeight: 500)
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if sortOption == "Waktu" {
                        // --- SORT BY TIME ---
                        let sortedOrders = ordersForSelectedDate.sorted { a, b in
                            let dateA = DateFormatterHelper.toDate(a.orderDdayDate ?? "") ?? .distantPast
                            let dateB = DateFormatterHelper.toDate(b.orderDdayDate ?? "") ?? .distantPast
                            return dateA < dateB
                        }
                        
                        ForEach(sortedOrders) { order in
                            if let firstItem = viewModel.orderItems.first(where: { $0.orderId == order.id }) {
                                NavigationLink(
                                    destination:
                                        OrderDetailView(
                                            order: order,
                                            orderItem: [firstItem],
                                            source: .allOrders,
                                            activeTab: .constant(.belumBayar)
                                        )
                                        .environmentObject(session) ) {
                                            OrderCard(order: order, orderItem: firstItem)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                            }
                        }
                        
                    }
                    else {
                        // --- SORT BY NAME (GROUPED BY PRODUCT TYPE) ---
                        
                        // Ambil semua item order yang relevan dengan tanggal itu
                        let itemsForDate = viewModel.orderItems.filter { item in
                            ordersForSelectedDate.contains { $0.id == item.orderId }
                        }
                        
                        // Kelompokkan berdasarkan productType
                        let groupedItems = Dictionary(grouping: itemsForDate) { $0.productName }
                        
                        // Urutkan productType secara alfabet
                        let sortedTypes = groupedItems.keys.sorted()
                        
                        ForEach(sortedTypes, id: \.self) { type in
                            if let items = groupedItems[type] {
                                VStack(alignment: .leading, spacing: 8) {
                                    
                                    HStack {
                                        Text(type.uppercased())
                                            .font(.title3.bold())
                                        
                                        Spacer()
                                        
                                        Text("\(items.count)")
                                            .padding(.vertical, 3)
                                            .padding(.horizontal, 6)
                                            .font(.headline.bold())
                                            .foregroundColor(.blue)
                                            .background(Color.clear)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.blue, lineWidth: 2)
                                            )
                                        
                                    }
                                    .padding(.horizontal)
                                    
                                    Divider()
                                        .padding(.bottom, 3)
                                    
                                    // Urutkan nama produk di dalam group
                                    let sortedItems = items.sorted {
                                        $0.productName.localizedCaseInsensitiveCompare($1.productName) == .orderedAscending
                                    }
                                    
                                    ForEach(sortedItems) { item in
                                        if let order = ordersForSelectedDate.first(where: { $0.id == item.orderId }) {
                                            NavigationLink(
                                                destination:
                                                    OrderDetailView(
                                                        order: order,
                                                        orderItem: [item],
                                                        source: .allOrders,
                                                        activeTab: .constant(.belumBayar)
                                                    )
                                                    .environmentObject(session)
                                            ) {
                                                OrderCard(order: order, orderItem: item)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                                .padding(.bottom, 12)
                            }
                        }
                    }
                }
                .padding(.top, 16)
            }
        }
    }
}
