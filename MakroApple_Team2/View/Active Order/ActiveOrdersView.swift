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
    
    @State var showProfile = false
    @State private var profileImage: UIImage? = nil
    @State var onChangeSettings = false
    
    @State private var viewMode: ViewMode = .bulanan
    @State private var sortMode: SortMode = .waktu

    enum ViewMode { case bulanan, mingguan }
    enum SortMode { case waktu, namaProduk }
    
    @State private var sortOption: String = "Waktu"
    @State private var showSortPopover = false

    @State private var expandedProducts: Set<String> = []

    
    var body: some View {
        NavigationStack {
          VStack(spacing: 0) {
              HStack {
                  Text("Kalender")
                      .font(.largeTitle)
                      .fontWeight(.bold)
                      .foregroundStyle(Color(.black))
                  
                  Spacer()
          
                  Menu {
                          // Section 1 – View mode
                          Button {
                              viewMode = .bulanan
                              isCollapsed = false
                          } label: {
                              HStack(spacing: 8) {
                                     Image(systemName: viewMode == .bulanan ? "checkmark" : "checkmark")
                                         .opacity(viewMode == .bulanan ? 1 : 0)

                                     Image(systemName: "rectangle.grid.1x2")
                                     Text("Bulanan")
                                 }
                          }

                          Button {
                              viewMode = .mingguan
                              isCollapsed = true
                          } label: {
                              Label("Mingguan",
                                    systemImage: viewMode == .mingguan ? "checkmark" : "square.grid.3x1.below.line.grid.1x2")
                          }

                          Divider()

                          // Section 2 – Sort By
                          Text("Sort By")
                              .font(.caption)
                              .foregroundColor(.secondary)

                          Button {
                              sortMode = .waktu
                              sortOption = "Waktu"
                          } label: {
                              Label("Waktu",
                                    systemImage: sortMode == .waktu ? "checkmark" : "square.grid.2x2")
                          }

                          Button {
                              sortMode = .namaProduk
                              sortOption = "Nama Produk"
                          } label: {
                              Label("Nama Produk",
                                    systemImage: sortMode == .namaProduk ? "checkmark" : "square.dashed")
                          }
                      } label: {
                          ZStack {
                              Circle()
                                  .fill(Color.white)
                                  .frame(width: 40, height: 40)
                                  .shadow(color: Color(.systemGray4),
                                          radius: 4, x: 0, y: 1)
                              Image(systemName: "ellipsis")
                                  .font(.title3.weight(.semibold))
                                  .foregroundColor(.primaryButton)
                          }
                      }
                      .buttonStyle(.plain)
                     
                  
                  Button {
                      showProfile = true
                  } label: {
                      if let logoImage = profileImage {
                          Image(uiImage: logoImage)
                              .resizable()
                              .scaledToFill()
                              .frame(width: 40, height: 40)
                              .clipShape(Circle())
                      } else {
                          ZStack {
                              Circle()
                                  .fill(Color.white)
                                  .frame(width: 40, height: 40)
                                  .shadow(color: Color(.systemGray4),
                                          radius: 4, x: 0, y: 1)

                              Image(systemName: "person.fill")
                                  .font(.title3)
                                  .foregroundColor(.primaryButton)
                          }
                      }
                  }
              }
              .padding(.horizontal)
              .padding(.bottom, 8)
              .task(id: viewModel.businessLogoUrl) {
                  guard let urlString = viewModel.businessLogoUrl else {
                      profileImage = nil
                      return
                  }
                  profileImage = await viewModel.loadImage(from: urlString)
              }
              
            CalendarHeaderView(
              selectedDate: $selectedDate,
              currentMonth: $currentMonth,
              isCollapsed: $isCollapsed,
              viewModel: viewModel
            )

            Divider()
              
              HStack{
                  
                  Text("Rekap Pesanan")
                  Spacer()
//                  Menu {
//                      Section("Sort By") {
//                          Button {
//                              sortOption = "Waktu"
//                          } label: {
//                              Label("Waktu", systemImage: sortOption == "Waktu" ? "checkmark" : "")
//                          }
//
//                          Button {
//                              sortOption = "Nama Produk"
//                          } label: {
//                              Label("Nama Produk", systemImage: sortOption == "Nama Produk" ? "checkmark" : "")
//                          }
//                      }
//                  } label: {
//                      Image(systemName: "arrow.up.arrow.down.square.fill")
//                  }

                  
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
                      sortOption: sortOption,
                      expandedProducts: $expandedProducts
                  )

//                .background(
//                  GeometryReader { geo in
//                    let minY = geo.frame(in: .named("ordersSpace")).minY
//                    Color.clear
//                      .onChange(of: minY, initial: true) { oldY, newY in
//                        let rawDelta = newY - oldY
//
//                        // Ignore jitter
//                        guard abs(rawDelta) > 15 else { return }
//
//                        // Velocity bias: quick flicks count more, but capped
//                        let bias = min(max(abs(rawDelta) / 18, 1), 2.0)
//                        let delta = rawDelta * bias
//
//                          withAnimation(.easeInOut(duration: 0)) {
//                          // Scrolling up (content moves up) => delta negative => collapse
//                          if delta < -6, !isCollapsed, newY < -20 {
//                            isCollapsed = true
//                          }
//                          // Scrolling down (content moves down) => delta positive => expand if near top
//                          else if delta > 6, isCollapsed, newY > 20 {
//                            isCollapsed = false
//                          }
//                        }
//                      }
//                  }
//                )
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
          .sheet(isPresented: $showProfile) {
              NavigationStack{
                  SettingsView(onChangeSettings: $onChangeSettings)
                 
              }
          }
          .onChange(of: onChangeSettings) { newValue in
              if newValue {
                  onChangeSettings = false
                  Task {
                      guard let userIdString = session.userId,
                            let userId = UUID(uuidString: userIdString) else { return }
                      
                      await viewModel.checkIfUserHasTemplates(for: userId)
                      await viewModel.fetchBusinessName(for: userId)
                      await viewModel.fetchOrders(for: userId)
                      await viewModel.fetchOrderItems(for: userId)
                  }
              }
          }
//          .navigationBarTitleDisplayMode(.inline)
//          .navigationTitle("Kalender")
//          .navigationBarTitleDisplayMode(.large)
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

struct MenuRow: View {
    let isSelected: Bool
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                } else {
                    // keep alignment
                    Color.clear
                        .frame(width: 14, height: 14)
                }

                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .regular))

                Text(title)
                    .font(.body)
            }
            .foregroundColor(.primary)
        }
        .buttonStyle(.plain)
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
