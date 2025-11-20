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
    
    func loadOrders() -> [WidgetOrder] {
        let decoder = JSONDecoder()
        guard let data = suite.data(forKey: key),
              let decoded = try? decoder.decode([WidgetOrder].self, from: data)
        else { return [] }
        return decoded
    }
}
