//
//  ContentView.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 06/10/25.
//

import SwiftUI
import Supabase

//struct ContentView: View {
//    @EnvironmentObject var session: SessionManager
//    @SceneStorage("selectedTab") var selectedTab = 0
//
//    var body: some View {
//        Group {
//            if session.isSignedIn {
//                // ✅ Main app after login
//                MainTabView(selectedTab: $selectedTab, sharedText: .constant(""), hasNewSharedText: <#Binding<Bool>#>)
//            } else {
//                // 👇 Sign-in screen
////                SignInWithAppleView()
//                MainTabView(selectedTab: $selectedTab, sharedText: .constant(""))
//            }
//        }
////        .task {
////            await checkSession()
////        }
//    }
//
//    // MARK: - Auto-login check
//    private func checkSession() async {
//        do {
//            let sessionResult = try await SupabaseManager.shared.client.auth.session
//            let user = sessionResult.user
//            await MainActor.run {
//                session.userId = user.id.uuidString
//                session.isSignedIn = true
//            }
//            print("✅ Auto-login for user: \(user.email ?? "No email")")
//        } catch {
//            await MainActor.run {
//                session.isSignedIn = false
//                session.userId = nil
//            }
//            print("ℹ️ No active session: \(error.localizedDescription)")
//        }
//    }
//}
struct MainTabView: View {
    @Binding var selectedTab: Int
    @Binding var sharedText: String
    @Binding var hasNewObject: Bool
    @Binding var sharedImages: [UIImage]
    @EnvironmentObject var unsavedBus: UnsavedOverlayBus
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var deleteBus: DeleteOverlayBus
    @StateObject private var analyticViewModel = AnalyticTabViewModel()
    @State private var shouldNavigateToActiveOrders = false

    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                Tab("Pesanan", systemImage: "book.pages.fill", value: 0) {
                    AllOrdersView(sharedImages: $sharedImages,
                                  sharedText: $sharedText,
                                  hasNewObject: $hasNewObject)
                    .environmentObject(analyticViewModel)
                }
                
                Tab("Jadwal", systemImage: "calendar", value: 1) {
                    ActiveOrdersView()
                        .environmentObject(analyticViewModel)
                }
                Tab("Analitik", systemImage: "chart.bar", value: 2) {
                    AnalyticTabView()
                        .environmentObject(analyticViewModel)
                }
                if selectedTab == 0 || selectedTab == 4 {
                    Tab("Cari Nama atau Pesanan", systemImage: "magnifyingglass", value: 4, role: .search) {
                        AllOrdersView(sharedImages: $sharedImages,
                                      sharedText: $sharedText,
                                      hasNewObject: $hasNewObject)
                        .environmentObject(analyticViewModel)
                    }
                   
                }
                Tab("AIVA AI", systemImage: "ellipsis.message.fill", value: 3) {
                    ChatBotView()
                }
            }
            .tint(.primaryButton)
            .onAppear {
                if let userIdStr = session.userId,
                   let userId = UUID(uuidString: userIdStr) {
                    analyticViewModel.prefetchInitialData(userId: userId)
                }

                // 🚀 Handle notification tap
                if UserDefaults.standard.bool(forKey: "shouldNavigateToActiveOrders") {
                    selectedTab = 1 // ActiveOrdersView tab
                    UserDefaults.standard.removeObject(forKey: "shouldNavigateToActiveOrders")
                }

                NotificationCenter.default.addObserver(forName: .navigateToActiveOrders, object: nil, queue: .main) { _ in
                    selectedTab = 1
                }
            }
            .onChange(of: selectedTab) { newTab in
                if newTab != 2,  // Bukan di Analytics tab
                   let userIdStr = session.userId,
                   let userId = UUID(uuidString: userIdStr) {
                    analyticViewModel.prefetchInitialData(userId: userId)
                }
            }
        }
    }
}

