//
//  OrderDetailView.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 14/10/25.
//

import SwiftUI

// To tell where the user open this page from
enum OrderSource {
    case allOrders
    case activeOrders
}

struct OrderDetailView: View {
    
    
    @State private var viewModel = AllOrdersViewModel()
    @EnvironmentObject var session: SessionManager
    let order: OrderRecord
    let orderItem: [OrderItemRecord]
    
    
    @State private var showSuccessToast = false
    @Environment(\.dismiss) private var dismiss
    
    let source: OrderSource
    
    
    @Binding var activeTab: TabModel

    private var userIdString: String? { session.userId }
    
    enum ActiveAlert {
        case payment
        case cancel
    }

    @State private var activeAlert: ActiveAlert? = nil
    
    
    private func currency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "IDR"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "Rp \(value)"
    }
    
    private func buttonText(for status: String) -> String? {
        switch status {
        case "Belum Terbayar":
            return "Pembayaran Selesai"
        case "Diproses":
            return "Lanjut ke Pengiriman"
        case "Terkirim":
            return "Pesanan Diterima Pemesan"
        default:
            return nil // hide button for "Selesai" or "Dibatalkan"
        }
    }
    
    
    var body: some View {
        
        ZStack(alignment: .bottom){
            
            ScrollView {
                
                VStack{
                    
                    OrderStatus(order: order)
                    
                    
//                    Text("Order ID: \(order.id.uuidString)")
//                    Text("User ID: \(userIdString ?? "nil")")
//
//                    Text("User ID: \(session.userId ?? "nil")")
                    
                    
                    VStack{
                        Text("Rincian Pelanggan")
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.title3)
                        
                        
                        let columns = [
                            GridItem(.fixed(150), alignment: .leading),
                            GridItem(.flexible(), alignment: .trailing)
                        ]
                        
                        LazyVGrid(columns: columns, spacing: 10) {
                            Group {
                                
                                // Nama Pemesan
                                Text("Nama Pemesan :")
                                Text(order.customerOrderName)
                                    .padding(.vertical, 3)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray, lineWidth: 0.5) // stroke
                                            .background(RoundedRectangle(cornerRadius: 30).fill(.secondary.opacity(0.1))) // fill
                                    )
                                
                                
                                Text("No. Telp Pemesan :")
                                Text(order.customerOrderPhone!)
                                    .padding(.vertical, 3)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray, lineWidth: 0.5) // stroke
                                            .background(RoundedRectangle(cornerRadius: 30).fill(.secondary.opacity(0.1))) // fill
                                    )
                                
                                Text("Nama Penerima :")
                                Text(order.customerReceiverName!)
                                    .padding(.vertical, 3)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray, lineWidth: 0.5) // stroke
                                            .background(RoundedRectangle(cornerRadius: 30).fill(.secondary.opacity(0.1))) // fill
                                    )
                                
                                Text("No. Telp Penerima :")
                                Text(order.customerReceiverPhone!)
                                    .padding(.vertical, 3)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray, lineWidth: 0.5) // stroke
                                            .background(RoundedRectangle(cornerRadius: 30).fill(.secondary.opacity(0.1))) // fill
                                    )
                                
                                
                            }
                        }
                        
                        Text("Jadwal Pesanan")
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top)
                            .font(.title3)
                        
                        LazyVGrid(columns: columns, spacing: 10) {
                            Group {
                                
                                
                                Text("Tanggal Pesanan :")
                                Text(DateFormatterHelper.formattedDate(order.orderDdayDate!))
                                    .padding(.vertical, 3)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray, lineWidth: 0.5) // stroke
                                            .background(RoundedRectangle(cornerRadius: 30).fill(.secondary.opacity(0.1))) // fill
                                    )
                                
                                Text("Jam Kirim :")
                                Text("\(DateFormatterHelper.formattedTime(order.orderDdayDate!)) WIB")
                                    .padding(.vertical, 3)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray, lineWidth: 0.5) // stroke
                                            .background(RoundedRectangle(cornerRadius: 30).fill(.secondary.opacity(0.1))) // fill
                                    )
                                
                                
                            }
                        }
                        
                        Text("Rincian Pesanan")
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top)
                            .font(.title3)
                        
                        
                        VStack{
                            
                            ForEach(orderItem) { item in
                                
                                // CHANGE THIS LATER WITH PRODUCT CATEGORY
                                Text(item.productType)
                                    .bold()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .font(.headline)
                                
                                LazyVGrid(columns: columns, spacing: 10) {
                                    Group {
                                        
                                        Text("Nama Produk :")
                                        Text(item.productName)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                            .padding(4)
                                            .lineLimit(3)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.gray, lineWidth: 0.5) // stroke
                                                    .background(RoundedRectangle(cornerRadius: 30).fill(.secondary.opacity(0.1)))
                                            )
                                        
                                        Text("Jumlah Produk :")
                                        Text(String(item.quantity))
                                            .padding(.vertical, 3)
                                            .frame(maxWidth: .infinity)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.gray, lineWidth: 0.5) // stroke
                                                    .background(RoundedRectangle(cornerRadius: 30).fill(.secondary.opacity(0.1))) // fill
                                            )
                                        
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(.secondary.opacity(0.1))
                        .cornerRadius(10)
                        
                        
                        VStack {
                            Text("Add On")
                                .bold()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(.headline)
                            
                            LazyVGrid(columns: columns, spacing: 10) {
                                Group {
                                    
                                    Text("Nama Produk :")
                                    Text(order.addOn!)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding(4)
                                        .lineLimit(10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.gray, lineWidth: 0.5) // stroke
                                                .background(RoundedRectangle(cornerRadius: 30).fill(.secondary.opacity(0.1))) // fill
                                        )
                                    
                                    Text("Jumlah Produk :")
                                    
                                    // CHANGE THIS WITH ADD ON AMOUNT
                                    Text("3")
                                        .padding(.vertical, 3)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.gray, lineWidth: 0.5) // stroke
                                                .background(RoundedRectangle(cornerRadius: 30).fill(.secondary.opacity(0.1))) // fill
                                        )
                                    
                                }
                            }
                        }
                        .padding()
                        .background(.secondary.opacity(0.1))
                        .cornerRadius(10)
                        
                        Text("Referensi Foto")
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top)
                            .font(.title3)
                        
                        let photoURLs = [order.photoUrl1, order.photoUrl2, order.photoUrl3]
                        
                        HStack(spacing: 12) {
                            ForEach(Array(photoURLs.enumerated()), id: \.offset) { index, url in
                                if let url = url, !url.isEmpty {
                                    AsyncImage(url: URL(string: url)) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 115, height: 115)
                                            .clipped()
                                            .cornerRadius(10)
                                    } placeholder: {
                                        ProgressView()
                                            .frame(width: 115, height: 115)
                                    }
                                } else {
                                    VStack {
                                        Image(systemName: "photo.badge.exclamationmark.fill")
                                            .font(.title)
                                            .foregroundColor(.gray)
                                    }
                                    .frame(width: 115, height: 115)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .strokeBorder(style: StrokeStyle(lineWidth: 0.5))
                                            .foregroundStyle(Color.primary)
                                            .background(.gray.opacity(0.1))
                                            .cornerRadius(10)
                                    )
                                }
                            }
                            
                        }
                        
                        Text("Lain - Lain")
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top)
                            .font(.title3)
                        
                        LazyVGrid(columns: columns, spacing: 10) {
                            
                            Text("Pengiriman :")
                            Text(order.opsiPengiriman!)
                                .padding(.vertical, 3)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray, lineWidth: 0.5)
                                        .background(RoundedRectangle(cornerRadius: 30).fill(.secondary.opacity(0.1)))
                                )
                            
                            Text("Notes :")
                            Text(order.notes!)
                                .lineLimit(5)
                                .padding(.vertical, 3)
                            
                                .lineLimit(10)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray, lineWidth: 0.5)
                                        .background(RoundedRectangle(cornerRadius: 10).fill(.secondary.opacity(0.1)))
                                )
                        }
                        
                        
                        Text("Invoice")
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top)
                            .font(.title3)
                        
                        LazyVGrid(columns: columns, spacing: 10) {
                            
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray, lineWidth: 0.5)
                                .frame(height: 200)
                                .shadow(radius: 30)
                            VStack {
                                Text("INV/2025/00001 Nadia Prameswari")
                                
                                
                                Spacer()
                                
                                
                                Label("Bagikan Invoice", systemImage: "square.and.arrow.up")
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .foregroundColor(Color.white)
                                    .cornerRadius(30)
                                    .padding(.horizontal)
                                
                                Spacer()
                                
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                        
                        
                        
                    }
                    .font(.callout)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    
                    Spacer()
                }
                .padding(.bottom,70)
                
                
            }
            
            if let buttonTitle = buttonText(for: order.status) {
                Button {
                    
                    if order.status == "Terkirim" {
                        
                        activeAlert = .payment
                        
                    }
                    else {
                        
                        Task {
                            await handleStatusUpdate()
                        }
                    }
                    
                } label: {
                    Text(buttonTitle)
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .glassEffect(.clear.tint(.blue), in: .rect(cornerRadius: 30))
                        .padding(.horizontal)
                }
            }
            
            if activeAlert != nil {
                CustomAlert(activeAlert: $activeAlert) { status in
                    await handleStatusUpdate(to: status)
                        
                }
            }
            
        }
        .overlay(
            Group {
                if showSuccessToast {
                    VStack {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                            Text("Status updated successfully!")
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                        }
                        .padding()
                        .background(Color.green.opacity(0.9))
                        .cornerRadius(12)
                        .shadow(radius: 5)
                        Spacer()
                    }
                    .padding(.top, 40)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        )
        .navigationTitle("Rincian Pesanan")
        .toolbar {
            if order.status == "Belum Terbayar" || order.status == "Diproses" {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        activeAlert = .cancel
                    } label: {
                        Image(systemName: "trash")
                        //                                .foregroundColor(.red)
                    }
                }
            }
        }
        .task {
            viewModel.configure(userId: session.userId)
            if let userIdString = viewModel.userId {
                await viewModel.fetchBusinessName(for: UUID(uuidString: userIdString))
                await viewModel.fetchOrders(for: UUID(uuidString: userIdString))
                await viewModel.fetchOrderItems(for: UUID(uuidString: userIdString))
            } else {
                print("❌ Passed session.userId invalid or nil")
            }
        }
        
