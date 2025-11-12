//
//  File.swift
//  MakroApple_Team2
//
//  Created by Edward Suwandi on 12/11/25.
//

import SwiftUI
    // MARK: - Payment Info Section
struct  PaymentInfoSection: View {
    
    var accountName : String
    var accountNumber : String
    var bankName : String
    
    var body: some View{
        

        
        
        VStack(alignment: .trailing, spacing: 4) {
            Text("Informasi Pembayaran")
                .font(.system(size: 15, weight: .bold))
            Divider()
                .frame(maxWidth: 210)
            
            Text(accountName)
                .font(.system(size: 10))
            
            Text(accountNumber)
                .font(.system(size: 10))
            
            Text(bankName)
                .font(.system(size: 10))
        }
    }
}
