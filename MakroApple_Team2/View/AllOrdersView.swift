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
    
    
    @State private var scrollOffset: CGFloat = 0
    @State private var topInset: CGFloat = 0
    @State private var startTopInset: CGFloat = 0
    
    @State var activeTab: TabModel = .belumBayar
    
    private var filteredOrders: [OrderRecord] {
        viewModel.orders.filter { order in
            order.status.localizedCaseInsensitiveCompare(activeTab.dbValue)  == .orderedSame
        }
    }
    
    @State private var distance = 0
    var body: some View {
        GeometryReader{ geo in
            NavigationView{
                VStack{
                    HStack{
                        // Business Name
                        Text(viewModel.businessName.isEmpty ? "Loading..." : viewModel.businessName)
                        
                            .fontWeight(.bold)
                        
                        
                        Spacer()
                        
                        NavigationLink(destination: NewOrderView()) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.blue)
                        }
                        
                    }
                    .font(.largeTitle)
                    .padding(.horizontal)
                    
                    
                    
                    
                    // Deadline Card
                    DeadlineCard()
                    
                    
                    
                    // Custom Tab Bar
                    CustomTabBar(activeTab: $activeTab)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical)
                    
                    // Orders List
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredOrders) { order in
                                if let firstItem = viewModel.orderItems.first(where: { $0.orderId == order.id }) {
                                    NavigationLink(
                                                        destination: OrderDetailView(order: order, orderItem: [firstItem])
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
                    // Pastikan user sudah login
                    if let userIdString = session.userId,
                       let userId = UUID(uuidString: userIdString) {
                        await viewModel.fetchBusinessName(for: userId)
                        await viewModel.fetchOrders(for: userId)
                        await viewModel.fetchOrderItems(for: userId)
                    } else {
                        print("❌ User ID invalid or nil")
                    }
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
