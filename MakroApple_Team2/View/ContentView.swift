//
//  ContentView.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 06/10/25.
//

import SwiftUI

struct ContentView: View {
  @State private var selected: Tab = .active
  @State private var showNewOrder = false
  @Environment(\.colorScheme) private var scheme
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

  var body: some View {
    ZStack(alignment: .bottom) {
      TabView(selection: $selected) {
        ActiveOrdersView().tabItem { Label("Active", systemImage: "calendar") }.tag(Tab.active)
        AllOrdersView().tabItem { Label("Orders", systemImage: "tray.full") }.tag(Tab.orders)
        AnalyticsView().tabItem { Label("Analytics", systemImage: "chart.bar") }.tag(Tab.analytics)
        SettingsView().tabItem { Label("Settings", systemImage: "gearshape") }.tag(Tab.settings)
      }

      // Docked circle button “next to” the Tab Bar
      HStack {
        Spacer()
        AddButton {
          showNewOrder = true
        }
        .padding(.trailing, 12)
      }
      .padding(.bottom, 60)
      .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    .sheet(isPresented: $showNewOrder) {
      NewOrderView()
    }
  }

  enum Tab { case active, orders, analytics, settings }
}

private struct AddButton: View {
  var action: () -> Void
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

  var body: some View {
    Button(action: action) {
      Image(systemName: "plus")
        .font(.system(size: 18, weight: .semibold))
        .frame(width: 56, height: 56)
        .foregroundStyle(.primary)
        .background(backgroundMaterial, in: Circle())
        .overlay(
          Circle().strokeBorder(Color.white.opacity(0.18))
        )
        .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
        .accessibilityLabel("Add order")
    }
  }

  private var backgroundMaterial: some ShapeStyle {
    reduceTransparency ? AnyShapeStyle(.bar) : AnyShapeStyle(.ultraThickMaterial)
  }
}


#Preview {
    ContentView()
}
