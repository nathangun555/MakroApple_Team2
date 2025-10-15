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
        return df.string(from: order.date)
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
                Text(order.customerName)
            }

            Section(header: Text("Date")) {
                Text(formattedDate)
            }

            Section(header: Text("Items")) {
                ForEach(order.items, id: \.self) { item in
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
            customerName: "Jane Stacey",
            date: Date(),
            items: ["Strawberry Cheesecake XL"],
            total: 125000
        ))
    }
}
