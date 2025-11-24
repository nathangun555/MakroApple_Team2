import Foundation
import WidgetKit

class WidgetDataManager {
    static let shared = WidgetDataManager()
    
    private let suite = UserDefaults(suiteName: "group.com.please.shared")!
    private let key = "orders_for_widget"
    private let itemsKey = "order_items_for_widget"
    
    
    
    // Simpan OrderRecord langsung
    func saveOrders(_ orders: [OrderRecord]) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(orders) {
            suite.set(data, forKey: key)
            WidgetCenter.shared.reloadAllTimelines() // reload widget otomatis
            print("✅ Orders saved for widget: \(orders.count)")
        } else {
            print("❌ Failed to encode orders for widget")
        }
    }
    
    
    
    // Load OrderRecord langsung
    func loadOrders() -> [OrderRecord] {
        let decoder = JSONDecoder()
        guard let data = suite.data(forKey: key),
              let decoded = try? decoder.decode([OrderRecord].self, from: data) else {
            print("Widget orders kosong")
            return []
        }
        print("Widget orders loaded:", decoded)
        return decoded
    }
    
    func saveOrderItems(_ items: [OrderItemRecord]) {
           let encoder = JSONEncoder()
           if let data = try? encoder.encode(items) {
               suite.set(data, forKey: itemsKey)
               WidgetCenter.shared.reloadAllTimelines()
               print("✅ Order items saved for widget: \(items.count)")
           }
       }
       
       func loadOrderItems() -> [OrderItemRecord] {
           let decoder = JSONDecoder()
           guard let data = suite.data(forKey: itemsKey),
                 let decoded = try? decoder.decode([OrderItemRecord].self, from: data) else {
               print("Widget order items kosong")
               return []
           }
           return decoded
       }
}
