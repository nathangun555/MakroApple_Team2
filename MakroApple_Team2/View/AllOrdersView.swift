//
//  AllOrdersView.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 10/10/25.
//

import SwiftUI

struct AllOrdersView: View {
    @State private var searchText = ""
    @State private var path = NavigationPath()
    @State var activeTab: TabModel = .belumBayar
    
    @Binding var sharedImages: [UIImage]
    @Binding var sharedText: String
    @Binding var hasNewObject: Bool
    @State var showNewOrderView = false
    @State var showTutorial = false
    
    @State private var parsedOrderData: [String: Any] = [:]
    @State private var selectedImages: [UIImage?] = [nil]
    
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
        NavigationStack(path: $path) {
            VStack {
                // 🏷️ Header
                HStack {
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
                .padding(.horizontal)
                
                DeadlineCard(orders: viewModel.orders)
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
                
                // 📋 Orders List
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
                                        )
                                        .environmentObject(session)
                                ) {
                                    OrderCard(order: order, orderItem: firstItem)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
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
            .navigationDestination(for: OrderDestination.self) { destination in
                switch destination {
                case .newOrder:
                    NewOrderView(
                        selectedImages: $selectedImages,
                        parsedOrderData: $parsedOrderData,
                        sharedText: $sharedText,
                        sharedImages: $sharedImages,
                        path: $path
                    )
                    
                case .editOrder:
                    EditOrderView(
                        parsedOrderData: $parsedOrderData,
                        selectedImages: $selectedImages,
                        path: $path
                    )
                    
                case .confirmInvoice(let orderId):
                    ConfirmInvoiceView(orderId: orderId, path: $path)
                    
                case .invoicePreview(let orderId):
                    InvoicePreviewView(orderId: orderId, path: $path)
                    
                case .tutorial:
                    InputBusinessDetailsView()
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
            path.append(OrderDestination.newOrder)
        } else {
            path.append(OrderDestination.tutorial)
        }
    }
}

// MARK: - 🧭 Navigation Enum (Now Clean & Hashable)
enum OrderDestination: Hashable {
    case newOrder
    case editOrder
    case confirmInvoice(orderId: String)
    case invoicePreview(orderId: String)
    case tutorial
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

