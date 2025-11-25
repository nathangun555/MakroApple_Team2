//
//  NotificationManager.swift
//  MakroApple_Team2
//
//  Created by Edward Suwandi on 19/11/25.
//

import Foundation
import UserNotifications
import Supabase

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

    // MARK: - Save / Read Counts Pesanan Hari Ini & Besok
    func saveOrderCounts(today: Int, tomorrow: Int) {
        UserDefaults.standard.set(today, forKey: Keys.orderToday)
        UserDefaults.standard.set(tomorrow, forKey: Keys.orderTomorrow)
    }
    
    func readTodayCount() -> Int { UserDefaults.standard.integer(forKey: Keys.orderToday) }
    func readTomorrowCount() -> Int { UserDefaults.standard.integer(forKey: Keys.orderTomorrow) }

    // MARK: - Schedule notifications rutin
    func scheduleDailyNotifications() {
        let todayCount = readTodayCount()
        if todayCount > 0 {
            scheduleNotification(
                identifier: "order_today_8am",
                hour: 8, minute: 0,
                title: "Pesanan Hari Ini!",
                bodyGetter: { "Anda memiliki \(todayCount) pesanan dijadwalkan hari ini. Lihat detail pesanan sekarang." }
            )
        } else {
            print("ℹ️ Tidak ada pesanan hari ini, notifikasi dilewati")
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["order_today_8am"])
        }

        let tomorrowCount = readTomorrowCount()
        if tomorrowCount > 0 {
            scheduleNotification(
                identifier: "order_tomorrow_7am",
                hour: 7, minute: 0,
                title: "Pesanan Besok",
                bodyGetter: { "Kamu memiliki \(tomorrowCount) pesanan yang harus dikirim besok. Lihat detailnya di kalender sekarang." }
            )
        } else {
            print("ℹ️ Tidak ada pesanan besok, notifikasi dilewati")
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["order_tomorrow_7am"])
        }
    }


    // MARK: - Fetch jumlah autocancel dari Supabase & schedule jam 6 pagi
    func fetchAutocancelCountAndNotify() async {
        do {
            let client = SupabaseManager.shared.client
            let todayISO = Date().ISO8601Format()

            // Query semua order yang statusnya Dibatalkan dan invoice_due_date lewat
            let response = try await client
                .from("orders")
                .select("id")
                .eq("status", value: "Dibatalkan")
                .lt("invoice_due_date", value: todayISO)
                .execute()

            let count = response.count ?? 0

            print("⚠️ Autocancel count fetched from Supabase: \(count)")

            scheduleAutocancelNotification(count: count)
        } catch {
            print("❌ Failed to fetch autocancel count:", error.localizedDescription)
        }
    }

    // MARK: - Schedule autocancel notification jam 6 pagi
    private func scheduleAutocancelNotification(count: Int) {
        guard count > 0 else {
            print("ℹ️ No autocancel orders to notify")
            return
        }

        scheduleNotification(
            identifier: "autocancel_daily_6am",
            hour: 19, minute: 11,
            title: "Pesanan Otomatis Dibatalkan",
            bodyGetter: { "Ada \(count) pesanan yang otomatis dibatalkan karena lewat tanggal jatuh tempo." }
        )
    }

    // MARK: - Generic schedule helper
    private func scheduleNotification(
        identifier: String,
        hour: Int,
        minute: Int,
        title: String,
        bodyGetter: () -> String
    ) {
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

    // MARK: - Debug: schedule immediate notification
    func scheduleImmediateDebugNotification(title: String, body: String, seconds: TimeInterval = 5) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let req = UNNotificationRequest(identifier: "debug_oneoff_\(UUID().uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }

    // MARK: - Helpers & Keys
    private struct Keys {
        static let orderToday = "order_today"
        static let orderTomorrow = "order_tomorrow"
    }
}
