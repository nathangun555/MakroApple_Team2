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
    
    @State private var activeAlert: CustomAlertType?
    
    @State private var viewModel = AllOrdersViewModel()
    @State private var invoiceViewModel = InvoicePreviewViewModel()
    @EnvironmentObject var session: SessionManager
    @State var order: OrderRecord
    let orderItem: [OrderItemRecord]
    
    
    @State private var showSuccessToast = false
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPDFURL: URL?
    @State private var showPDFViewer = false
    
    let source: OrderSource
    
    
    @Binding var activeTab: TabModel

    private var userIdString: String? { session.userId }
    
    
    
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
        case "Dibatalkan" :
            return "Pesan Kembali"
        default:
            return nil
        }
    }
    
    
    var body: some View {
        
        ZStack(alignment: .bottom){
            
            ScrollView {
                
                VStack{
                    
                    OrderStatus(order: order)
                    
                    
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
                                            .background(
                                                Rectangle()
                                                .fill(.secondary.opacity(0.1))) // fill
                                    )
                                
                                
                                Text("No. Telp Pemesan :")
                                Text("\(order.customerOrderPhone?.isEmpty == true ? "-" : order.customerOrderPhone!)")
                                    .padding(.vertical, 3)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray, lineWidth: 0.5) // stroke
                                            .background(
                                                Rectangle()
                                                    .fill(.secondary.opacity(0.1))) // fill
                                    )
                                
                                Text("Nama Penerima :")
                                Text(order.customerReceiverName ?? "-")
                                    .padding(.vertical, 3)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray, lineWidth: 0.5) // stroke
                                            .background(
                                                Rectangle()
                                                    .fill(.secondary.opacity(0.1))) // fill
                                    )
                                
                                Text("No. Telp Penerima :")
                                Text(order.customerReceiverPhone ?? "-")
                                    .padding(.vertical, 3)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray, lineWidth: 0.5) // stroke
                                            .background(
                                                Rectangle()
                                                    .fill(.secondary.opacity(0.1))) // fill
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
                                
                                Text(DateFormatterHelper.formattedDate(order.orderDdayDate ?? "-"))
                                    .padding(.vertical, 3)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray, lineWidth: 0.5) // stroke
                                            .background(
                                                Rectangle()
                                                    .fill(.secondary.opacity(0.1))) // fill
                                    )
                                
                                Text("Jam Kirim :")
                                Text("\(DateFormatterHelper.formattedTime(order.orderDdayDate ?? "g")) WIB")
                                    .padding(.vertical, 3)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray, lineWidth: 0.5)
                                            .background(
                                                Rectangle()
                                                    .fill(.secondary.opacity(0.1)))
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
                                
                                VStack{
                                    
                                    LazyVGrid(columns: columns, spacing: 10) {
                                        Group {
                                            Text("Nama Produk :")
                                            Text("\(item.productName.isEmpty == true ? "-" : item.productName)")
                                                .frame(maxWidth: .infinity, alignment: .center)
                                                .padding(4)
                                                .lineLimit(10)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(Color.gray, lineWidth: 0.5) // stroke
                                                        .background(
                                                            Rectangle()
                                                                .fill(.secondary.opacity(0.1)))
                                                )
                                            
                                            Text("Jumlah Produk :")
                                            Text(String(item.quantity) ?? "-")
                                                .padding(.vertical, 3)
                                                .frame(maxWidth: .infinity)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(Color.gray, lineWidth: 0.5) // stroke
                                                        .background(
                                                            Rectangle()
                                                                .fill(.secondary.opacity(0.1))) // fill
                                                )
                                            
                                        }
                                    }
                                }.padding()
                                    .background(.secondary.opacity(0.1))
                                    .cornerRadius(10)
                                
                            }
                        }
                        
                        
                        Text("Referensi Foto")
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top)
                            .font(.title3)
                        
                        let photoURLs = [order.photoUrl1, order.photoUrl2, order.photoUrl3]
                            .compactMap { $0 }
                            .filter { !$0.isEmpty }
                        
                        
                        HStack(spacing: 12) {
                            if photoURLs.isEmpty {
                                // Show placeholder when there are no photos at all
                                VStack {
                                    Image(systemName: "photo.badge.exclamationmark.fill")
                                        .font(.title)
                                        .foregroundColor(.gray)
                                    Text("No photos")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .frame(width: 115, height: 115)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(style: StrokeStyle(lineWidth: 0.5))
                                        .foregroundStyle(Color.primary)
                                        .background(.gray.opacity(0.1))
                                        .cornerRadius(10)
                                )
                                
                                
                            } else {
                                ForEach(photoURLs, id: \.self) { url in
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
                                }
                            }

                            Spacer()
                        }
                        
                        Text("Lain - Lain")
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top)
                            .font(.title3)
                        
                        LazyVGrid(columns: columns, spacing: 10) {
                            
                            Text("Pengiriman :")
                            Text("\(order.opsiPengiriman?.isEmpty == true ? "-" : order.opsiPengiriman!)")
                                .padding(.vertical, 3)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray, lineWidth: 0.5)
                                        .background(RoundedRectangle(cornerRadius: 30).fill(.secondary.opacity(0.1)))
                                )
                            
                            Text("Notes :")

                            Text("\(order.notes?.isEmpty == true ? "-" : order.notes!)")
                                .lineLimit(5)
                                .padding(5)
                            
                                .lineLimit(10)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray, lineWidth: 0.5)
                                        .background(RoundedRectangle(cornerRadius: 10).fill(.secondary.opacity(0.1)))
                                )
                        }
                        
                        if let customFields = order.customFields, !customFields.isEmpty {

                            let columns = [
                                GridItem(.fixed(150), alignment: .leading),
                                GridItem(.flexible(), alignment: .trailing)
                            ]

                            LazyVGrid(columns: columns, spacing: 10) {
                                ForEach(customFields.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                    Text("\(key):")
                                    Text("\(value.value ?? "-")")
                                        .padding(.vertical, 3)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.gray, lineWidth: 0.5)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .fill(.secondary.opacity(0.1))
                                                )
                                        )
                                }
                            }
                        }

                        
                        
                        Text("Invoice")
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top)
                            .font(.title3)
                        
                        LazyVGrid(columns: columns, spacing: 5) {
                            
                            if let urlString = order.invoiceUrl,
                                   let pdfURL = URL(string: urlString) {
                                    Button {
                                        // Show PDF preview
                                        activeAlert = nil
                                        showPDFPreview(url: pdfURL)
                                    } label: {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.gray, lineWidth: 0.5)
                                                .frame(height: 200)
                                                .shadow(radius: 30)
                                            
                                            VStack {
                                                Image(systemName: "doc.richtext.fill")
                                                    .font(.system(size: 40))
                                                    .foregroundColor(.blue)
                                                Text("Tap to Preview Invoice")
                                                    .font(.footnote)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                } else {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray, lineWidth: 0.5)
                                            .frame(height: 200)
                                            .shadow(radius: 30)
                                        VStack {
                                            Image(systemName: "doc.text.fill.badge.exclamationmark")
                                                .font(.system(size: 40))
                                                .foregroundColor(.gray)
                                            Text("No Invoice Uploaded")
                                                .font(.footnote)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            
                            
                            VStack (alignment: .leading) {
                                
                                VStack(alignment : .leading){
                                    Text("INV/2025/00001")
                                    Text(order.customerOrderName)
                                    
                                }
                                .font(.body)
                                
                                
                                Button {
                                    if let urlString = order.invoiceUrl,
                                       let remoteURL = URL(string: urlString) {
                                        Task {
                                            do {
                                                // Download the file (same as toolbar behavior)
                                                let (data, _) = try await URLSession.shared.data(from: remoteURL)
                                                let tempURL = FileManager.default.temporaryDirectory
                                                    .appendingPathComponent("invoice_preview.pdf")
                                                try data.write(to: tempURL)

                                                // Use the same sharing logic as toolbar
                                                invoiceViewModel.shareInvoice(items: [tempURL]) { success in
                                                    print(success ? "✅ Shared" : "❌ Failed to share")
                                                }
                                            } catch {
                                                print("❌ Failed to share invoice:", error)
                                            }
                                        }
                                    }
                                } label: {
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundColor(.black)
                                }
                                .buttonStyle(.bordered)
                                .tint(.gray)

                                
                                Spacer()
                                
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
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
                    else if order.status == "Dibatalkan"{
                        activeAlert = .reorder
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
                        .glassEffect(.clear.tint(.primaryButton), in: .rect(cornerRadius: 30))
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
        .onDisappear {
            switch order.status.lowercased() {
            case "belum terbayar": activeTab = .belumBayar
            case "diproses": activeTab = .diproses
            case "terkirim": activeTab = .terkirim
            case "selesai": activeTab = .selesai
            case "dibatalkan": activeTab = .dibatalkan
            default: break
            }
        }
        .sheet(isPresented: $showPDFViewer) {
            NavigationStack {
                if let url = selectedPDFURL {
                    PDFKitView(url: url)
                        .navigationTitle("Invoice Preview")
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button {
                                    if let url = selectedPDFURL {
                                        invoiceViewModel.shareInvoice(items: [url]) { success in
                                            print(success ? "✅ Shared" : "❌ Failed")
                                        }
                                    }
                                } label: {
                                    Image(systemName: "square.and.arrow.up")
                                }
                            }


                        }
                }
            }
        
        }

    }
    private func showPDFPreview(url: URL) {
        if url.isFileURL {
            selectedPDFURL = url
            showPDFViewer = true
            return
        }

        // Detect image files (png/jpg)
        if url.pathExtension.lowercased() == "png" || url.pathExtension.lowercased() == "jpg" {
            print("🖼️ This is an image, not a PDF. Use an Image viewer instead.")
            // Example: show a SwiftUI Image view or custom viewer
            return
        }

        // Otherwise download and preview as PDF
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("invoice_preview.pdf")
                try data.write(to: tempURL)

                await MainActor.run {
                    selectedPDFURL = tempURL
                    showPDFViewer = true
                }
            } catch {
                print("❌ Failed to download PDF:", error)
            }
        }
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
                case "dibatalkan": finalStatus = "Belum Terbayar"
                default: return
                }

                try await SupabaseManager.shared.updateOrderStatus(orderId: order.id, newStatus: finalStatus)
                print("✅ Automatically updated status to:", finalStatus)
            }

            // 2️⃣ Refresh all orders
            await viewModel.fetchOrders(for: userId)
            
            // NEW: update local state
            if let updated = viewModel.orders.first(where: { $0.id == order.id }) {
                self.order = updated
            }

            // 3️⃣ Show success toast
            withAnimation { showSuccessToast = true }

            // 4️⃣ Hide toast after delay and handle navigation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation { showSuccessToast = false }
            }

        } catch {
            print("❌ Failed to update status:", error.localizedDescription)
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
//    let view = AllOrdersView()
//
//    // Inject the environment object
//    return view.environmentObject(session)
//}

