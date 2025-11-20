//
//  SmallWidgetView.swift
//  MakroApple_Team2
//
//  Created by Edward Suwandi on 20/11/25.
//

import SwiftUI

struct SmallWidgetView: View {
    let orders: [WidgetOrder]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Pesanan")
                .font(.headline)

            if let first = orders.first {
                Text(first.customerName ?? first.orderNumber ?? "-")
                    .font(.subheadline)
                    .lineLimit(1)
                
                Text(first.status)
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Tidak ada pesanan")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}


struct MediumWidgetView: View {
    let orders: [WidgetOrder]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(orders.prefix(3)) { order in
                HStack {
                    VStack(alignment: .leading) {
                        Text(order.customerName ?? order.orderNumber ?? "-")
                            .font(.subheadline)
                            .lineLimit(1)

                        if let iso = order.orderDdayISO,
                           let d = DateFormatterHelper.toDate(iso) {
                            Text(DateFormatter.localizedString(from: d, dateStyle: .medium, timeStyle: .none))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Text(order.status)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
    }
}

struct LargeWidgetView: View {
    let orders: [WidgetOrder]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daftar Pesanan")
                .font(.title3.bold())

            ForEach(orders.prefix(6)) { order in
                HStack {
                    VStack(alignment: .leading) {
                        Text(order.customerName ?? order.orderNumber ?? "-")
                            .font(.body)
                            .lineLimit(1)

                        if let iso = order.orderDdayISO,
                           let d = DateFormatterHelper.toDate(iso) {
                            Text(DateFormatter.localizedString(from: d, dateStyle: .medium, timeStyle: .none))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Text(order.status)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
            }

            Spacer()
        }
        .padding()
    }
}

