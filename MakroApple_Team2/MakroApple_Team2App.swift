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

@main
struct MakroApple_Team2App: App {
  @StateObject private var session = SessionManager()

  var body: some Scene {
    WindowGroup {
      NavigationStack {
        ActiveOrdersView()
          .environmentObject(session)   // Inject globally
      }
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
    // Group {
    //     if session.isSignedIn {
    //       NavigationStack { AllOrdersView() }
    //     } else {
    //       NavigationStack { SignInWithAppleView() }
    //     }
    //   }
    //   .environmentObject(session)
    //   .task {
    //     await session.restoreSessionIfAvailable()
    //     session.startAuthListener()
    //   }
  }
}

//@main
//struct MakroApple_Team2App: App {
//  @StateObject private var session = SessionManager()
//
//  var body: some Scene {
//    WindowGroup {
//      NavigationStack {
//        Set_BusinessDetailsView()
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
