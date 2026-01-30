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
        
        switch entry.mode {
            
        case .customer:
            switch family {
            case .systemSmall:
                EmptyView()
            case .systemMedium:
                CustomerMediumWidgetView(orders: entry.orders, orderItems: entry.orderItems)
            case .systemLarge:
                CustomerLargeWidgetView(orders: entry.orders, orderItems: entry.orderItems)
            default:
                CustomerMediumWidgetView(orders: entry.orders, orderItems: entry.orderItems)
            }
            
        case .order:
            switch family {
                case .systemSmall:
                EmptyView()
            case .systemMedium:
                EmptyView()
            case .systemLarge:
                OrderLargeWidgetView(orders: entry.orders, orderItems: entry.orderItems)
            default:
                EmptyView()
            }
        }
        
        
//        switch family {
//        case .systemSmall:
//            MediumWidgetView(orders: entry.orders, orderItems: entry.orderItems)
//
//        case .systemMedium:
//            MediumWidgetView(orders: entry.orders, orderItems: entry.orderItems)
//
//
//        case .systemLarge:
//            LargeWidgetView(orders: entry.orders, orderItems: entry.orderItems)
//
//
//        default:
//            MediumWidgetView(orders: entry.orders, orderItems: entry.orderItems)
//
//        }
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
