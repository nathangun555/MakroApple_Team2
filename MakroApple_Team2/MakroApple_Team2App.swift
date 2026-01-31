
//
//  MakroApple_Team2App.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 06/10/25.
//

import SwiftUI
import Combine
import UserNotifications

@main
struct MakroApple_Team2App: App {
    @StateObject var session = SessionManager()
    @StateObject var deleteBus = DeleteOverlayBus()
    @StateObject var unsavedBus = UnsavedOverlayBus()

//    @State private var selectedTab: Int = 2
    @State private var selectedTab: Int = {
        let flag = UserDefaults.standard.bool(forKey: "shouldNavigateToActiveOrders")
        print("⚡ Checking shouldNavigateToActiveOrders:", flag)
        if flag {
            print("➡️ Navigating to ActiveOrders")
            UserDefaults.standard.set(false, forKey: "shouldNavigateToActiveOrders")
            return 1
        }
        return 0
    }()
    
    @State private var sharedText: String = ""
    @State private var sharedImages: [UIImage] = []
    @State private var hasNewObject = false
    @State private var isDismissed: Bool = false

    @State private var path: NavigationPath = .init()

//    let notifDelegate = NotificationDelegate()
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    init() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        NotificationManager.shared.requestPermission()
        UINavigationBar.appearance().tintColor = UIColor(Color.primaryButton)
        
        
        delegate.sessionManager = session
        
        
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                // MARK: - Root content (auth-based)
                Group {
                    if !session.isAuthLoaded {
                        // Splash saat cek session Supabase
                        SplashView()
                    } else if session.isSignedIn {
                        MainTabView(
                            selectedTab: $selectedTab,
                            sharedText: $sharedText,
                            hasNewObject: $hasNewObject,
                            sharedImages: $sharedImages
                        )
                    } else {
                        AuthenticationView() 
                    }
                }

                // MARK: - Overlay loading data awal (opsional, pakai flag di SessionManager)
                if session.isInitialDataLoading {
                    Color(.systemBackground)
                        .ignoresSafeArea()

                    VStack(spacing: 16) {
                        if let appIcon = Bundle.main.icon {
                            Image(uiImage: appIcon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 96, height: 96)
                                .cornerRadius(20)
                                .shadow(radius: 10)
                        }
                    }
                }
            }
            .environmentObject(session)
            .environmentObject(deleteBus)
            .environmentObject(unsavedBus)
            .onOpenURL { url in
                guard url.host == "fromwhatsapp" else { return }

                if let defaults = UserDefaults(suiteName: "group.com.please.shared2") {

                    // Ambil shared text
                    if let text = defaults.string(forKey: "sharedText") {
                        sharedText = text
                        hasNewObject = true
                        print("📩 SHARED TEXT: \(text)")
                        defaults.removeObject(forKey: "sharedText")
                    }

                    // Ambil shared images
                    if let imageDataArray = defaults.array(forKey: "sharedImagesData") as? [Data] {
                        sharedImages = imageDataArray.compactMap { UIImage(data: $0) }
                        hasNewObject = true
                        print("🖼️ LOADED \(sharedImages.count) SHARED IMAGES")
                        defaults.removeObject(forKey: "sharedImagesData")
                    }

                    defaults.synchronize()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .navigateToActiveOrders)) { _ in
                print("➡️ Received notification to navigate to ActiveOrdersView")
                            selectedTab = 1
                        }
            .onAppear {
                NotificationManager.shared.scheduleDailyNotifications()
                
            }
            
        }
    }
}
