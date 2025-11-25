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
    @State var showProfile = false
    @State var isDismissed = false
    @State var onChangeSettings = false
    
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
    @EnvironmentObject var deleteBus: DeleteOverlayBus
    
    @State private var viewModel = AllOrdersViewModel()
    @State private var profileImage: UIImage? = nil

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
                // Header
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
                        ZStack {
                            Circle()
                                .fill(viewModel.hasTemplates ? .primaryButton : .white)
                                .frame(width: 40, height: 40)
                                .shadow(color: Color(.systemGray4),
                                        radius: 4, x: 0, y: 1)

                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(viewModel.hasTemplates ? .white : .secondary)
                        }
                    }
                    .disabled(!viewModel.hasTemplates)
                    
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
//                                    .glassEffect()
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .task(id: viewModel.businessLogoUrl) {
                    guard let urlString = viewModel.businessLogoUrl else {
                        profileImage = nil
                        return
                    }
                    profileImage = await viewModel.loadImage(from: urlString)
                }
                
                DeadlineCard(orders: viewModel.orders, hastemplates: viewModel.hasTemplates, isTutorial: $showTutorial)
                
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
                        OrderEmptyState()
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
                                            OrderCard(order: order, orderItem: orderItems)
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
//                await viewModel.autoCancelOverdueOrders()
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
                    showNewOrderView = false
                    isDismissed = false
                    Task {
                        guard let userIdString = session.userId,
                              let userId = UUID(uuidString: userIdString) else { return }
                        
                        await viewModel.checkIfUserHasTemplates(for: userId)
                        await viewModel.fetchBusinessName(for: userId)
//                        await viewModel.autoCancelOverdueOrders()
                        await viewModel.fetchOrders(for: userId)
                        await viewModel.fetchOrderItems(for: userId)
                    }
                }
                
                sharedText = ""
                sharedImages = []
                
            }
            
            .onChange(of: onChangeSettings) { newValue in
                if newValue {
                    onChangeSettings = false
                    Task {
                        guard let userIdString = session.userId,
                              let userId = UUID(uuidString: userIdString) else { return }
                        
                        await viewModel.checkIfUserHasTemplates(for: userId)
                        await viewModel.fetchBusinessName(for: userId)
//                        await viewModel.autoCancelOverdueOrders()
                        await viewModel.fetchOrders(for: userId)
                        await viewModel.fetchOrderItems(for: userId)
                    }
                }
            }

            .fullScreenCover(isPresented: $showTutorial) {
                NavigationStack{
                    InputBusinessDetailsView(isDismissed: $isDismissed)
                   
                }
            }
            .sheet(isPresented: $showProfile) {
                NavigationStack{
                    SettingsView(onChangeSettings: $onChangeSettings)
                }
            }
            .onChange(of: isDismissed) { newValue in
                if newValue {
                    showTutorial = false
                    isDismissed = false
                }
            }
        }
        
        .searchable(text: $searchText, prompt: "Cari Nama Pelanggan")
    }
    
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

#Preview("Signed In") {
    let session = SessionManager()
    session.isAuthLoaded = true
    session.isSignedIn = true

    return MainTabView(
        selectedTab: .constant(0),
        sharedText: .constant("Test Text"),
        hasNewObject: .constant(false),
        sharedImages: .constant([])
    )
    .environmentObject(session)
    .environmentObject(DeleteOverlayBus())
    .environmentObject(UnsavedOverlayBus())
}

