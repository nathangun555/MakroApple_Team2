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
    @State private var sharedImages: [UIImage] = []
    @State private var hasNewObject = false
    
    var body: some Scene {
        WindowGroup {
            NavigationStack{
                InputMenuView()
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
            
//            MainTabView(selectedTab: $selectedTab, sharedText: $sharedText,hasNewObject: $hasNewObject, sharedImages : $sharedImages)
//                .environmentObject(session)
//                .onAppear {
//                    
//                    if let defaults = UserDefaults(suiteName: "group.com.please.shared") {
//                        
//                        // Load text from another app
//                        if let text = defaults.string(forKey: "sharedText") {
//                            sharedText = text
//                            hasNewObject = true
//                            defaults.removeObject(forKey: "sharedText")
//                            print("REMOVED OBJECT \(text)")
//                        }
//                        
//                        // Load image from another app
//                        if let image = defaults.array(forKey: "sharedImagesData") as? [Data] {
//                            sharedImages = image.compactMap { UIImage(data: $0) }
//                            hasNewObject = true
//                            defaults.removeObject(forKey: "sharedImagesData")
//                            print("LOADED \(sharedImages.count) shared images")
//                            
//                            
//                        }
//                        defaults.synchronize()
//                    }
//                }
//                .onOpenURL { url in
//                    if url.host == "fromwhatsapp" {
//                        if let defaults = UserDefaults(suiteName: "group.com.please.shared") {
//                            
//                            if let text = defaults.string(forKey: "sharedText") {
//                                sharedText = text
//                                hasNewObject = true
//                                print("SHARED TEXT : \(text)")
//                            }
//                            
//                            if let image = defaults.array(forKey: "sharedImagesData") as? [Data] {
//                                sharedImages = image.compactMap { UIImage(data: $0) }
//                                hasNewObject = true
//                                print("LOADED \(sharedImages.count) shared images")
//                            }
//                            defaults.synchronize()
//                        }
//                    }
//                }
            
        }
        
    }
}
