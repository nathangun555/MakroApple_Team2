//
//  ContentView.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 06/10/25.
//


import SwiftUI
import Foundation

struct ContentView: View {
    
    @SceneStorage("selectedTab") var selectedTab = 0
    @State private var showNewOrder = false
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        
        GeometryReader { geometry in
            
            NavigationStack {
                TabView(selection: $selectedTab) {
                    Tab("Orders", systemImage: "calendar", value: 0) {
                        AllOrdersView()
                    }
                    Tab("Active", systemImage: "tray.full", value: 1) {
                        ActiveOrdersView()
                    }
                    Tab("Analytics", systemImage: "chart.bar", value: 2) {
                        AnalyticsView()
                    }
                    Tab("Settings", systemImage: "gearshape", value: 3) {
                        SettingsView()
                    }
                    if selectedTab == 0 || selectedTab == 4 {
                        Tab("Search", systemImage: "magnifyingglass", value: 4, role: .search) {
                            AllOrdersView()
                        }
                    }
                }
                //            .tabBarMinimizeBehavior(.onScrollDown)
                .tabViewBottomAccessory {
                    if selectedTab == 0 {
                        Button(action: {
                            showNewOrder = true
                        }) {
                            HStack {
                                Image(systemName: "plus")
                                Text("Add New Order")
                            }
                            .frame(width: geometry.size.width)
                        }
                    }
                }
                .navigationDestination(isPresented: $showNewOrder) {
                    NewOrderView()
                        .navigationBarBackButtonHidden(false)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
