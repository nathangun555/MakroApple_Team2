//
//  WidgetViews.swift
//  MakroApple_Team2
//
//  Created by Edward Suwandi on 20/11/25.
//

import SwiftUI
import WidgetKit

let widgetStatusColors: [String: Color] = [
    "Belum Terbayar": .belumBayar,
    "Diproses": .diproses,
    "Terkirim": .terkirim,
    "Selesai": .selesai,
    "Dibatalkan": .dibatalkan
]


struct widgetOrderCard: View {
    let order: WidgetOrder
    
    var body: some View {

        HStack {
            // Indikator
            RoundedRectangle(cornerRadius: 10)
                .frame(width: 6)
                .foregroundColor(widgetStatusColors[order.status])
        }
    }
}

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
        .containerBackground(for: .widget) {
                   Color(.systemBackground) // <-- ini wajib untuk widget iOS 17+
               }
    }
}


//struct MediumWidgetView: View {
//    let orders: [WidgetOrder]
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 10) {
//            ForEach(orders.prefix(3)) { order in
//                HStack {
//                    VStack(alignment: .leading) {
//                        Text(order.customerName ?? order.orderNumber ?? "-")
//                            .font(.subheadline)
//                            .lineLimit(1)
//
//                        if let iso = order.orderDdayISO,
//                           let d = DateFormatterHelper.toDate(iso) {
//                            Text(DateFormatter.localizedString(from: d, dateStyle: .medium, timeStyle: .none))
//                                .font(.caption2)
//                                .foregroundStyle(.secondary)
//                        }
//                    }
//
//                    Spacer()
//
//                    Text(order.status)
//                        .font(.caption2)
//                        .padding(.horizontal, 6)
//                        .padding(.vertical, 2)
//                        .background(widgetStatusColors[order.status])
//                        .clipShape(Capsule())
//                }
//            }
//        }
//        .padding()
//        .containerBackground(for: .widget) {
//                   Color(.systemBackground) // <-- ini wajib untuk widget iOS 17+
//               }
//    }
//}


struct MediumWidgetView: View {

    private var dateComponents: (day: String, monthYear: String) {
        let date = Date()
        let day = Calendar.current.component(.day, from: date).description

        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let monthYear = formatter.string(from: date)

        return (day, monthYear)
    }

    var body: some View {
        HStack(spacing: 15) {

            // LEFT SIDE
            VStack(alignment: .leading, spacing: 10) {

                Text(dateComponents.day)
                    .font(.largeTitle.bold())
                    .foregroundColor(.primaryButton)

                Text(dateComponents.monthYear)
                    .font(.footnote.bold())
                    .foregroundColor(.primary)

                dummyCard(
                    time: "10.00",
                    title: "Le Blume Puddin - Fruit Almond Puddin",
                    color: .purple.opacity(0.7)
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)


            // RIGHT SIDE
            VStack(spacing: 8) {

                dummyCard(
                    time: "12.00",
                    title: "Tiramisu - Add on Baileys",
                    color: .purple.opacity(0.7)
                )

                dummyCard(
                    time: "19.00",
                    title: "Ciffoné - Classic Pandan",
                    color: .blue.opacity(0.6)
                )

                VStack(alignment: .leading) {
                    Text("+ 3 Pesanan")
                        .font(.caption.bold())
                        .foregroundColor(.primaryButton)

                   
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 6)
                .padding(.horizontal, 6)
//                .background(
//                    RoundedRectangle(cornerRadius: 16)
//                        .fill(Color(.systemGray6).opacity(0.5))
//                )
            }
            .frame(maxWidth: .infinity)
        }
//        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}


@ViewBuilder
func dummyCard(time: String, title: String, color: Color) -> some View {
    HStack(spacing: 4) {
        RoundedRectangle(cornerRadius: 3)
            .frame(width: 6)
            .foregroundColor(color)

        VStack(alignment: .leading, spacing: 2) {
            Text(time)
                .font(.caption2)
                .foregroundColor(.secondary)

            Text(title)
                .font(.caption)
                .lineLimit(1)
        }

        Spacer()   // ⬅️ WAJIB UNTUK MEMANJANGKAN CARD
    }
    .padding(.vertical, 4)
    .padding(.horizontal, 4)
    .frame(maxWidth: .infinity) // ⬅️ WAJIB
    .background(
        LinearGradient(colors: [Color.white.opacity(0.15), color.opacity(0.20)],
                       startPoint: .leading,
                       endPoint: .trailing)
    )
    .clipShape(RoundedRectangle(cornerRadius: 10))
}



//struct LargeWidgetView: View {
//    let orders: [WidgetOrder]
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            Text("Daftar Pesanan")
//                .font(.title3.bold())
//
//            ForEach(orders.prefix(6)) { order in
//                HStack {
//                    VStack(alignment: .leading) {
//                        Text(order.customerName ?? order.orderNumber ?? "-")
//                            .font(.body)
//                            .lineLimit(1)
//
//                        if let iso = order.orderDdayISO,
//                           let d = DateFormatterHelper.toDate(iso) {
//                            Text(DateFormatter.localizedString(from: d, dateStyle: .medium, timeStyle: .none))
//                                .font(.caption)
//                                .foregroundColor(.secondary)
//                        }
//                    }
//
//                    Spacer()
//
//                    Text(order.status)
//                        .font(.caption2)
//                        .padding(.horizontal, 6)
//                        .padding(.vertical, 4)
//                        .background(.ultraThinMaterial)
//                        .clipShape(Capsule())
//                }
//            }
//
//            Spacer()
//        }
//        .padding()
//        .containerBackground(for: .widget) {
//                   Color(.systemBackground) // <-- ini wajib untuk widget iOS 17+
//               }
//    }
//}



struct DummyOrder: Identifiable {
    let id = UUID()
    let name: String
    let summary: String
    let time: String
    let color: Color
}


let dummyOrders: [DummyOrder] = [
    DummyOrder(name: "Michiko", summary: "Dearollcake - Choco Cheese", time: "10.30", color: .green),
    DummyOrder(name: "Stacey", summary: "Carrot Keik - Box of 9 Cups", time: "11.00", color: .purple),
    DummyOrder(name: "Nathan", summary: "Tiramisu - Classic Round 16 cm", time: "13.15", color: .blue),
    DummyOrder(name: "Alfred", summary: "IP 13 - Starlight", time: "16.45", color: .gray),
    DummyOrder(name: "Nathan", summary: "IP 13 - Starlight", time: "16.45", color: .gray)
]

struct LargeWidgetView: View {

    private var dateComponents: (day: String, monthYear: String) {
        let date = Date()
        let day = Calendar.current.component(.day, from: date).description

        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let monthYear = formatter.string(from: date)

        return (day, monthYear)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            // HEADER
            HStack(alignment: .bottom) {
                Text(dateComponents.day)
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.primaryButton)

                VStack(alignment: .leading, spacing: 0) {
                    Text(dateComponents.monthYear)
                        .font(.system(size: 18, weight: .medium))
                        .padding(.bottom, 8)
                }

                Spacer()
            }

            // DUMMY CARDS PERSIS SEPERTI SS
            ForEach(dummyOrders.prefix(3)) { item in
                            dummyCard(name: item.name, summary: item.summary, time: item.time, color: item.color)
                        }
            // LAST ITEM
            VStack(alignment: .trailing, spacing: 2) {
                Text("+ 2 Pesanan")
                    .font(.system(size: 15, weight: .semibold))

//                Text("00.00 - 18.00")
//                    .font(.system(size: 13))
//                    .foregroundColor(.secondary)
            }
            .padding(.top, 4)
            .foregroundColor(.primaryButton)
            .padding(.horizontal, 16)

            Spacer()
        }
//        .padding(.horizontal, 16)
        .padding(.top, 10)
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}

// MARK: - COMPONENT EXACT LIKE SCREENSHOT
@ViewBuilder
func dummyCard(name: String, summary: String, time: String, color: Color) -> some View {
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

            Text(summary)
                .font(.system(size: 15, weight: .semibold))
            Text("+2 more")
                .font(Font.caption2.bold())
                .foregroundColor(.secondary)
        }

        Spacer()

       
    }
    .padding(.vertical, 6)
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




// MARK: - CARD COMPONENT
struct OrderSmallCard: View {
    let title: String
    let price: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .frame(width: 4)
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("Ringkasan Pesanan")
                    .font(.system(size: 13, weight: .semibold))
            }
            
            
            Spacer()

            Text(price)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}



// MARK: - Dummy data untuk preview
let sampleOrders: [WidgetOrder] = [
    WidgetOrder(
        id: UUID(),
        orderNumber: "ORD001",
        customerName: "Edward",
        status: "Diproses",
        orderDdayISO: "2025-11-21T00:00:00Z"
    ),
    WidgetOrder(
        id: UUID(),
        orderNumber: "ORD002",
        customerName: "Anna",
        status: "Selesai",
        orderDdayISO: "2025-11-22T00:00:00Z"
    )
]

#Preview(as: .systemLarge) {
    MakroWidgetExtension()
} timeline: {
    SimpleEntry(date: .now, configuration: .preview(), orders: sampleOrders)
}
