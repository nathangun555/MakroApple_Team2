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
    
    @Binding var expandedProducts: Set<String>
    
    var body: some View {
        let ordersForSelectedDate = viewModel.ordersForDate(for: selectedDate)
        
        if ordersForSelectedDate.isEmpty {
            OrderEmptyState()
            .frame(maxWidth: .infinity, minHeight: 275)
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
                            let items = viewModel.orderItems.filter { $0.orderId == order.id }
                            if !items.isEmpty {
                                NavigationLink(
                                    destination:
                                        OrderDetailView(
                                            order: order,
                                            orderItem: items,
                                            source: .allOrders,
                                            activeTab: .constant(.belumBayar)
                                        )
                                        .environmentObject(session)
                                ) {
                                    OrderCard(order: order, orderItem: items)

                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }

                        
                    }
//                    else {
//                        // --- SORT BY NAME (GROUPED BY PRODUCT TYPE) ---
//                        
//                        // Ambil semua item order yang relevan dengan tanggal itu
//                        let itemsForDate = viewModel.orderItems.filter { item in
//                            ordersForSelectedDate.contains { $0.id == item.orderId }
//                        }
//                        
//                        // Kelompokkan berdasarkan productType
//                        let groupedItems = Dictionary(grouping: itemsForDate) { $0.productName }
//                        
//                        // Urutkan productType secara alfabet
//                        let sortedTypes = groupedItems.keys.sorted()
//                        
//                        ForEach(sortedTypes, id: \.self) { type in
//                            if let items = groupedItems[type] {
//                                VStack(alignment: .leading, spacing: 8) {
//                                    
//                                    HStack {
//                                        Text(type.uppercased())
//                                            .font(.title3.bold())
//                                        
//                                        Spacer()
//                                        
//                                        Text("\(items.count)")
//                                            .padding(.vertical, 3)
//                                            .padding(.horizontal, 6)
//                                            .font(.headline.bold())
//                                            .foregroundColor(.blue)
//                                            .background(Color.clear)
//                                            .overlay(
//                                                RoundedRectangle(cornerRadius: 8)
//                                                    .stroke(Color.blue, lineWidth: 2)
//                                            )
//                                        
//                                    }
//                                    .padding(.horizontal)
//                                    
//                                    Divider()
//                                        .padding(.bottom, 3)
//                                    
//                                    // Urutkan nama produk di dalam group
//                                    let sortedItems = items.sorted {
//                                        $0.productName.localizedCaseInsensitiveCompare($1.productName) == .orderedAscending
//                                    }
//                                    
//                                    ForEach(sortedItems) { item in
//                                        if let order = ordersForSelectedDate.first(where: { $0.id == item.orderId }) {
//                                            NavigationLink(
//                                                destination:
//                                                    OrderDetailView(
//                                                        order: order,
//                                                        orderItem: [item],
//                                                        source: .allOrders,
//                                                        activeTab: .constant(.belumBayar)
//                                                    )
//                                                    .environmentObject(session)
//                                            ) {
//                                                OrderCard(order: order, orderItem: item)
//                                            }
//                                            .buttonStyle(PlainButtonStyle())
//                                        }
//                                    }
//                                }
//                                .padding(.bottom, 12)
//                            }
//                        }
//                    }
                    else {
                        // --- SORT BY NAME (GROUPED BY PRODUCT TYPE) ---

                        let itemsForDate = viewModel.orderItems.filter { item in
                            ordersForSelectedDate.contains { $0.id == item.orderId }
                        }

                        let groupedItems = Dictionary(grouping: itemsForDate) { $0.productName }

                        let sortedTypes = groupedItems.keys.sorted()

                        ForEach(sortedTypes, id: \.self) { type in
                            if let items = groupedItems[type] {

                                // apakah produk ini sedang di-expand?
                                let isExpanded = expandedProducts.contains(type)

                                VStack(alignment: .leading, spacing: 8) {

                                    // HEADER PRODUK (dropdown button)
                                    Button {
                                        if isExpanded {
                                            expandedProducts.remove(type)
                                        } else {
                                            expandedProducts.insert(type)
                                        }
                                    } label: {
                                        HStack(spacing: 12) {
                                            // badge jumlah pesanan
                                            Text("\(items.count)")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.primaryButton)
                                                .frame(width: 28, height: 24)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                        .fill(Color.white)
                                                )

                                            // nama produk
                                            Text(type)
                                                .font(.headline)

                                            Spacer()

                                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .fill(Color("DeadlineCard"))   // warna card kamu
                                        )

                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal)

                                    // ISI CARD HANYA JIKA EXPANDED
                                    if isExpanded {
                                        // urutkan item di dalam produk ini kalau mau
                                        let sortedItems = items.sorted {
                                            $0.productName.localizedCaseInsensitiveCompare($1.productName) == .orderedAscending
                                        }

                                        VStack(spacing: 8) {
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
                                                        OrderCard(order: order, orderItem: [item])
                                                    }
                                                    .buttonStyle(PlainButtonStyle())
                                                }
                                            }
                                        }
                                        .padding(.horizontal)
                                        .padding(.top, 4)
                                    }
                                }
                            }
                        }
                    }

                }
                .padding(.top, 16)
            }
        }
    }
}
