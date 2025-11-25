import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications
import Supabase
import PostgREST
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    var sessionManager: SessionManager? // inject dari Scene / Environment

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        FirebaseApp.configure()
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            print("✅ Notif permission granted: \(granted)")
        }

        UIApplication.shared.registerForRemoteNotifications()
        return true
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        print("🔥 FCM Token: \(token)")

        saveFcmTokenWhenUserAvailable(token: token)
    }

    private func saveFcmTokenWhenUserAvailable(token: String) {
        Task {
            // tunggu session load
            while sessionManager?.isAuthLoaded != true {
                try await Task.sleep(nanoseconds: 200_000_000)
            }

            guard let userIdString = sessionManager?.userId?.lowercased(),
                  let userId = UUID(uuidString: userIdString) else {
                print("❌ SessionManager userId invalid")
                return
            }


            do {
                // 1️⃣ Upsert user ke tabel `users` (tanpa FK dev mode)
                let userBody: [String: AnyCodable] = [
                    "id":  AnyCodable(userId.uuidString.lowercased()),
                    "email": AnyCodable("example@example.com") // bisa diganti dari Auth
                ]

                let _: PostgrestResponse<Void> = try await SupabaseManager.shared.client
                    .from("users")
                    .upsert(userBody, onConflict: "id")
                    .execute()

                // 2️⃣ Upsert token ke device_tokens
                let tokenBody: [String: AnyCodable] = [
                    "token": AnyCodable(token),
                    "user_id": AnyCodable(userId.uuidString.lowercased())
                ]

                let _: PostgrestResponse<Void> = try await SupabaseManager.shared.client
                    .from("device_tokens")
                    .upsert(tokenBody, onConflict: "token")
                    .execute()

                print("📤 FCM token berhasil dikirim ke Supabase untuk user \(userId)")
            } catch {
                print("user id sekarang: \(userId)")
                print("❌ Gagal kirim token: \(error)")
            }
        }
    }
}
