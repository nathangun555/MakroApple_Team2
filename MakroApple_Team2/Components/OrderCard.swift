//
//  OrderCardViewModel.swift
//  MakroApple_Team2
//
//  Created by Edward Suwandi on 13/10/25.
//

import SwiftUI

struct OrderCardView: View {
//    let order : Order
    var body: some View {
        
        VStack(alignment: .leading){
            HStack{
                Text("Nathan Gunawan")
                
                Spacer()
                
                VStack{
                    Text("20 Sept 2025 18.00")
                }
            }
            .foregroundColor(.secondary)
            
            Text("3 Kue Tart")
                .font(Font.title.bold())
            
            HStack{
                Text("+ 3 more")
                    .font(Font.subheadline)
                
                
                Spacer()
                Button(action: {
                    
                }) {
                    
                }
                
            }
            .foregroundColor(.secondary)
        }
        
                    .frame(height: 100)
                    .padding(.horizontal)
                    .background(.secondary.opacity(0.10))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.top, 5)
        
//            HStack{
//
//                VStack(alignment: .leading){
//                    HStack{
//                        Text("Nathan Gunawan")
//                            
//                        Spacer()
//                        
//                        VStack{
//                            Text("20 September 2025")
//                        }
//                        
//                    }
//                    .foregroundColor(.secondary)
//                    Spacer()
//                    
//                    VStack(alignment: .leading){
//                        Text("3 Kue Tart")
//                            .font(Font.title.bold())
//                        
//                        HStack{
//                            Text("+ 3 more")
//                                .font(Font.subheadline)
//                                
//                            
//                            Spacer()
//                            Text("18.00")
//
//                        }
//                        .foregroundColor(.secondary)
//                       
//                    }
//                    
//                    
//                }
//                .frame(maxHeight: 70)
//                
//                
//                Spacer()
//                
//                
//            }
//            .frame(height: 100)
//            .padding(.horizontal)
//            .background(.secondary.opacity(0.10))
//            .cornerRadius(10)
//            .padding(.horizontal)
//            .padding(.top, 5)
        
    }
}

#Preview {
    OrderCardView()
}


