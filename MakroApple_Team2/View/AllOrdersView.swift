//
//  AllOrdersView.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 10/10/25.
//

import SwiftUI

struct AllOrdersView: View {
    
    @EnvironmentObject var session: SessionManager

    @State private var viewModel = AllOrdersViewModel()
    
    
    
    @SceneStorage("selectedTab") var selectedTab = 0
    @State private var searchText = ""
    
    
    @State var activeTab: TabModel = .belumBayar
    
//    private var filteredOrders: [OrderRecord] {
//        viewModel.orders.filter { order in
//            order.status.localizedCaseInsensitiveCompare(activeTab.dbValue)  == .orderedSame
//        }
//        
//        .sorted { a, b in
//            guard let dateA = a.orderDdayDate, let dateB = b.orderDdayDate else {
//                return false
//            }
//            return dateA < dateB
//        }
//    }
    
    private var filteredOrders: [OrderRecord] {
        viewModel.orders
            .filter { order in
                // Match the selected tab first
                order.status.localizedCaseInsensitiveCompare(activeTab.dbValue) == .orderedSame
            }
            .filter { order in
                // If search text is empty, include all
                if searchText.isEmpty { return true }
                
                // Convert both sides to lowercase for case-insensitive matching
                let lowerSearch = searchText.lowercased()
                
                // Match by name or phone number (adjust property names if needed)
                return order.customerOrderName.lowercased().contains(lowerSearch) == true ||
                order.customerOrderPhone?.lowercased().contains(lowerSearch) == true
            }
            .sorted { a, b in
                guard let dateA = a.orderDdayDate, let dateB = b.orderDdayDate else {
                    return false
                }
                return dateA < dateB
            }
    }

    
    var body: some View {
        GeometryReader{ geo in
            NavigationView{
                VStack{
                    HStack{
                        let sharedDefaults = UserDefaults(suiteName: "group.com.macroa2.identifier")
                        if let sharedText = sharedDefaults?.string(forKey: "sharedText") {
                            
                            Text(sharedText)
                        }
                        
                        // Business Name
//                        Text(viewModel.businessName.isEmpty ? "Loading..." : viewModel.businessName)
                        
                        Text("Pesanan")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        NavigationLink(destination: NewOrderView()) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.primaryButton)
                        }
                        
                    }
                    .font(.largeTitle)
                    .padding(.horizontal)
                    
                    
                    
                    
                    // Deadline Card
                    DeadlineCard(orders: viewModel.orders)
                    
                    
                    
                    // Custom Tab Bar
                    CustomTabBar(activeTab: $activeTab)
//                        .frame(maxWidth: .infinity)
                        .padding(.vertical)
                    
                    // Orders List
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredOrders) { order in
                                if let firstItem = viewModel.orderItems.first(where: { $0.orderId == order.id }) {
                                    NavigationLink(
                                        destination:
                                            OrderDetailView(
                                                order: order,
                                                orderItem: [firstItem],
                                                source: .allOrders,
                                                activeTab: $activeTab
                                            ).environmentObject(session)
                                                    ) {
                                                        OrderCard(order: order, orderItem: firstItem)
                                                    }
                                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            
                        }
                        .padding(.bottom, 20)
                    }
                    .navigationTitle("")
                    .navigationBarHidden(true)
                    
                }
                .task {
                    guard let userIdString = session.userId, let userId = UUID(uuidString: userIdString) else { return }
                    print("🪪 Fetching data for user:", userId)
                    await viewModel.fetchBusinessName(for: userId)
                    await viewModel.fetchOrders(for: userId)
                    await viewModel.fetchOrderItems(for: userId)
                }
            }
            .isSearchable(selectedTab: selectedTab, filter: $searchText)
        }
    }
    
}
    


#Preview {
    // Create a stub session
    let session = SessionManager()
    session.isSignedIn = true
    session.userId = "083dc90d-ca03-4f45-a631-06fe21fe750f"
    
    // Create the view
    let view = AllOrdersView()
    
    // Inject the environment object
    return view.environmentObject(session)
}



// Struct and Extension to remove the search bar under the navigation title,
// NOTE : Change to the real data filter later, code below is only a dummy.
struct IsSearchableModifier: ViewModifier {
    
    let selectedTab: Int
    @Binding var filter: String
    
    func body(content: Content) -> some View {
        if selectedTab == 4 {
            content
                .searchable(text: $filter, prompt: "Cari Nama atau Pesanan")
        }
        else {
            content
        }
    }
}

extension View {
    func isSearchable(selectedTab: Int, filter: Binding<String>) -> some View {
        self.modifier(IsSearchableModifier(selectedTab: selectedTab, filter: filter))
    }
}
