import AppIntents


// Mode Widget
enum OrderWidgetMode: String, AppEnum {
    case customer
    case order

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Order View Mode"
    }

    static var caseDisplayRepresentations: [OrderWidgetMode: DisplayRepresentation] {
        [
            .customer: "By Customer",
            .order: "By Order"
        ]
    }
}

// MARK: - Main Intent for Widget
struct OrderWidgetIntent: WidgetConfigurationIntent {
    

    @Parameter(title: "Mode")
    var mode: OrderWidgetMode?

    static var title: LocalizedStringResource = "Order Widget Settings"
    static var description = IntentDescription(
        "Configure how the order widget displays orders."
    )
}
