//
//  AllOrdersView.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 10/10/25.
//

import SwiftUI

struct AllOrdersView: View {
    @State private var searchText = ""
    @State var activeTab: TabModel = .belumBayar
    @State private var showSearchBar = false
    
    @Binding var sharedImages: [UIImage]
    @Binding var sharedText: String
    @Binding var hasNewObject: Bool
    @State var showNewOrderView = false
    @State var showTutorial = false
    @State var isDismissed = false
    
    @Environment(\.dismiss) var dismiss
    
    // 🧠 These caches temporarily store data per navigation ID
    @State private var orderDataCache: [UUID: [String: Any]] = [:]
    @State private var orderImagesCache: [UUID: [UIImage]] = [:]
    
    @AppStorage("showBelumBayarGuide") private var showBelumBayarGuide: Bool = true
    @AppStorage("showDiprosesGuide") private var showDiprosesGuide: Bool = true
    @AppStorage("showDikirimGuide") private var showDikirimGuide: Bool = true
    @AppStorage("showSelesaiGuide") private var showSelesaiGuide: Bool = true
    @AppStorage("showDibatalkanGuide") private var showDibatalkanGuide: Bool = true
    
    @EnvironmentObject var session: SessionManager
    
    @State private var viewModel = AllOrdersViewModel()

    private var filteredOrders: [OrderRecord] {
        viewModel.orders
            .filter { order in
                order.status.localizedCaseInsensitiveCompare(activeTab.dbValue) == .orderedSame
            }
            .filter { order in
                if searchText.isEmpty { return true }
                let lowerSearch = searchText.lowercased()
                return order.customerOrderName.lowercased().contains(lowerSearch) ||
                (order.customerOrderPhone?.lowercased().contains(lowerSearch) ?? false)
            }
            .sorted { a, b in
                guard let dateA = a.orderDdayDate, let dateB = b.orderDdayDate else { return false }
                return dateA < dateB
            }
    }

    var body: some View {
        NavigationStack() {
            VStack {
                // 🏷️ Header
                HStack {
                    
                    Button {
                        showBelumBayarGuide = true
                        showDiprosesGuide = true
                        showDikirimGuide = true
                        showSelesaiGuide = true
                        showDibatalkanGuide = true
                    } label: {
                        Text("Pesanan")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(Color(.black))
                    }
                    
                    Spacer()
                    Button {
                        handleAddNewOrder()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.primaryButton)
                    }
                }
                .padding(.horizontal)
                
                DeadlineCard(orders: viewModel.orders, hastemplates: viewModel.hasTemplates)
                CustomTabBar(activeTab: $activeTab)
                
                GuideMessage(
                    activeTab: activeTab,
                    isVisible: activeTab == .belumBayar ? $showBelumBayarGuide :
                        activeTab == .diproses ? $showDiprosesGuide :
                        activeTab == .terkirim ? $showDikirimGuide :
                        activeTab == .selesai ? $showSelesaiGuide :
                        $showDibatalkanGuide
                )
                .padding(.vertical, 5)
                
                
                

                
                // 📋 Orders List
                
                VStack {
                    if filteredOrders.isEmpty {
                        VStack {
                            Image(systemName: "doc.text.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                                .padding(12) // jarak dari icon ke tepi circle
                                .background(
                                    Circle()
                                        .fill(Color.blue.opacity(0.1))
                                )

                                    Text("Belum Ada Pesanan")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)

                                    Text("Belum ada pesanan yang tercatat.\nTambah pesanan baru untuk mulai kelola penjualanmu dengan mudah.")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 32)
                                }
                    }
                    else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredOrders) { order in
                                    let orderItems = viewModel.orderItems.filter { $0.orderId == order.id }
                                    
                                    if !orderItems.isEmpty {
                                        NavigationLink(
                                            destination:
                                                OrderDetailView(
                                                    order: order,
                                                    orderItem: orderItems,
                                                    source: .allOrders,
                                                    activeTab: $activeTab
                                                )
                                                .toolbar(.hidden, for: .tabBar)
                                                .environmentObject(session)
                                        ) {
                                            OrderCard(order: order, orderItem: orderItems.first!)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                            .padding(.bottom, 20)
                            
                            
                        }
                      
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                   
               
                   
            }
            .navigationBarHidden(true)
            .task {
                guard let userIdString = session.userId,
                      let userId = UUID(uuidString: userIdString) else { return }
                
                print("🪪 Fetching data for user:", userId)
                await viewModel.checkIfUserHasTemplates(for: userId)
                await viewModel.fetchBusinessName(for: userId)
                await viewModel.fetchOrders(for: userId)
                await viewModel.fetchOrderItems(for: userId)
            }
            .onAppear {
                if hasNewObject {
                    print("📩 Detected shared text on appear:", sharedText)
                    showNewOrderView = true
                    hasNewObject = false
                }
            }
            .onChange(of: hasNewObject) { newValue in
                if newValue {
                    print("📩 Detected new shared text via onChange:", sharedText)
                    showNewOrderView = true
                    hasNewObject = false
                    
                }
            }
            .fullScreenCover(isPresented: $showNewOrderView) {
                NavigationStack{
                    NewOrderView(
                        sharedText: $sharedText,
                        sharedImages: $sharedImages,
                        isDismissed: $isDismissed
                    )
                    
                }
            }
            .onChange(of: isDismissed) { newValue in
                if newValue {
                    showNewOrderView = false  // closes the fullScreenCover
                    isDismissed = false       // reset state for next time
                    Task {
                        guard let userIdString = session.userId,
                              let userId = UUID(uuidString: userIdString) else { return }
                        
                        await viewModel.checkIfUserHasTemplates(for: userId)
                        await viewModel.fetchBusinessName(for: userId)
                        await viewModel.fetchOrders(for: userId)
                        await viewModel.fetchOrderItems(for: userId)
                    }
                }
                
                sharedText = ""
                sharedImages = []
                
            }

            .fullScreenCover(isPresented: $showTutorial) {
                NavigationStack{
                    InputBusinessDetailsView(isDismissed: $isDismissed)
                   
                }
            }
            .onChange(of: isDismissed) { newValue in
                if newValue {
                    showTutorial = false  // closes the fullScreenCover
                    isDismissed = false       // reset state for next time
                }
            }
        }
        
        .searchable(text: $searchText, prompt: "Cari Nama Pelanggan")
    }
    
    // MARK: - 🔘 Add New Order
    private func handleAddNewOrder() {
        let id = UUID()
        orderImagesCache[id] = sharedImages
        orderDataCache[id] = ["sharedText": sharedText]

        if viewModel.hasTemplates {
            showNewOrderView = true
//            showTutorial = true
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

