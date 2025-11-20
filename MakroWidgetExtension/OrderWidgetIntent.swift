//
//  OrderWidgetIntent.swift
//  MakroApple_Team2
//
//  Created by Edward Suwandi on 20/11/25.
//


import AppIntents

enum OrderWidgetMode: String, AppEnum {
    case status
    case calendar

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Order View Mode"
    }

    static var caseDisplayRepresentations: [OrderWidgetMode: DisplayRepresentation] {
        [
            .status: "By Status",
            .calendar: "By Calendar Date"
        ]
    }
}

enum OrderStatusOption: String, AppEnum {
    case BelumTerbayar = "Belum Terbayar"
    case Diproses = "Diproses"
    case Terkirim = "Terkirim"
    case Selesai = "Selesai"
    case Dibatalkan = "Dibatalkan"

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Order Status"
    }

    static var caseDisplayRepresentations: [OrderStatusOption: DisplayRepresentation] {
        [
            .BelumTerbayar: "Belum Terbayar",
            .Diproses: "Diproses",
            .Terkirim: "Terkirim",
            .Selesai: "Selesai",
            .Dibatalkan: "Dibatalkan"
        ]
    }
}

struct OrderWidgetIntent: WidgetConfigurationIntent {

    static var title: LocalizedStringResource = "Order Widget"
    static var description = IntentDescription("See order information in widget.")

    @Parameter(
        title: "Mode",
        default: .status
    )
    var mode: OrderWidgetMode

    @Parameter(
        title: "Status (used if mode = status)",
        default: .Diproses
    )
    var status: OrderStatusOption

    @Parameter(
        title: "Select Date (used if mode = calendar)",
        default: Date()
    )
    var selectedDate: Date
}
