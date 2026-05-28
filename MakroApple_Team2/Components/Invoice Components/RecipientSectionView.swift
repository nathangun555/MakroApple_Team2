//
//  RecipientSectionView.swift
//  MakroApple_Team2
//
//  Created by Edward Suwandi on 12/11/25.
//

import SwiftUI

struct RecipientSectionView: View {
    
    var recipientName : String
    var recipientPhone : String
    var deliveryAddress : String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Informasi Penerima")
                .font(.system(size: 15, weight: .bold))
            
            Divider()
            .frame(maxWidth: 150)
            
            Text(recipientName)
                .font(.system(size: 10))
            
            Text(recipientPhone)
                .font(.system(size: 10))
            
            Text(deliveryAddress)
                .font(.system(size: 10))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
