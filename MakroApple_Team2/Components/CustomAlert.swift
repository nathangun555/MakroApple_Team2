//
//  CustomAlert.swift
//  MakroApple_Team2
//
//  Created by Edward Suwandi on 31/10/25.
//

import SwiftUI

enum CustomAlertType {
    case payment
    case cancel
    case reorder
    case deleteSetting
    case changeSetting
    case firstTimeOrder
}


struct CustomAlert: View {
    
    @Binding var activeAlert: CustomAlertType?
    let handleStatusUpdate: (String) async -> Void
    
    var body: some View {
        
        if let activeAlert = activeAlert {
            ZStack {
                
                ZStack {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()

                    Rectangle()
                        .fill(Color.black.opacity(0.6))
                        .ignoresSafeArea()
                }
                .onTapGesture {
                    withAnimation(.spring()) {
                        self.activeAlert = nil
                    }
                }

                
                // Alert Box
                VStack {
                    switch activeAlert {
                        
                    case .payment:
                        PaymentContent()
                        
                        
                    case .cancel:
                        CancelContent()
                        
                    case .reorder:
                        ReorderContent()
                        
                        
                    case .deleteSetting:
                        DeleteSettingContent()
                        
                    case .changeSetting:
                        ChangeSettingContent()
                        
                    case .firstTimeOrder:
                        FirstTimeOrderContent()
                        
                    }
                    
                    // Confirmation Button
                    HStack {
                        
                        Button("Tidak") {
                            withAnimation(.spring()) {
                                self.activeAlert = nil
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(Color.white)
                        .glassEffect(.clear.tint(.gray), in: .rect(cornerRadius: 30))
                        
                        // Confirm button
                        Button("Ya") {
                            withAnimation(.spring()) {
                                self.activeAlert = nil
                            }
                            Task {
                                switch activeAlert {
                                case .payment: await handleStatusUpdate("Selesai")
                                case .cancel: await handleStatusUpdate("Dibatalkan")
                                case .reorder: await handleStatusUpdate("Belum Terbayar")
                                    
                                case .deleteSetting:
                                    await print("HALO")
                                    
                                case .changeSetting:
                                    await print("HALO")
                                    
                                case .firstTimeOrder:
                                    await print("HALO")
                                    
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(Color.white)
                        .glassEffect(.clear.tint(.primaryButton), in: .rect(cornerRadius: 30))
                    }
                    
                }
                .padding()
                .frame(maxWidth: 350)
                .background(.white)
                .cornerRadius(10)
                .shadow(radius: 10)
                .transition(.scale.combined(with: .opacity))
            }
            
        }
    }
}

struct PaymentContent: View {
    var body: some View {
        VStack {
            Image(systemName: "checkmark.rectangle.stack.fill")
                .font(.title)
                .foregroundColor(.primaryButton)
                .padding(.top, 5)
            
            Text("Pesanan Selesai")
                .font(.headline)
                .padding(3)
            
            Text("Apakah Anda yakin pesanan ini sudah dibayar lunas dan diterima oleh customer? Pesanan akan dipindahkan ke section Selesai.")
                .font(.caption)
                .padding(.bottom)
                .multilineTextAlignment(.center)
        }
    }
}

struct CancelContent: View {
    var body: some View {
        VStack {
            // Image Icon
            Image(systemName: "xmark.bin.fill")
                .font(.title)
                .foregroundColor(.primaryButton)
                .padding(.top, 5)
            
            Text("Batalkan Pesanan")
                .font(.headline)
                .padding(3)
            
            
            Text("Apakah Anda yakin ingin membatalkan pesanan ini? Pesanan akan dipindahkan ke bagian dibatalkan.")
                .font(.caption)
                .padding(.bottom)
                .multilineTextAlignment(.center)
        }
    }
}

struct ReorderContent: View {
    var body: some View {
        VStack {
            // Image Icon
            Image(systemName: "basket.fill")
                .font(.title)
                .foregroundColor(.primaryButton)
                .padding(.top, 5)
            
            Text("Pesan Kembali Pesanan")
                .font(.headline)
                .padding(3)
            
            Text ("Sistem akan membuat ulang pesanan dan memindahkannya ke status Belum Dibayar.")
                .font(.caption)
                .padding(.bottom)
                .multilineTextAlignment(.center)
        }
    }
}

struct DeleteSettingContent: View {
    var body: some View {
        VStack {
            // Image Icon
            Image(systemName: "trash.fill")
                .font(.title)
                .foregroundColor(.primaryButton)
                .padding(.top, 5)
            
            Text("Hapus")
                .font(.headline)
                .padding(3)
            
            Text ("Apakah Anda yakin ingin menghapus bagian ini?")
                .font(.caption)
                .padding(.bottom)
                .multilineTextAlignment(.center)
        }
    }
}

struct ChangeSettingContent: View {
    var body: some View {
        VStack {
            // Image Icon
            Image(systemName: "gear.badge.xmark")
                .font(.title)
                .foregroundColor(.primaryButton)
                .padding(.top, 5)
            
            Text("Perubahan Belum Disimpan")
                .font(.headline)
                .padding(3)
            
            Text ("Sistem akan membuat ulang pesanan dan memindahkannya ke status Belum Dibayar.")
                .font(.caption)
                .padding(.bottom)
                .multilineTextAlignment(.center)
        }
    }
}

struct FirstTimeOrderContent: View {
    var body: some View {
        VStack {
            // Image Icon
            Image(systemName: "building.2.crop.circle.fill")
                .font(.title)
                .foregroundColor(.primaryButton)
                .padding(.top, 5)
            
            Text("Lengkapi Data Bisnis Anda")
                .font(.headline)
                .padding(3)
            
            Text ("Untuk menambahkan pesanan pertama Anda, lengkapi terlebih dahulu data bisnis yang diperlukan.")
                .font(.caption)
                .padding(.bottom)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    @State var activeAlert: CustomAlertType? = .payment
    
    return CustomAlert(
        activeAlert: $activeAlert,
        handleStatusUpdate: { status in
            print("Status updated to \(status)")
            return
        }
    )
}
