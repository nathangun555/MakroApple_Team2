//
//  OrderStatus.swift
//  MakroApple_Team2
//
//  Created by Edward Suwandi on 30/10/25.
//

import SwiftUI

struct OrderStatus: View {
    let order: OrderRecord
    
    var body: some View {
        HStack {
            if order.downPayment != nil && (order.downPayment!) > 0 {
                Text("DP")
                    .font(.caption)
                    .bold()
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(
                        ZStack {
                            Circle()
                                .fill(statusColors[order.status] ?? .gray) // background fill
                            Circle()
                                .stroke(statusColors[order.status] ?? .gray, lineWidth: 2) // visible stroke
                        }
                    )
            }
            Spacer()
            Text(order.status)
            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 5)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(statusColors[order.status] ?? .gray, lineWidth: 2)
                )
        )
        .padding(.horizontal)
        .padding(.bottom)
    }
}
