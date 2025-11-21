import WidgetKit
import SwiftUI

// MARK: - Lightweight model for widget
struct WidgetOrder: Identifiable, Codable {
    let id: UUID
    let orderNumber: String?
    let customerName: String?
    let status: String
    let orderDdayISO: String?
}

// MARK: - Timeline Entry
struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: OrderWidgetIntent
    let orders: [WidgetOrder]
}

// MARK: - Provider
struct Provider: AppIntentTimelineProvider {

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: OrderWidgetIntent(), orders: [])
    }

    func snapshot(for configuration: OrderWidgetIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration, orders: Self.sample)
    }

    func timeline(for configuration: OrderWidgetIntent, in context: Context) async -> Timeline<SimpleEntry> {

        // Load saved orders (AppGroup)
        let orders = WidgetDataManager.shared.loadOrders()

        // Filter by intent
        let filtered: [WidgetOrder] = {
            switch configuration.mode {
            case .status:
                let target = (configuration.status ?? .Diproses).rawValue.lowercased()
                return orders.filter { $0.status.lowercased() == target }


            case .calendar:
                guard let selected = configuration.selectedDate else { return [] }

                return orders.filter { order in
                    guard let iso = order.orderDdayISO,
                          let d = DateFormatterHelper.toDate(iso)
                    else { return false }

                    return Calendar.current.isDate(d, inSameDayAs: selected)
                }


            default:
                return orders
            }
        }()

        let entry = SimpleEntry(
            date: Date(),
            configuration: configuration,
            orders: Array(filtered.prefix(20))
        )

        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!

        return Timeline(entries: [entry], policy: .after(nextRefresh))
    }

    // Sample for Preview
    static var sample: [WidgetOrder] = [
        WidgetOrder(id: UUID(), orderNumber: "INV/001", customerName: "Budi", status: "Diproses", orderDdayISO: ISO8601DateFormatter().string(from: Date())),
        WidgetOrder(id: UUID(), orderNumber: "INV/002", customerName: "Siti", status: "Terkirim", orderDdayISO: ISO8601DateFormatter().string(from: Date()))
    ]
}


// MARK: - Widget
struct OrderWidget: Widget {
    let kind = "OrderWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind,
                               intent: OrderWidgetIntent.self,
                               provider: Provider()) { entry in
            MakroWidgetExtensionEntryView(entry: entry)
        }
        .configurationDisplayName("Order Status Widget")
        .description("Shows filtered orders.")
    }
}


// MARK: - Preview Intent Helper
extension OrderWidgetIntent {
    static func preview(mode: OrderWidgetMode = .status, status: OrderStatusOption = .Diproses, date: Date = .now) -> OrderWidgetIntent {
        var i = OrderWidgetIntent()
        i.mode = mode
        i.status = status
        i.selectedDate = date
        return i
    }
}





// MARK: - Preview
#Preview(as: .systemLarge) {
    OrderWidget()
} timeline: {
    SimpleEntry(
        date: .now,
        configuration: .preview(mode: .status, status: .Diproses),
        orders: Provider.sample
    )
}
