//
//  ActiveOrdersView.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 10/10/25.
//

import SwiftUI

struct ActiveOrdersView: View {
    @EnvironmentObject var session: SessionManager
    @State private var viewModel = AllOrdersViewModel()
    @State private var selectedDate: Date = Date()
    @State private var currentMonth: Date = Date()
    @State private var isCollapsed: Bool = false

    @State private var lastListMinY: CGFloat = 0
    private let collapseThreshold: CGFloat = 8
    private let expandThreshold: CGFloat = 12
    private let expandNearTop: CGFloat = 16
    private let minDeltaToConsider: CGFloat = 0.5
    
    @State private var sortOption: String = "Waktu"
    @State private var showSortPopover = false

    var body: some View {
        NavigationStack {
          VStack(spacing: 0) {
            CalendarHeaderView(
              selectedDate: $selectedDate,
              currentMonth: $currentMonth,
              isCollapsed: $isCollapsed,
              viewModel: viewModel
            )

            Divider()
              
              HStack{
                  
                  Text("Urutkan Berdasarkan")
                  Spacer()
                  Menu {
                      Section("Sort By") {
                          Button {
                              sortOption = "Waktu"
                          } label: {
                              Label("Waktu", systemImage: sortOption == "Waktu" ? "checkmark" : "")
                          }

                          Button {
                              sortOption = "Nama Produk"
                          } label: {
                              Label("Nama Produk", systemImage: sortOption == "Nama Produk" ? "checkmark" : "")
                          }
                      }
                  } label: {
                      Image(systemName: "arrow.up.arrow.down.square.fill")
                  }

                  
              }
              .font(.title2)
              .fontWeight(.bold)
              .padding(.horizontal)
              .padding(.top)

            ScrollView {
              LazyVStack(spacing: 0) {
                OrderListView(
                    selectedDate: selectedDate,
                    viewModel: viewModel,
                    sortOption: sortOption
                )
                .background(
                  GeometryReader { geo in
                    let minY = geo.frame(in: .named("ordersSpace")).minY
                    Color.clear
                      .onChange(of: minY, initial: true) { oldY, newY in
                        let rawDelta = newY - oldY
                          
                        // Ignore jitter
                        guard abs(rawDelta) > 15 else { return }

                        // Velocity bias: quick flicks count more, but capped
                        let bias = min(max(abs(rawDelta) / 18, 1), 2.0)
                        let delta = rawDelta * bias

                          withAnimation(.easeInOut(duration: 0)) {
                          // Scrolling up (content moves up) => delta negative => collapse
                          if delta < -6, !isCollapsed, newY < -20 {
                            isCollapsed = true
                          }
                          // Scrolling down (content moves down) => delta positive => expand if near top
                          else if delta > 6, isCollapsed, newY > 20 {
                            isCollapsed = false
                          }
                        }
                      }
                  }
                )
              }
            }
            .coordinateSpace(name: "ordersSpace")
          }
          .task {
              if let userIdString = session.userId,
                 let userId = UUID(uuidString: userIdString) {
                  await viewModel.fetchBusinessName(for: userId)
                  await viewModel.autoCancelOverdueOrders()
                  await viewModel.fetchOrders(for: userId)
                  await viewModel.fetchOrderItems(for: userId)
              } else {
                  print("❌ User ID invalid or nil")
              }
          }
          .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Scroll Offset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}


#Preview {
    // Create a stub session
    let session = SessionManager()
    session.isSignedIn = true
    session.userId = "083dc90d-ca03-4f45-a631-06fe21fe750f"
    
    // Create the view
    let view = ActiveOrdersView()
    
    // Inject the environment object
    return view.environmentObject(session)
}
