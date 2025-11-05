//
//  MakroApple_Team2App.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 06/10/25.
//

//import SwiftUI
//
//@main
//struct MakroApple_Team2App: App {
//    @StateObject private var session = SessionManager()
//
//    var body: some Scene {
//        WindowGroup {
//            AllOrdersView()
//                .environmentObject(session)   // ✅ Inject globally
//        }
//    }
//}

import SwiftUI

//@main
//struct MakroApple_Team2App: App {
//  @StateObject private var session = SessionManager()
//
//  var body: some Scene {
//    WindowGroup {
//      NavigationStack {
//        AllOrdersView()
//          .environmentObject(session)   // Inject globally
//      }
//      .task {
//        #if DEV_STUB_SESSION
//        // Dev stub session: skip real auth and force a specific user
//        session.isSignedIn = true
//        session.userId = "083dc90d-ca03-4f45-a631-06fe21fe750f"
//        #else
//        // In non-dev builds, keep your normal flow (e.g., ContentView auto-checks session)
//        // If using ContentView in production, switch root to ContentView() here.
//        #endif
//      }
//    }
//    // Group {
//    //     if session.isSignedIn {
//    //       NavigationStack { AllOrdersView() }
//    //     } else {
//    //       NavigationStack { SignInWithAppleView() }
//    //     }
//    //   }
//    //   .environmentObject(session)
//    //   .task {
//    //     await session.restoreSessionIfAvailable()
//    //     session.startAuthListener()
//    //   }
//  }
//}

@main
//struct MakroApple_Team2App: App {
//    @StateObject var session = SessionManager()
//
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//                .environmentObject(session)
//                .task {
//                    // ✅ Manual injection (for testing)
//                    session.isSignedIn = true
//                    session.userId = "083dc90d-ca03-4f45-a631-06fe21fe750f"
//
//                    print("🪪 Injected user ID manually:", session.userId ?? "nil")
//                }
//        }
//    }
//}

//@main
struct MakroApple_Team2App: App {
    @StateObject var session = SessionManager()
        @State private var selectedTab: Int = 1   // 👈 Add this


  var body: some Scene {
    WindowGroup {
      NavigationStack {
          ConfirmInvoiceView(orderId: "57B1A943-1902-4977-8E49-FA0AB3DB57CE")
      }
      .environmentObject(session)   // Inject globally
      .task {
        #if DEV_STUB_SESSION
        // Dev stub session: skip real auth and force a specific user
        session.isSignedIn = true
        session.userId = "083dc90d-ca03-4f45-a631-06fe21fe750f"
        #else
        // In non-dev builds, keep your normal flow (e.g., ContentView auto-checks session)
        // If using ContentView in production, switch root to ContentView() here.
        #endif
      }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if url.scheme == "macroa2" && url.host == "share" {
            let sharedDefaults = UserDefaults(suiteName: "group.com.macroa2.identifier")
            let sharedText = sharedDefaults?.string(forKey: "sharedText")
            let sharedImage = sharedDefaults?.string(forKey: "sharedImage")
            
            print("📩 Received shared text:", sharedText ?? "None")
            print("🖼️ Received shared image:", sharedImage ?? "None")

            // ✅ Optionally clear after use
            sharedDefaults?.removeObject(forKey: "sharedText")
            sharedDefaults?.removeObject(forKey: "sharedImage")
            return true
        }
        return false
    }
}
//@main
//struct MakroApple_Team2App: App {
//  @StateObject private var session = SessionManager()
//
//  var body: some Scene {
//    WindowGroup {
//      NavigationStack {
//        NewTemplateFormView()
//          .environmentObject(session)   // Inject globally
//      }
//      .task {
//        #if DEV_STUB_SESSION
//        // Dev stub session: skip real auth and force a specific user
//        session.isSignedIn = true
//        session.userId = "083dc90d-ca03-4f45-a631-06fe21fe750f"
//        #else
//        // In non-dev builds, keep your normal flow (e.g., ContentView auto-checks session)
//        // If using ContentView in production, switch root to ContentView() here.
//        #endif
//      }
//    }
//    // Group {
//    //     if session.isSignedIn {
//    //       NavigationStack { AllOrdersView() }
//    //     } else {
//    //       NavigationStack { SignInWithAppleView() }
//    //     }
//    //   }
//    //   .environmentObject(session)
//    //   .task {
//    //     await session.restoreSessionIfAvailable()
//    //     session.startAuthListener()
//    //   }
//  }
//}

//@main
//struct MakroApple_Team2App: App {
//    var body: some Scene {
//        WindowGroup {
//            SignInWithAppleView(isSignedIn: .constant(false), userId: .constant(nil))
//        }
//    }
//}
