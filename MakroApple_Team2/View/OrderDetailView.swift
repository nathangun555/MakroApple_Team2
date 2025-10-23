//
//  OrderDetailView.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 14/10/25.
//

import SwiftUI

struct OrderDetailView: View {
//    let order: Order
    let order: OrderRecord
    let orderItem: [OrderItemRecord]
    
    private func currency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "IDR"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "Rp \(value)"
    }

    var body: some View {
        
        ZStack(alignment: .bottom){
            
            ScrollView {
                
                VStack{
                    
                    // Status
                    Text("Belum Bayar")
                        .padding(.vertical, 5)
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .cornerRadius(30)
                        .padding(.horizontal)
                    
                    
                    
                    
                    
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
                                            .background(RoundedRectangle(cornerRadius: 30).fill(Color.white)) // fill
                                    )
                                
                                
                                Text("No. Telp Pemesan :")
                                Text(order.customerOrderPhone!)
                                    .padding(.vertical, 3)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray, lineWidth: 0.5) // stroke
                                            .background(RoundedRectangle(cornerRadius: 30).fill(Color.white)) // fill
                                    )
                                
                                Text("Nama Penerima :")
                                Text(order.customerReceiverName!)
                                    .padding(.vertical, 3)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray, lineWidth: 0.5) // stroke
                                            .background(RoundedRectangle(cornerRadius: 30).fill(Color.white)) // fill
                                    )
                                
                                Text("No. Telp Penerima :")
                                Text(order.customerReceiverPhone!)
                                    .padding(.vertical, 3)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray, lineWidth: 0.5) // stroke
                                            .background(RoundedRectangle(cornerRadius: 30).fill(Color.white)) // fill
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
                                            .background(RoundedRectangle(cornerRadius: 30).fill(Color.white)) // fill
                                    )
                                
                                Text("Jam Kirim :")
                                Text("\(DateFormatterHelper.formattedTime(order.orderDdayDate!)) WIB")
                                    .padding(.vertical, 3)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray, lineWidth: 0.5) // stroke
                                            .background(RoundedRectangle(cornerRadius: 30).fill(Color.white)) // fill
                                    )
                                
                                
                            }
                        }
                        
                        Text("Rincian Pesanan")
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top)
                            .font(.title3)
                        
                        ForEach(orderItem) { item in
                            
                            // CHANGE THIS LATER WITH PRODUCT CATEGORY
                            Text(item.productType)
                                .bold()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top)
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
                                                .background(RoundedRectangle(cornerRadius: 30).fill(Color.white)) // fill
                                        )
                                    
                                    Text("Jumlah Produk :")
                                    Text(String(item.quantity))
                                        .padding(.vertical, 3)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.gray, lineWidth: 0.5) // stroke
                                                .background(RoundedRectangle(cornerRadius: 30).fill(Color.white)) // fill
                                        )
                                    
                                }
                            }
                        }
                        
                        
                        Text("Add On")
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top)
                            .font(.title3)
                        
                        
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
                                            .background(RoundedRectangle(cornerRadius: 30).fill(Color.white)) // fill
                                    )
                                
                                Text("Jumlah Produk :")
                                
                                // CHANGE THIS WITH ADD ON AMOUNT
                                Text("3")
                                    .padding(.vertical, 3)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray, lineWidth: 0.5) // stroke
                                            .background(RoundedRectangle(cornerRadius: 30).fill(Color.white)) // fill
                                    )
                                
                            }
                        }
                        
                        
                        
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
                                        .stroke(Color.gray, lineWidth: 0.5) // stroke
                                        .background(RoundedRectangle(cornerRadius: 30).fill(Color.white)) // fill
                                )
                            
                            Text("Notes :")
                            Text(order.notes!)
                                .lineLimit(5)
                                .padding(.vertical, 3)
                            
                                .lineLimit(10)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray, lineWidth: 0.5) // stroke
                                        .background(RoundedRectangle(cornerRadius: 30).fill(Color.white)) // fill
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
                                
                                
                                Text("Bagikan Invoice")
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .glassEffect(.regular)
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
            Button(action : {
                print("tapped")
            }) {
                Text("Lanjut")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .glassEffect(.clear.tint(.blue))
                    .padding(.horizontal)
            }
        }
//            .background(Color.white.ignoresSafeArea())
//            .padding(.bottom, 70)
            
        
        
        
            
        
        .navigationTitle("Rincian Pesanan")
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

