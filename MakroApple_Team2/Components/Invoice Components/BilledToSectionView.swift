//
//  File.swift
//  MakroApple_Team2
//
//  Created by Edward Suwandi on 12/11/25.
//
import SwiftUI

// MARK: - Billed To Section
struct BilledToSectionView: View {
    var customerName: String
    var customerPhone: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Ditagihkan Ke")
                .font(.system(size: 15, weight: .bold))
            
            Divider()
                .frame(maxWidth: 150)
            
            Text(customerName)
                .font(.system(size: 10))
            
            Text(customerPhone)
                .font(.system(size: 10))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
