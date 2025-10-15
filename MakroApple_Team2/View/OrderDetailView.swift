//
//  OrderDetailView.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 14/10/25.
//

import SwiftUI

struct OrderDetailView: View {
    let order: Order

    private var formattedDate: String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df.string(from: order.orderDate)
    }

    private func currency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "IDR"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "Rp \(value)"
    }

    var body: some View {
        List {
            Section(header: Text("Customer")) {
                Text(order.customer_order_name)
            }

            Section(header: Text("Date")) {
                Text(formattedDate)
            }

            Section(header: Text("Items")) {
                ForEach(order.productName, id: \.self) { item in
                    Text(item)
                }
            }

            Section(header: Text("Total")) {
                Text(currency(order.total))
                    .font(.headline)
            }
        }
        .navigationTitle("Order Detail")
    }
}

#Preview {
    NavigationStack {
        OrderDetailView(order: Order(
            customer_order_name: "Jane Stacey",
            customer_order_phone: "08123456789",
            productName: ["Strawberry Cheesecake XL"],
            orderDate: Date(),
            orderStatus: "Active",
            total: 125000
        ))
    }
}
