//
//  MakroWidgetExtensionEntryView.swift
//  MakroApple_Team2
//
//  Created by Edward Suwandi on 20/11/25.
//

import SwiftUI
import WidgetKit

struct MakroWidgetExtensionEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: SimpleEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(orders: entry.orders)

        case .systemMedium:
            MediumWidgetView(orders: entry.orders)

        case .systemLarge:
            LargeWidgetView(orders: entry.orders)

        default:
            MediumWidgetView(orders: entry.orders)
        }
    }
}


struct MakroWidgetExtension: Widget {
    let kind = "MakroWidgetExtension"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: OrderWidgetIntent.self, provider: Provider()) { entry in
            MakroWidgetExtensionEntryView(entry: entry)
        }
        .configurationDisplayName("Makro Order Widget")
        .description("Lihat pesanan berdasarkan status atau tanggal.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
