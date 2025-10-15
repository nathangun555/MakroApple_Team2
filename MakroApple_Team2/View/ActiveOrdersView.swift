//
//  ActiveOrdersView.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 10/10/25.
//

import SwiftUI

struct ActiveOrdersView: View {
    @State private var selectedDate: Date = Date()
    @State private var currentMonth: Date = Date()
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
    
    // Dummy order data
    private let sampleOrders: [Order] = [
        Order(
            customer_order_name: "Jane Stacey",
            customer_order_phone: "08123456789",
            productName: ["Strawberry Cheesecake XL"],
            orderDate: Date(),
            orderStatus: "Active",
            total: 125000
        ),
        Order(
            customer_order_name: "John Gunawan",
            customer_order_phone: "08987654321",
            productName: ["Burnt Cheesecake S"],
            orderDate: Date(),
            orderStatus: "Active",
            total: 75000
        )
    ]
    
    
    var body: some View {
        NavigationStack{
            VStack(spacing: 0) {
                HStack {
                    Button {
                        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth)!
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                    }
                    Spacer()
                    Text(formattedMonthYear(for: currentMonth))
                        .font(.headline)
                    Spacer()
                    Button {
                        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth)!
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.title3)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)

                HStack {
                    ForEach(daysOfWeek, id: \.self) { day in
                        Text(day)
                            .font(.caption2)
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                let days = generateDays(for: currentMonth)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                    ForEach(days, id: \.self) { day in
                        let isCurrentMonth = calendar.isDate(day, equalTo: currentMonth, toGranularity: .month)
                        
                        Button {
                            selectedDate = day
                        } label: {
                            Text("\(calendar.component(.day, from: day))")
                                .frame(width: 36, height: 36)
                                .background(
                                    calendar.isDate(day, inSameDayAs: selectedDate)
                                    ? Color.blue.opacity(0.9)
                                    : .clear
                                )
                                .clipShape(RoundedRectangle(cornerRadius:10))
                                .foregroundColor(
                                    calendar.isDate(day, inSameDayAs: selectedDate)
                                    ? .white
                                    : (isCurrentMonth ? .primary : .gray.opacity(0.4))
                                )
                        }
                    }
                }
                .padding(.horizontal)
                .frame(maxHeight: 320)
                
                Divider()
                    .padding(.bottom, 16)
                
                ScrollView {
                    let ordersForSelectedDate = sampleOrders.filter { calendar.isDate($0.orderDate, inSameDayAs: selectedDate) }

                    if ordersForSelectedDate.isEmpty {
                        Text("Nothing on your agenda")
                            .foregroundStyle(.secondary)
                            .padding(.top, 24)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(ordersForSelectedDate.indices, id: \.self) { index in
                                let order = ordersForSelectedDate[index]
                                NavigationLink {
                                    OrderDetailView(order: order)
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(order.customer_order_name)
                                            .fontWeight(.semibold)
                                        Text("Pesanan: \(order.productName.joined(separator: ", "))")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Text("Total: Rp \(String(order.total))")
                                            .font(.footnote)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(.secondary.opacity(0.07))
                                    .cornerRadius(10)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .animation(.easeInOut, value: currentMonth)
        }
    }
    
    func formattedMonthYear(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date).uppercased()
    }
    
    func generateDays(for month: Date) -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month),
              let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start)
        else { return [] }
        
        var days: [Date] = []
        (0..<42).forEach { i in
            if let day = calendar.date(byAdding: .day, value: i, to: firstWeek.start) {
                days.append(day)
            }
        }
        return days
    }
}

#Preview {
    ActiveOrdersView()
}
