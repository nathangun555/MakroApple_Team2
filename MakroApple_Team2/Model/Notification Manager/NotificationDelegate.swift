//
//  NotificationDelegate.swift
//  MakroApple_Team2
//
//  Created by Edward Suwandi on 19/11/25.
//

// NotificationDelegate.swift
import Foundation
import UserNotifications

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    // tampilkan banner & sound saat app foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler:
                                @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
