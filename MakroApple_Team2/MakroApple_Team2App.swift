//
//  MakroApple_Team2App.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 06/10/25.
//

import SwiftUI

@main
struct MakroApple_Team2App: App {
    @StateObject private var session = SessionManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(session)   // ✅ Inject globally
        }
    }
}


//@main
//struct MakroApple_Team2App: App {
//    var body: some Scene {
//        WindowGroup {
//            SignInWithAppleView(isSignedIn: .constant(false), userId: .constant(nil))
//        }
//    }
//}
