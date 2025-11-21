import AppIntents

// MARK: - Widget Mode Enum
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

// MARK: - Status Enum
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

// MARK: - Main Intent for Widget
struct OrderWidgetIntent: WidgetConfigurationIntent {

    @Parameter(title: "Mode")
    var mode: OrderWidgetMode?   // MUST BE OPTIONAL

    @Parameter(title: "Order Status")
    var status: OrderStatusOption?   // MUST BE OPTIONAL

    @Parameter(title: "Select Date")
    var selectedDate: Date?     // MUST BE OPTIONAL

    static var title: LocalizedStringResource = "Order Widget Settings"
    static var description = IntentDescription(
        "Configure how the order widget displays orders."
    )
}
