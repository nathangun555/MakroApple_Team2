//
//  NotificationManager.swift
//  MakroApple_Team2
//
//  Created by Edward Suwandi on 19/11/25.
//

// NotificationManager.swift
import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}
    
    // MARK: - Permission
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            print(granted ? "✅ Notif permission granted" : "❌ Notif permission denied")
            if let e = error { print("Permission error:", e.localizedDescription) }
        }
    }
    
    // MARK: - Save / Read Counts
    func saveOrderCounts(today: Int, tomorrow: Int) {
        UserDefaults.standard.set(today, forKey: Keys.orderToday)
        UserDefaults.standard.set(tomorrow, forKey: Keys.orderTomorrow)
    }
    
    func readTodayCount() -> Int { UserDefaults.standard.integer(forKey: Keys.orderToday) }
    func readTomorrowCount() -> Int { UserDefaults.standard.integer(forKey: Keys.orderTomorrow) }
    
    // MARK: - Schedule notifications (7:00 & 8:00)
    func scheduleDailyNotifications() { 
        scheduleNotification(
            identifier: "order_tomorrow_7am",
            hour: 18, minute: 5,
            title: "Jangan Lupa Pesanan Besok",
            bodyGetter: { "Kamu memiliki \(self.readTomorrowCount()) pesanan yang harus dikirim besok. Lihat detailnya di kalender sekarang" }
        )
        scheduleNotification(
            identifier: "order_today_8am",
            hour: 8, minute: 0,
            title: "Pesanan Hari Ini!",
            bodyGetter: { "Anda memiliki \(self.readTodayCount()) pesanan dijadwalkan hari ini. Lihat detail pesanan sekarang" }
        )
    }
    
    private func scheduleNotification(
        identifier: String,
        hour: Int,
        minute: Int,
        title: String,
        bodyGetter: () -> String
    ) {
        // Remove existing request to replace content
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = bodyGetter()
        content.sound = .default
        
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let req = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(req) { error in
            if let e = error {
                print("❌ Failed to schedule \(identifier):", e.localizedDescription)
            } else {
                print("📩 Scheduled \(identifier) at \(hour):\(String(format: "%02d", minute))")
            }
        }
    }
    
    // MARK: - Helpers & Keys
    private struct Keys {
        static let orderToday = "order_today"
        static let orderTomorrow = "order_tomorrow"
    }
    
    // For debug: schedule immediate one-off notification (not repeating)
    func scheduleImmediateDebugNotification(title: String, body: String, seconds: TimeInterval = 5) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let req = UNNotificationRequest(identifier: "debug_oneoff_\(UUID().uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }
}
