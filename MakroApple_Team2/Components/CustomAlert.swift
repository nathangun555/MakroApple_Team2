//
//  CustomAlert.swift
//  MakroApple_Team2
//
//  Created by Edward Suwandi on 31/10/25.
//

import SwiftUI

struct CustomAlert: View {
    @Binding var activeAlert: OrderDetailView.ActiveAlert?
    let handleStatusUpdate: (String) async -> Void
    
    var body: some View {
        
        if let activeAlert = activeAlert {
            ZStack {
                
                ZStack {
                    Rectangle()
                        .fill(.ultraThinMaterial) // the blur layer
                        .ignoresSafeArea()

                    Rectangle()
                        .fill(Color.black.opacity(0.6)) // slight black overlay tint
                        .ignoresSafeArea()
                }
                .onTapGesture {
                    withAnimation(.spring()) {
                        self.activeAlert = nil
                    }
                }

                
                // Alert Box
                VStack {
                    
                    // Image Icon
                    Image(systemName: activeAlert == .payment ? "checkmark.rectangle.stack.fill" : "xmark.bin.fill")
                        .font(.title)
                        .foregroundColor(.primaryButton)
                        .padding(.top, 5)
                    
                    // Alert Message
                    if activeAlert == .payment {
                        VStack {
                            Text("Pesanan Selesai")
                                .font(.headline)
                                .padding(3)
                            
                            Text("Apakah Anda yakin pesanan ini sudah dibayar lunas dan diterima oleh customer? Pesanan akan dipindahkan ke section Selesai.")
                                .font(.caption)
                                .padding(.bottom)
                        }
                        .multilineTextAlignment(.center)
                        
                        
                        
                    } else {
                        VStack {
                            Text("Batalkan Pesanan")
                                .font(.headline)
                                .padding(3)
                            
                            
                            Text ("Apakah Anda yakin ingin membatalkan pesanan ini? Pesanan akan dipindahkan ke bagian dibatalkan.")
                                .font(.caption)
                                .padding(.bottom)
                            
                        }
                        .multilineTextAlignment(.center)
                    }
                    // Confirmation Button
                    HStack {
                        Button(activeAlert == .payment ? "Belum" : "Tidak") {
                            withAnimation(.spring()) {
                                self.activeAlert = nil
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(Color.white)
                        .glassEffect(.clear.tint(.gray), in: .rect(cornerRadius: 30))
                        
                        // Confirm button
                        Button(activeAlert == .payment ? "Sudah" : "Ya, batalkan") {
                            withAnimation(.spring()) {
                                self.activeAlert = nil
                            }
                            Task {
                                if activeAlert == .payment {
                                    await handleStatusUpdate("Selesai")
                                } else {
                                    await handleStatusUpdate("Dibatalkan")
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
#Preview {
    // Create a mock alert state for preview
    @State var activeAlert: OrderDetailView.ActiveAlert? = .cancel
    
    CustomAlert(
        activeAlert: $activeAlert,
        handleStatusUpdate: { status in
            print("Status updated to \(status)")
            return
        }
    )
}
