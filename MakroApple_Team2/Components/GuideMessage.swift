//
//  GuideMessage.swift
//  MakroApple_Team2
//
//  Created by Edward Suwandi on 03/11/25.
//

import SwiftUI

struct GuideMessage: View {
    
    let activeTab: TabModel
    
    @Binding var isVisible: Bool
    
    var body: some View {
        
        if isVisible{
            VStack(alignment: .leading) {
                
                HStack {
                    
                    switch activeTab {
                    case .belumBayar:
                        Text("Menunggu Pembayaran Customer").bold()
                        
                    case .diproses:
                        Text("Sedang Disiapkan untuk Dikirim").bold()
                        
                    case .terkirim:
                        Text("Dalam Proses Pengiriman").bold()
                        
                    case .selesai:
                        Text("Pesanan Telah Selesai").bold()
                        
                    case .dibatalkan:
                        Text("Pesanan Tidak Diproses Lebih Lanjut").bold()
                        
                    }
                    
                    Spacer()
                    
                    Button(action : {
                        isVisible = false
                    }){
                        Image(systemName: "x.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    
                }
                .font(.footnote)
                .padding(.vertical,4)
                
                
                switch activeTab {
                case .belumBayar:
                    Text("Pesanan sudah dibuat dan invoice telah dikirim ke customer, namun pembayaran belum diterima. Gunakan tahap ini untuk menagih atau mengingatkan customer sebelum tenggat waktu berakhir.")
                    
                case .diproses:
                    Text("Pembayaran telah diterima dan pesanan sedang disiapkan. Semua pesanan di tahap ini juga akan otomatis muncul di tab Kalender sesuai tanggal pengiriman.")
                    
                case .terkirim:
                    Text("Pesanan sudah diserahkan ke kurir dan sedang dalam proses pengiriman menuju customer.")
                    
                case .selesai:
                    Text("Pesanan telah diterima oleh customer dan transaksi dinyatakan lunas.")
                    
                case .dibatalkan:
                    Text("Pesanan dibatalkan karena customer belum melakukan pembayaran hingga melewati tenggat waktu atau membatalkan pesanan melalui chat.")
                    
                }
                
            }
            .font(.caption2)
            .frame(maxWidth: .infinity)
            
            .padding()
            .background(statusColors[activeTab.dbValue]?.opacity(0.20))
            .foregroundColor(.black.opacity(0.50))
            .cornerRadius(10)
            .padding(.horizontal)
            
        }
        
          
    }
}
//
//#Preview {
//    GuideMessage(activeTab: .diproses, isVisible: false)
//}
