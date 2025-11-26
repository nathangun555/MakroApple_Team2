//
//  NotificationDelegate.swift
//  MakroApple_Team2
//
//  Created by Edward Suwandi on 19/11/25.
//

import Foundation
import UserNotifications

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    static let shared = NotificationDelegate()

    // Dipanggil saat notifikasi muncul di foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        print("📩 willPresent called")
        print("📩 userInfo:", userInfo)

        // Tampilkan banner + sound di foreground
        completionHandler([.banner, .sound])
    }

    // Dipanggil saat user tap notifikasi
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        print("📩 didReceive called")
        print("📩 userInfo:", userInfo)

        // Cek apakah notifikasi punya "navigate" untuk ActiveOrdersView
        if let navigate = userInfo["navigate"] as? String,
           navigate == "activeOrders" {
            print("➡️ Posting navigateToActiveOrders notification")

            // Simpan flag jika diperlukan (cold start)
            UserDefaults.standard.set(true, forKey: "shouldNavigateToActiveOrders")

            // Post NotificationCenter event
            NotificationCenter.default.post(name: .navigateToActiveOrders, object: nil)
        }

        completionHandler()
    }
}

extension Notification.Name {
    static let navigateToActiveOrders = Notification.Name("navigate_to_active_orders")
}
