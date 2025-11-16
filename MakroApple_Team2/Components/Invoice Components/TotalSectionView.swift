//
//  Untitled.swift
//  MakroApple_Team2
//
//  Created by Edward Suwandi on 12/11/25.
//

import SwiftUI

struct TotalSectionView : View {
    
    var subtotal : Decimal
    var shippingCost : Decimal
    var total : Decimal
    var downPayment : Decimal
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Subtotal")
                    .font(.system(size: 10))
                Spacer()
                Text("Rp. \(subtotal.formatted())")
                    .font(.system(size: 10))
            }
            
            Divider()
            
            HStack {
                Text("Ongkir")
                    .font(.system(size: 10))
                Spacer()
                Text("Rp. \(shippingCost.formatted())")
                    .font(.system(size: 10))
            }
            
            Divider()
            
            HStack {
                Text("Total")
                    .font(.system(size: 10, weight: .bold))
                Spacer()
                Text("Rp. \(total.formatted())")
                    .font(.system(size: 10, weight: .bold))
            }
            
            Divider()
            
            HStack {
                Text("Down Payment")
                    .font(.system(size: 10))
                Spacer()
                Text("Rp. \(downPayment.formatted())")
                    .font(.system(size: 10))
            }
        }
        .frame(maxWidth: 250)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.horizontal, 6)
    }
}
