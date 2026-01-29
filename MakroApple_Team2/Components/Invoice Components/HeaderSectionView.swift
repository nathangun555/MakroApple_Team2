//
//  HeaderSectionView.swift
//  MakroApple_Team2
//
//  Created by Edward Suwandi on 12/11/25.
//

import SwiftUI

struct HeaderSectionView: View {
    
    
    var businessLogoUrl: String
    var businessName : String?
    var businessAddress : String?
    var businessPhone : String?
    var businessEmail : String?
    var invoiceNumber: String
    var url2: URL = URL(string: "https://hddpofvkwanymugjtlpp.supabase.co/storage/v1/object/public/MakroAppleTeam2_Bucket/business-logos/3A0A83FE-2480-42F5-82AE-D2A419AAFF89.jpg") ?? URL(string: "google.com")!
    
    @State private var isLogoLoaded = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            
            if businessLogoUrl.isEmpty {
                
                Text("AMMAR")
                
            } else if let url = URL(string: businessLogoUrl),
                      let imageData = try? Data(contentsOf: url),
                      let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onAppear {
                        if !isLogoLoaded {
                            isLogoLoaded = true
                            print("✅ Logo sudah load")
                        }
                    }
            } else {
                Text("AMMAR")
            }
            
            
            
            
            
            //                AsyncImage(url: url) { image in
            //                        image
            //                            .resizable()
            //                            .aspectRatio(contentMode: .fit)
            //
            //                    } placeholder: {
            ////                        ProgressView()
            //                        Text("Loading...")
            //                    }
            //                    .frame(width: 60, height: 60)
            //                    .clipShape(RoundedRectangle(cornerRadius: 12))
            
            
            
            VStack(alignment: .leading, spacing: 2) {
                Text(businessName ?? "TaskFlow Bakery")
                    .font(.system(size: 25))
                    .fontWeight(.bold)
                
                if let address = businessAddress, !address.isEmpty {
                    Text(address)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
                
                if let phone = businessPhone, !phone.isEmpty {
                    Text(phone)
                        .font(.system(size: 9))
                }
                
                if let email = businessEmail, !email.isEmpty {
                    Text(email)
                        .font(.system(size: 9))
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 0) {
                Text("INVOICE")
                    .font(.system(size: 24, weight: .bold))
                    .tracking(1)
                
                Text("Invoice Code : \(invoiceNumber)")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
        }
    }
}
//#Preview {
//    HeaderSectionView(businessLogoUrl: "https://hddpofvkwanymugjtlpp.supabase.co/storage/v1/object/public/MakroAppleTeam2_Bucket/business-logos/3A0A83FE-2480-42F5-82AE-D2A419AAFF89.jpg", businessName: "Toko Subur", businessAddress: "Ngagel Jaya", businessPhone: "62812345678", businessEmail: "bejo@gmail.com", invoiceNumber: "1234")
//}

#Preview("Valid URL loads image") {
    HeaderSectionView(
        businessLogoUrl: "https://hddpofvkwanymugjtlpp.supabase.co/storage/v1/object/public/MakroAppleTeam2_Bucket/business-logos/3A0A83FE-2480-42F5-82AE-D2A419AAFF89.jpg",
        businessName: "Toko Subur",
        businessAddress: "Ngagel Jaya",
        businessPhone: "62812345678",
        businessEmail: "bejo@gmail.com",
        invoiceNumber: "1234"
    )
    .previewLayout(.sizeThatFits)
    .padding()
}

#Preview("Broken URL shows Progress then fallback") {
    HeaderSectionView(
        businessLogoUrl: "https://example.com/404.jpg",
        businessName: "Toko Subur",
        businessAddress: "Ngagel Jaya",
        businessPhone: "62812345678",
        businessEmail: "bejo@gmail.com",
        invoiceNumber: "1234"
    )
    .previewLayout(.sizeThatFits)
    .padding()
}

#Preview("Empty URL uses system placeholder") {
    HeaderSectionView(
        businessLogoUrl: "",
        businessName: "Toko Subur",
        businessAddress: "Ngagel Jaya",
        businessPhone: "62812345678",
        businessEmail: "bejo@gmail.com",
        invoiceNumber: "1234"
    )
    .previewLayout(.sizeThatFits)
    .padding()
}
