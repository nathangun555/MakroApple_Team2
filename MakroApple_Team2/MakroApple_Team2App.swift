//
//  MakroApple_Team2App.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 06/10/25.
//

import SwiftUI

@main
struct MakroApple_Team2App: App {
    @StateObject var session = SessionManager()
    @State private var selectedTab: Int = 1
    @State private var sharedText: String = ""
    @State private var hasNewSharedText = false
    
    var body: some Scene {
        WindowGroup {
            MainTabView(selectedTab: $selectedTab, sharedText: $sharedText, hasNewSharedText: $hasNewSharedText)
                .environmentObject(session)
                .onAppear {
                    // ✅ Load any shared text from App Group
                    if let defaults = UserDefaults(suiteName: "group.com.please.shared"),
                       let text = defaults.string(forKey: "sharedText") {
                        sharedText = text
                        hasNewSharedText = true
                        defaults.removeObject(forKey: "sharedText")
                        print("REMOVED OBJECT \(text)")
                    }
                }
                .onOpenURL { url in
                    if url.host == "fromwhatsapp" {
                        print("OPENED FROM WA")
                        if let defaults = UserDefaults(suiteName: "group.com.please.shared"),
                           let text = defaults.string(forKey: "sharedText") {
                            print("FOUND TEXT \(text)")
                            sharedText = text
                            hasNewSharedText = true
                            print("SHARED TEXT = \(sharedText)")
                        }
                    }
                }
            
        }
        
    }
}
