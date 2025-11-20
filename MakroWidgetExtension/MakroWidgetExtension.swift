import WidgetKit
import SwiftUI

// MARK: - Lightweight model for widget (keamanan & ukuran)
struct WidgetOrder: Identifiable, Codable {
    let id: UUID
    let orderNumber: String?
    let customerName: String?
    let status: String
    let orderDdayISO: String? // keep original ISO string
}

// MARK: - Timeline Entry
struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: OrderWidgetIntent
    let orders: [WidgetOrder]
}

// MARK: - Provider
struct Provider: AppIntentTimelineProvider {
    // placeholder with empty data
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: OrderWidgetIntent(), orders: [])
    }

    // snapshot for preview
    func snapshot(for configuration: OrderWidgetIntent, in context: Context) async -> SimpleEntry {
        // Provide sample orders for snapshot
        let sample = [
            WidgetOrder(id: UUID(), orderNumber: "INV/20231101/0001", customerName: "Budi", status: "Diproses", orderDdayISO: ISO8601DateFormatter().string(from: Date())),
            WidgetOrder(id: UUID(), orderNumber: "INV/20231101/0002", customerName: "Siti", status: "Terkirim", orderDdayISO: ISO8601DateFormatter().string(from: Date().addingTimeInterval(86400)))
        ]
        return SimpleEntry(date: Date(), configuration: configuration, orders: sample)
    }

    // timeline — utama
    func timeline(for configuration: OrderWidgetIntent, in context: Context) async -> Timeline<SimpleEntry> {
        // Load user id from App Group (required to call Supabase)
        let userIdString = UserDefaults(suiteName: "group.com.please.shared")?.string(forKey: "widget_user_id")
        var fetchedOrders: [WidgetOrder] = []

        if let userIdString,
           let userUUID = UUID(uuidString: userIdString) {
            // Try fetch from Supabase (use your existing SupabaseManager)
            do {
                let orders = try await SupabaseManager.shared.fetchAllOrders(for: userUUID)
                
                // Filter according to configuration
                switch configuration.mode {
                case .status:
                    // match status exactly as chosen (user-facing enum values)
                    let desired = configuration.status.rawValue
                    let filtered = orders.filter { $0.status.localizedCaseInsensitiveCompare(desired) == .orderedSame }
                    fetchedOrders = filtered.map { toWidgetOrder(from: $0) }
                    
                case .calendar:
                    // selected date — include orders on that day, exclude "Belum Terbayar" & "Dibatalkan"
                    let selected = configuration.selectedDate
                    let filtered = orders.filter { order in
                        // parse orderDdayDate via DateFormatterHelper (existing in app)
                        guard let iso = order.orderDdayDate,
                              let date = DateFormatterHelper.toDate(iso) else { return false }
                        let sameDay = Calendar.current.isDate(date, inSameDayAs: selected)
                        let statusLower = order.status.lowercased()
                        let excluded = statusLower == "belum terbayar" || statusLower == "dibatalkan"
                        return sameDay && !excluded
                    }
                    fetchedOrders = filtered.map { toWidgetOrder(from: $0) }
                @unknown default:
                    fetchedOrders = orders.map { toWidgetOrder(from: $0) }
                }
            } catch {
                // on error, fallback to empty list
                print("Widget Supabase fetch error:", error)
                fetchedOrders = []
            }
        } else {
            // No user id saved for widget — return empty
            fetchedOrders = []
        }

        // Keep only top 10 in timeline data; widget view will show up to 3
        let entry = SimpleEntry(date: Date(), configuration: configuration, orders: Array(fetchedOrders.prefix(20)))

        // Refresh policy: update after 30 minutes
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        return Timeline(entries: [entry], policy: .after(refreshDate))
    }

    // Helper: convert OrderRecord -> WidgetOrder
    private func toWidgetOrder(from order: OrderRecord) -> WidgetOrder {
        WidgetOrder(
            id: order.id,
            orderNumber: order.orderNumber,
            customerName: order.customerOrderName,
            status: order.status,
            orderDdayISO: order.orderDdayDate
        )
    }
}

// MARK: - Widget View
struct MakroWidgetExtensionEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            // background
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .containerBackground(.fill.tertiary, for: .widget)

            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack {
                    Text(headerTitle())
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    Text("\(entry.orders.count)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Divider()

                if entry.orders.isEmpty {
                    Text("Tidak ada pesanan")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    // show up to 3 orders
                    ForEach(entry.orders.prefix(3)) { order in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(order.customerName ?? order.orderNumber ?? "—")
                                        .font(.subheadline)
                                        .lineLimit(1)
                                    Spacer()
                                    Text(order.status)
                                        .font(.caption2)
                                        .padding(6)
                                        .background(statusColor(order.status).opacity(0.15))
                                        .cornerRadius(6)
                                }
                                if let iso = order.orderDdayISO,
                                   let d = DateFormatterHelper.toDate(iso) {
                                    Text(DateFormatter.localizedString(from: d, dateStyle: .medium, timeStyle: .none))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                Spacer()
            }
            .padding()
        }
    }

    // header text depends on mode
    func headerTitle() -> String {
        switch entry.configuration.mode {
        case .status:
            return "Status: \(entry.configuration.status.rawValue)"
        case .calendar:
            let date = entry.configuration.selectedDate
            return "Tanggal: " + DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
        @unknown default:
            return "Pesanan"
        }
    }

    func statusColor(_ status: String) -> Color {
        let lower = status.lowercased()
        if lower.contains("diproses") { return Color.yellow }
        if lower.contains("terkirim") { return Color.blue }
        if lower.contains("selesai") { return Color.green }
        if lower.contains("dibatalkan") { return Color.red }
        return Color.gray
    }
}

// MARK: - Widget Definition
struct MakroWidgetExtension: Widget {
    let kind: String = "MakroWidgetExtension"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: OrderWidgetIntent.self, provider: Provider()) { entry in
            MakroWidgetExtensionEntryView(entry: entry)
        }
        .configurationDisplayName("Makro Orders")
        .description("Lihat pesanan berdasarkan status atau tanggal.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    MakroWidgetExtension()
} timeline: {
    SimpleEntry(date: Date(), configuration: OrderWidgetIntent(), orders: [])
}
//#Preview(as: .systemMedium) {
//    
//}
