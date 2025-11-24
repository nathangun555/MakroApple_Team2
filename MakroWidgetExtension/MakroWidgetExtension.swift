import SwiftUI
import WidgetKit

// MARK: - Timeline Entry
struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: OrderWidgetIntent
    let orders: [OrderRecord] // langsung OrderRecord
    let orderItems: [OrderItemRecord]
}

// MARK: - Provider
struct Provider: AppIntentTimelineProvider {

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            configuration: OrderWidgetIntent(),
            orders: [],
            orderItems: []
        )
    }

    func snapshot(for configuration: OrderWidgetIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            configuration: configuration,
            orders: WidgetDataManager.shared.loadOrders(),
            orderItems: WidgetDataManager.shared.loadOrderItems()
        )
    }

    func timeline(for configuration: OrderWidgetIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let allOrders = WidgetDataManager.shared.loadOrders()
        let allItems = WidgetDataManager.shared.loadOrderItems()

        let filteredOrders = filterOrders(allOrders, by: configuration)
        
        let entry = SimpleEntry(
            date: Date(),
            configuration: configuration,
            orders: Array(filteredOrders.prefix(20)),
            orderItems: allItems // ambil semua order items
        )
        
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        return Timeline(entries: [entry], policy: .after(nextRefresh))
    }

    private func filterOrders(_ orders: [OrderRecord], by configuration: OrderWidgetIntent) -> [OrderRecord] {
        switch configuration.mode {
        case .status:
            let target = (configuration.status?.rawValue ?? "Diproses").lowercased()
            return orders.filter { $0.status.lowercased() == target }
        case .calendar:
            guard let selected = configuration.selectedDate else { return [] }
            return orders.filter { order in
                guard let iso = order.orderDdayDate,
                      let d = DateFormatterHelper.toDate(iso) else { return false }
                return Calendar.current.isDate(d, inSameDayAs: selected)
            }
        default:
            return orders
        }
    }
}

