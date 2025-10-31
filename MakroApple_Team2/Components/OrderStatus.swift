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
            if order.downPayment != nil {
                Text("DP")
                    .font(.caption)
                    .bold()
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .stroke(Color.orange, lineWidth: 2)
                            .background(Circle().fill(order.statusColor))
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
                        .stroke(order.statusColor, lineWidth: 2)
                )
        )
        .padding(.horizontal)
        .padding(.bottom)
    }
}
