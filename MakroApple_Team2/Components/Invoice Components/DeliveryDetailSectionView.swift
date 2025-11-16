//
//  DeliveryDetailSectionView.swift
//  MakroApple_Team2
//
//  Created by Edward Suwandi on 12/11/25.
//

import SwiftUI

struct DeliveryDetailSectionView: View {
    
    var orderDate : String
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Spacer()
            HStack {
                Text("Tanggal Kirim :")
                    .font(.system(size: 10))
                Text(orderDate)
                    .font(.system(size: 10))
                    .underline()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
