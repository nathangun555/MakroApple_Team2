import SwiftUI
import WidgetKit


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

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: OrderWidgetIntent
    let orders: [OrderRecord]
    let orderItems: [OrderItemRecord]
    let mode: OrderWidgetMode
}

struct Provider: AppIntentTimelineProvider {

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            configuration: OrderWidgetIntent(),
            orders: [],
            orderItems: [],
            mode: .customer
        )
    }

    func snapshot(for configuration: OrderWidgetIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            configuration: configuration,
            orders: WidgetDataManager.shared.loadOrders(),
            orderItems: WidgetDataManager.shared.loadOrderItems(),
            mode: configuration.mode ?? .customer
        )
    }

    func timeline(for configuration: OrderWidgetIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let allOrders = WidgetDataManager.shared.loadOrders()
        let allItems = WidgetDataManager.shared.loadOrderItems()

        let mode = configuration.mode ?? .customer

        let filteredOrders = filterOrders(allOrders, mode: mode)

        let orderIds = Set(filteredOrders.map { $0.id })
        let filteredItems = allItems.filter {
            orderIds.contains($0.orderId)
        }

        let entry = SimpleEntry(
            date: Date(),
            configuration: configuration,
            orders: Array(filteredOrders.prefix(20)),
            orderItems: filteredItems,
            mode: mode
        )

        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        return Timeline(entries: [entry], policy: .after(nextRefresh))
    }

    
    
    private func filterOrders(
        _ orders: [OrderRecord],
        mode: OrderWidgetMode
    ) -> [OrderRecord] {

        let today = Date()

        return orders.filter { order in
            // FILTER STATUS
            let status = order.status.lowercased()
            if status == "belum terbayar" || status == "dibatalkan" {
                return false
            }

            // FILTER TANGGAL (HARI INI)
            guard let iso = order.orderDdayDate,
                  let d = DateFormatterHelper.toDate(iso) else {
                return false
            }

            return Calendar.current.isDate(d, inSameDayAs: today)
        }
    }


}

