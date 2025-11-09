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

    @EnvironmentObject var deleteBus: DeleteOverlayBus

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                Tab("Pesanan", systemImage: "basket.fill", value: 0) {
                    AllOrdersView(sharedImages: $sharedImages,
                                  sharedText: $sharedText,
                                  hasNewObject: $hasNewObject)
                }
                Tab("Jadwal", systemImage: "tray.full", value: 1) {
                    ActiveOrdersView()
                }
//                Tab("Analitik", systemImage: "chart.bar", value: 2) {
//                    AnalyticsView()
//                }
                Tab("Pengaturan", systemImage: "gearshape", value: 3) {
                    SettingsView()
                }
                if selectedTab == 0 || selectedTab == 4 {
                    Tab("Cari Nama atau Pesanan", systemImage: "magnifyingglass", value: 4, role: .search) {
                        AllOrdersView(sharedImages: $sharedImages,
                                      sharedText: $sharedText,
                                      hasNewObject: $hasNewObject)
                    }
                }
            }
            .disabled(deleteBus.show)

            if deleteBus.show {
                CustomDeleteAlertComponent(
                    title: "Hapus",
                    message: deleteBus.message,
                    cancelTitle: "Tidak",
                    confirmTitle: "Ya",
                    onCancel: { deleteBus.closeConfirm(false) },
                    onConfirm: { deleteBus.closeConfirm(true) }
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(999)
                .ignoresSafeArea()
            }
        }
    }
}


        
        
//        NavigationStack {
//            ZStack(alignment: .bottom) {
//                TabView(selection: $selectedTab) {
//                    AllOrdersView()
//                        .tabItem { Label("Pesanan", systemImage: "basket.fill") }
//                        .tag(0)
//
//                    ActiveOrdersView()
//                        .tabItem { Label("Jadwal", systemImage: "tray.full") }
//                        .tag(1)
//
//                    AnalyticsView()
//                        .tabItem { Label("Analitik", systemImage: "chart.bar") }
//                        .tag(2)
//
//                    SettingsView()
//                        .tabItem { Label("Pengaturan", systemImage: "gearshape") }
//                        .tag(3)
//                    
//                }
//
////                if selectedTab == 0 {
////                    Button(action: { showNewOrder = true }) {
////                        HStack {
////                            Image(systemName: "plus")
////                            Text("Tambah Pesanan")
////                        }
////                        .frame(maxWidth: .infinity)
////                        .padding()
////                        .background(Color.blue)
////                        .foregroundColor(.white)
////                        .cornerRadius(12)
////                        .shadow(radius: 4)
////                    }
////                    .padding(.horizontal)
////                    .padding(.bottom, 8)
////                }
//            }
////            .navigationDestination(isPresented: $showNewOrder) {
////                NewOrderView()
////                    .navigationBarBackButtonHidden(false)
////            }
//        }
//    }
//}
//
//#Preview {
//    ContentView()
//        .environmentObject(SessionManager())
//}






//
//  ContentView.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 06/10/25.
//


//import SwiftUI
//import Foundation
//
//struct ContentView: View {
//    
//    @SceneStorage("selectedTab") var selectedTab = 0
//    @State private var showNewOrder = false
//    @Environment(\.colorScheme) private var scheme
//    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
//    
//    @State private var searchText: String = ""
//
//    var body: some View {
//        
//        GeometryReader { geometry in
//            
//            NavigationStack {
//                TabView(selection: $selectedTab) {
//                    Tab("Pesanan", systemImage: "basket.fill", value: 0) {
//                        AllOrdersView()
//                    }
//                    Tab("Jadwal", systemImage: "tray.full", value: 1) {
//                        ActiveOrdersView()
//                    }
//                    Tab("Analitik", systemImage: "chart.bar", value: 2) {
//                        AnalyticsView()
//                    }
//                    Tab("Pengaturan", systemImage: "gearshape", value: 3) {
//                        SettingsView()
//                    }
//                    if selectedTab == 0 || selectedTab == 4 {
//                        Tab("Cari Nama atau Pesanan", systemImage: "magnifyingglass", value: 4, role: .search) {
//                            AllOrdersView()
//                        }
//                    }
//                }
//
//                
////                            .tabBarMinimizeBehavior(.onScrollDown)
//                .tabViewBottomAccessory {
//                    if selectedTab == 0 {
//                        Button(action: {
//                            showNewOrder = true
//                        }) {
//                            HStack {
//                                Image(systemName: "plus")
//                                Text("Tambah Pesanan")
//                            }
//                            .frame(width: geometry.size.width, height: geometry.size.height)
//                            .background(Color.blue)
//                            .foregroundStyle(Color.white)
//                        }
//                    }
//                }
//                .navigationDestination(isPresented: $showNewOrder) {
//                    NewOrderView()
//                        .navigationBarBackButtonHidden(false)
//                }
//            }
//        }
//    }
//}
//
