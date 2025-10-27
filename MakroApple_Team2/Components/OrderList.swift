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
    let selectedDate: Date
    let calendar = Calendar.current
    var viewModel = AllOrdersViewModel()
    let sortOption: String
    
    var body: some View {
        let ordersForSelectedDate = viewModel.ordersForDate(for: selectedDate)
        
        if ordersForSelectedDate.isEmpty {
            Text("Tidak ada pesanan")
                .foregroundStyle(.secondary)
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
                                NavigationLink(destination: OrderDetailView(order: order, orderItem: [firstItem])) {
                                    OrderCard(order: order, orderItem: firstItem)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        
                    } else {
                        // --- SORT BY NAME (GROUPED BY PRODUCT TYPE) ---
                        
                        // Ambil semua item order yang relevan dengan tanggal itu
                        let itemsForDate = viewModel.orderItems.filter { item in
                            ordersForSelectedDate.contains { $0.id == item.orderId }
                        }
                        
                        // Kelompokkan berdasarkan productType
                        let groupedItems = Dictionary(grouping: itemsForDate) { $0.productType }
                        
                        // Urutkan productType secara alfabet
                        let sortedTypes = groupedItems.keys.sorted()
                        
                        ForEach(sortedTypes, id: \.self) { type in
                            if let items = groupedItems[type] {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(type.uppercased())
                                        .font(.title3.bold())
                                        .padding(.horizontal)
                                    
                                    // Urutkan nama produk di dalam group
                                    let sortedItems = items.sorted {
                                        $0.productName.localizedCaseInsensitiveCompare($1.productName) == .orderedAscending
                                    }
                                    
                                    ForEach(sortedItems) { item in
                                        if let order = ordersForSelectedDate.first(where: { $0.id == item.orderId }) {
                                            NavigationLink(destination: OrderDetailView(order: order, orderItem: [item])) {
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
