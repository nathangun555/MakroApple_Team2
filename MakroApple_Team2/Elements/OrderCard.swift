//
//  OrderCardViewModel.swift
//  MakroApple_Team2
//
//  Created by Edward Suwandi on 13/10/25.
//

import SwiftUI

struct OrderCardView: View {
    
//    let order : Order
    var body: some View {
        
        
        HStack{

            // Indikator
            RoundedRectangle(cornerRadius: 10)
                .frame(width: 6)
                .foregroundColor(.yellow)
                .padding(.vertical, 3)
            
            // Card
            VStack(alignment: .leading){
                
                // Row 1
                HStack{
                    
                    // Nama Customer
                    Text("Nathan Gunawan")
                    
                    Spacer()
                    
                    // Tanggal Pesan
                    Text("20 Sept 2025 18.00")
                    
                    
                    Image(systemName: "chevron.right")
                    
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                
                // Pesanan
                Text("3 Kue Tart")
                    .font(Font.body.bold())
                
                // Tambahan
                Text("+ 3 more")
                    .font(Font.subheadline)
                    .foregroundColor(.secondary)
                
            }
            .padding()
        }
        
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.white.opacity(0.15), Color.yellow.opacity(0.5)]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(10)
        .frame(height: 100)
        .padding(.horizontal, 20)
        
        
       
        
    }
}

#Preview {
    ContentView()
}


