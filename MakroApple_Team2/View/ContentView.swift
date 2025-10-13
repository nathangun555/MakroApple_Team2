//
//  ContentView.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 06/10/25.
//

import SwiftUI
import Foundation

struct ContentView: View {
  @State private var showNewOrder = false
  @Environment(\.colorScheme) private var scheme
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

  var body: some View {
      TabView {
          Tab("Active", systemImage: "calendar") {
              ActiveOrdersView()
          }
          Tab("Orders", systemImage: "tray.full"){
              AllOrdersView()
          }
          Tab("Analytics", systemImage: "chart.bar"){
              AnalyticsView()
          }
          Tab("Settings", systemImage: "tray.full"){
              SettingsView()
          }
          Tab("Add", systemImage: "plus.circle.fill", role: .search){
              NewOrderView()
          }
      }
  }
}

#Preview {
    ContentView()
}
