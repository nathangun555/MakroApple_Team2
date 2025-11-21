//
//  WidgetDataManager.swift
//  MakroApple_Team2
//
//  Created by Edward Suwandi on 20/11/25.
//

import Foundation

class WidgetDataManager {
    static let shared = WidgetDataManager()
    
    private let suite = UserDefaults(suiteName: "group.com.please.shared")!
    private let key = "widget_orders"
    
    func saveOrders(_ orders: [WidgetOrder]) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(orders) {
            suite.set(data, forKey: key)
        }
    }
    
    func loadOrdersForWidget() -> [WidgetOrder] {
        let defaults = UserDefaults(suiteName: "group.com.please.shared")!
        guard let data = defaults.data(forKey: "orders_for_widget"),
              let orderRecords = try? JSONDecoder().decode([OrderRecord].self, from: data)
        else { return [] }

        return orderRecords.map { order in
            WidgetOrder(
                id: order.id,
                orderNumber: order.orderNumber,
                customerName: order.customerOrderName,
                status: order.status,
                orderDdayISO: order.orderDdayDate
            )
        }
    }

    
    func loadOrders() -> [WidgetOrder] {
        let decoder = JSONDecoder()
        guard let data = suite.data(forKey: key),
              let decoded = try? decoder.decode([WidgetOrder].self, from: data)
        else {
            print("Widget orders kosong")
            return []
        }
        
        print("Widget orders loaded:", decoded)
        return decoded
    }

}
