//
//  OrderEmptyState.swift
//  MakroApple_Team2
//
//  Created by Edward Suwandi on 25/11/25.
//

import SwiftUI


struct OrderEmptyState: View {
    var body: some View {
        VStack {
            Image(systemName: "book.pages.fill")
                .font(.title)
                .foregroundColor(.primaryButton)
                .padding(12)
                .background(
                    Circle()
                        .fill(Color.primaryButton.opacity(0.1))
                )

                    Text("Belum Ada Pesanan")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("Belum ada pesanan yang tercatat.\nTambah pesanan baru untuk mulai kelola penjualanmu dengan mudah.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
    }
}
