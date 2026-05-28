//
//  InvoiceContentView.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 06/11/25.
//

import SwiftUI

struct InvoiceContentView: View {
//    let viewModel: InvoicePreviewViewModel
    var viewModel: InvoiceData
    
    var body: some View {
        VStack(spacing: 12) {
            HeaderSectionView(businessLogoUrl: viewModel.businessLogoUrl, businessName: viewModel.businessName, businessAddress: viewModel.businessAddress, businessPhone: viewModel.businessPhone, businessEmail: viewModel.businessEmail, invoiceNumber: viewModel.invoiceNumber)
            
//            HeaderSectionView(
//                businessLogoUrl: "https://hddpofvkwanymugjtlpp.supabase.co/storage/v1/object/public/MakroAppleTeam2_Bucket/business-logos/3A0A83FE-2480-42F5-82AE-D2A419AAFF89.jpg",
//                businessName: "Toko Subur",
//                businessAddress: "Ngagel Jaya",
//                businessPhone: "62812345678",
//                businessEmail: "bejo@gmail.com",
//                invoiceNumber: "1234"
//            )
            Divider()
            
            HStack(alignment: .top, spacing: 20) {
                BilledToSectionView(customerName: viewModel.customerName, customerPhone: viewModel.customerPhone)
                Spacer()
                PaymentInfoSection(accountName: viewModel.accountName, accountNumber: viewModel.accountNumber, bankName: viewModel.bankName)
            }
            .padding(.top)
            
            
            HStack(alignment: .top, spacing: 20) {
                RecipientSectionView(recipientName: viewModel.recipientName, recipientPhone: viewModel.recipientPhone, deliveryAddress: viewModel.deliveryAddress)
                Spacer()
                DateInfoSectionView(invoiceDate: viewModel.invoiceDate, invoiceDueDate: viewModel.invoiceDueDate)
            }
            
            Divider()
            
            OrderItemsTableView(displayOrderItem: viewModel.displayOrderItems)
            
            Spacer()
            
            
            HStack(alignment: .bottom) {
                DeliveryDetailSectionView(orderDate: viewModel.orderDate)
                
                TotalSectionView(subtotal: viewModel.subtotal, shippingCost: viewModel.shippingCost, total: viewModel.total, downPayment: viewModel.downPayment)
            }
            
            
            Spacer()
            
            
        }
        .padding(40)
        .frame(width: 595, height: 842)
        .background(
            // White paper with border
            RoundedRectangle(cornerRadius: 0)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                )
                .shadow(radius: 3) // optional shadow
        )
    }
    
    
}

#Preview {
    InvoiceContentView(viewModel: InvoiceData())
        .scaleEffect(0.6)
}
