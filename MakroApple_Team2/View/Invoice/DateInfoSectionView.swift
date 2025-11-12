//
//  DateInfoSectionView.swift
//  MakroApple_Team2
//
//  Created by Edward Suwandi on 12/11/25.
//

import SwiftUI

struct DateInfoSectionView: View {
    
    var invoiceDate: String
    var invoiceDueDate: String
    
    
    
    var body: some View {
       
        VStack(alignment: .trailing, spacing: 4) {
            Text("Informasi Tanggal")
                .font(.system(size: 15, weight: .bold))
            
            Divider()
            .frame(maxWidth: 210)
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("Tanggal Invoice : \(DateFormatterHelper.formattedDate(invoiceDate, showTime: false))")
                    .font(.system(size: 10))
                
                Text("Jatuh Tempo Pembayaran : \(DateFormatterHelper.formattedDate(invoiceDueDate, showTime: false))")
                    .font(.system(size: 10))
            }
            
            Text("Pesanan akan otomatis dibatalkan jika melewati tanggal jatuh tempo.")
                .font(.system(size: 7))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 150)
        }
        
    }
}
