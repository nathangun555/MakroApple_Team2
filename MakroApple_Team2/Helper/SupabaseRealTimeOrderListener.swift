//
//  RealTimeOrderListener.swift
//  MakroApple_Team2
//

import Supabase
import Foundation

final class RealTimeOrderListener {
    static let shared = RealTimeOrderListener()
    private var channel: RealtimeChannelV2?
    
    private init() {}

    func startListening() async {
        print("🟡 startListening() CALLED")

        let client = SupabaseManager.shared.client
        print("🟡 Supabase Client initialized")

        // Create channel
        channel = client.realtimeV2.channel("orders-listener")
        print("🟡 Channel created: orders-listener")

        // Channel status change logs
        _ = channel?.onStatusChange { status in
            print("🔄 Realtime Status Update =>", status)
        }

        // Listen for postgres changes on orders table
        _ = channel?.onPostgresChange(
            AnyAction.self,
            schema: "public",
            table: "orders",
            filter: nil
        ) { change in
            switch change {
            case .update(let action):
                let oldStatus = action.oldRecord["status"]?.stringValue
                let newStatus = action.record["status"]?.stringValue

                if oldStatus != "Dibatalkan" && newStatus == "Dibatalkan" {
                    print("🚨 Order autocancel detected")

                    // Increment counter di UserDefaults
                    let oldCount = UserDefaults.standard.integer(forKey: Keys.autocancelCount)
                    UserDefaults.standard.set(oldCount + 1, forKey: Keys.autocancelCount)
                    print("📊 Total autocancel count today:", oldCount + 1)
                }
            default:
                break
            }
        }

        // Subscribe
        do {
            print("🟡 Attempting to subscribe...")
            try await channel?.subscribe()
            print("🟢 Listener ACTIVE — Realtime V2 connected SUCCESS")
        } catch {
            print("❌ REALTIME SUBSCRIBE ERROR:", error.localizedDescription)
        }
    }

    private struct Keys {
        static let autocancelCount = "autocancelCount"
    }
}