//        .alert(isPresented: .constant(activeAlert != nil)) {
//            switch activeAlert {
//            case .payment:
//                return Alert(
//                    title: Text("Pembeli sudah melunasi pembayaran?"),
//                    message: Text("Jika sudah dibayar penuh, status akan diubah menjadi 'Selesai'."),
//                    primaryButton: .default(Text("Sudah")) {
//                        Task { await handleStatusUpdate(to: "Selesai") }
//                    },
//                    secondaryButton: .cancel(Text("Belum"))
//                )
//
//            case .cancel:
//                return Alert(
//                    title: Text("Batalkan pesanan ini?"),
//                    message: Text("Pesanan yang dibatalkan tidak dapat dipulihkan."),
//                    primaryButton: .destructive(Text("Ya, batalkan")) {
//                        Task { await handleStatusUpdate(to: "Dibatalkan") }
//                    },
//                    secondaryButton: .cancel(Text("Tidak"))
//                )
//
//            case .none:
//                return Alert(title: Text(""))
//            }
//        }


        
    }
    
    private func handleStatusUpdate(to newStatus: String? = nil) async {
        guard let userIdString = session.userId,
              let userId = UUID(uuidString: userIdString) else { return }

        do {
            // Determine next status before the update
            var finalStatus: String

            if let newStatus = newStatus {
                finalStatus = newStatus
                try await SupabaseManager.shared.updateOrderStatus(orderId: order.id, newStatus: newStatus)
                print("✅ Manually updated status to:", newStatus)
            } else {
                // Calculate next step manually just like your viewModel.updateOrderStatus
                switch order.status.lowercased() {
                case "belum terbayar": finalStatus = "Diproses"
                case "diproses": finalStatus = "Terkirim"
                case "terkirim": finalStatus = "Selesai"
                default: return
                }

                try await SupabaseManager.shared.updateOrderStatus(orderId: order.id, newStatus: finalStatus)
                print("✅ Automatically updated status to:", finalStatus)
            }

            // 2️⃣ Refresh all orders
            await viewModel.fetchOrders(for: userId)

            // 3️⃣ Show success toast
            withAnimation { showSuccessToast = true }

            // 4️⃣ Hide toast after delay and handle navigation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation { showSuccessToast = false }

                // 5️⃣ Switch tab based on *new* final status
                if source == .allOrders {
                    switch finalStatus.lowercased() {
                    case "belum terbayar": activeTab = .belumBayar
                    case "diproses": activeTab = .diproses
                    case "terkirim": activeTab = .terkirim
                    case "selesai": activeTab = .selesai
                    case "dibatalkan": activeTab = .dibatalkan
                    default: break
                    }
                }

                // 6️⃣ Dismiss to go back
                dismiss()
            }

        } catch {
            print("❌ Failed to update status:", error.localizedDescription)
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
