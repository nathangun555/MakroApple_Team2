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
    
    @Binding var sharedImages: [UIImage]
    @Binding var sharedText: String
    @Binding var hasNewObject: Bool
    @State var showNewOrderView = false
    @State var showTutorial = false
    
    @AppStorage("showBelumBayarGuide") private var showBelumBayarGuide: Bool = true
    @AppStorage("showDiprosesGuide") private var showDiprosesGuide: Bool = true
    @AppStorage("showDikirimGuide") private var showDikirimGuide: Bool = true
    @AppStorage("showSelesaiGuide") private var showSelesaiGuide: Bool = true
    @AppStorage("showDibatalkanGuide") private var showDibatalkanGuide: Bool = true
    
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
        
            NavigationStack{
                VStack{
                    HStack{
                        Text("Pesanan")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button {
                            handleAddNewOrder()
                        } label: {
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
                    
                    GuideMessage(activeTab: activeTab, isVisible: activeTab == .belumBayar ? $showBelumBayarGuide :
                                    activeTab == .diproses ? $showDiprosesGuide :
                                    activeTab == .terkirim ? $showDikirimGuide :
                                    activeTab == .selesai ? $showSelesaiGuide :
                                    $showDibatalkanGuide)
                        .padding(.vertical,5)
                    
                    Button("Tampilkan Panduan Lagi") {
                        showBelumBayarGuide = true
                        showDiprosesGuide = true
                        showDikirimGuide = true
                        showSelesaiGuide = true
                        showDibatalkanGuide = true
                    }
                    .font(.caption2)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
                    
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
                    await viewModel.checkIfUserHasTemplates(for: userId)
                    await viewModel.fetchBusinessName(for: userId)
                    await viewModel.fetchOrders(for: userId)
                    await viewModel.fetchOrderItems(for: userId)
                }
                .onAppear {
                                // ✅ If the shared text already exists when view appears
                                if hasNewObject {
                                    print("📩 Detected shared text on appear:", sharedText)
                                    showNewOrderView = true
                                    hasNewObject = false
                                }
                            }
                            .onChange(of: hasNewObject) { newValue in
                                // ✅ If shared text changes while already in app
                                if newValue {
                                    print("📩 Detected new shared text via onChange:", sharedText)
                                    showNewOrderView = true
                                    hasNewObject = false
                                }
                            }
                            .navigationDestination(isPresented: $showNewOrderView) {
                                NewOrderView(sharedText: $sharedText, sharedImages: $sharedImages)
                            }
                            .navigationDestination(isPresented: $showTutorial) {
                                InputBusinessDetailsView()
                            }
            }
            .searchable(text: $searchText, prompt: "Cari Nama Pelanggan")
        
    }
    private func handleAddNewOrder() {
            if viewModel.hasTemplates {
                showNewOrderView = true
            } else {
                showTutorial = true
            }
        }
    
}
    


//#Preview {
//    // Create a stub session
//    let session = SessionManager()
//    session.isSignedIn = true
//    session.userId = "083dc90d-ca03-4f45-a631-06fe21fe750f"
//    
//    // Create the view
//    let view = AllOrdersView(sharedText: .constant(""))
//    
//    // Inject the environment object
//    view.environmentObject(session)
//}

