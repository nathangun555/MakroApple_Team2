//
//  InvoiceContentView.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 06/11/25.
//

import SwiftUI

struct InvoiceContentView: View {
    let viewModel: InvoicePreviewViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            headerSection
            
            Divider()
            
            HStack(alignment: .top, spacing: 20) {
                billedToSection
                Spacer()
                paymentInfoSection
            }
            
            Divider()
            
            HStack(alignment: .top, spacing: 20) {
                recipientSection
                Spacer()
                dateInfoSection
            }
            
            Divider()

            orderItemsTable
            
            Spacer(minLength: 30)
            
            totalsSection
            
            Spacer(minLength: 40)
            
            deliveryDetailsSection
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray5))
                .frame(width: 60, height: 60)
                .overlay(
                    Text("LOGO")
                        .font(.system(size: 8))
                        .foregroundColor(.gray)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.userRecord?.businessName ?? "TaskFlow Bakery")
                    .font(.system(size: 14, weight: .bold))
                
                if let address = viewModel.userRecord?.businessAddress, !address.isEmpty {
                    Text(address)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
                
                if let phone = viewModel.userRecord?.businessPhone, !phone.isEmpty {
                    Text(phone)
                        .font(.system(size: 9))
                }
                
                if let email = viewModel.userRecord?.businessEmail, !email.isEmpty {
                    Text(email)
                        .font(.system(size: 9))
                }
            }
            
            Spacer()

            VStack(alignment: .trailing, spacing: 0) {
                Text("INVOICE")
                    .font(.system(size: 24, weight: .bold))
                    .tracking(1)
                
                Text("Invoice Code : \(viewModel.invoiceNumber)")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Billed To Section
    private var billedToSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Ditagihkan Ke")
                .font(.system(size: 11, weight: .bold))
                .underline()
            
            Text(viewModel.customerName)
                .font(.system(size: 10))
                .italic()
            
            Text(viewModel.customerPhone)
                .font(.system(size: 10))
                .italic()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Payment Info Section
    private var paymentInfoSection: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("Informasi Pembayaran")
                .font(.system(size: 11, weight: .bold))
                .underline()
            
            Text(viewModel.accountName)
                .font(.system(size: 10))
            
            Text(viewModel.accountNumber)
                .font(.system(size: 10))
            
            Text(viewModel.bankName)
                .font(.system(size: 10))
        }
    }

    // MARK: - Recipient Section
    private var recipientSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Informasi Penerima")
                .font(.system(size: 11, weight: .bold))
                .underline()
            
            Text(viewModel.recipientName)
                .font(.system(size: 10))
                .italic()
            
            Text(viewModel.recipientPhone)
                .font(.system(size: 10))
                .italic()
            
            Text(viewModel.deliveryAddress)
                .font(.system(size: 10))
                .italic()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Date Info Section
    private var dateInfoSection: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("Informasi Tanggal")
                .font(.system(size: 11, weight: .bold))
                .underline()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("Tanggal Invoice : \(viewModel.invoiceDate)")
                    .font(.system(size: 10))
                
                Text("Jatuh Tempo Pembayaran : \(viewModel.invoiceDueDate)")
                    .font(.system(size: 10))
            }
            
            Text("Pesanan akan otomatis dibatalkan jika melewati tanggal jatuh tempo.")
                .font(.system(size: 7))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 150)
        }
    }

    // MARK: - Order Items Table
    private var orderItemsTable: some View {
        VStack(spacing: 0) {
            // Table Header
            HStack {
                Text("Deskripsi Barang")
                    .font(.system(size: 10, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Harga satuan")
                    .font(.system(size: 10, weight: .bold))
                    .frame(width: 70)
                
                Text("Jumlah")
                    .font(.system(size: 10, weight: .bold))
                    .frame(width: 50)
                
                Text("Total Harga")
                    .font(.system(size: 10, weight: .bold))
                    .frame(width: 70, alignment: .trailing)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
            .background(Color(.systemGray5))
            
            ForEach(viewModel.displayOrderItems) { item in
                VStack(spacing: 0) {
                    HStack {
                        Text(item.description)
                            .font(.system(size: 10))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(item.unitPrice.formatted())
                            .font(.system(size: 10))
                            .frame(width: 70)
                        
                        Text("\(item.quantity)")
                            .font(.system(size: 10))
                            .frame(width: 50)
                        
                        Text(item.total.formatted())
                            .font(.system(size: 10))
                            .frame(width: 70, alignment: .trailing)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 6)
                    
                    Divider()
                }
            }
        }
    }

    // MARK: - Totals Section
    private var totalsSection: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Subtotal")
                    .font(.system(size: 10))
                Spacer()
                Text(viewModel.subtotal.formatted())
                    .font(.system(size: 10))
            }
            
            Divider()
            
            HStack {
                Text("Ongkir")
                    .font(.system(size: 10))
                Spacer()
                Text(viewModel.shippingCost.formatted())
                    .font(.system(size: 10))
            }
            
            Divider()
            
            HStack {
                Text("Total")
                    .font(.system(size: 10, weight: .bold))
                Spacer()
                Text(viewModel.total.formatted())
                    .font(.system(size: 10, weight: .bold))
            }
            
            Divider()
            
            HStack {
                Text("Down Payment")
                    .font(.system(size: 10))
                Spacer()
                Text(viewModel.downPayment.formatted())
                    .font(.system(size: 10))
            }
        }
        .frame(maxWidth: 250)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.horizontal, 6)
    }

    // MARK: - Delivery Details Section
    private var deliveryDetailsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Tanggal Kirim :")
                    .font(.system(size: 10))
                Text(viewModel.orderDate.isEmpty ? "" : viewModel.orderDate)
                    .font(.system(size: 10))
                    .underline()
            }
            
            HStack {
                Text("Jam Kirim :")
                    .font(.system(size: 10))
                Text(viewModel.deliveryTime.isEmpty ? "" : viewModel.deliveryTime)
                    .font(.system(size: 10))
                    .underline()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
