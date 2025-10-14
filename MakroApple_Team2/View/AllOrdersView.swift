//
//  AllOrdersView.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 10/10/25.
//

import SwiftUI

struct AllOrdersView: View {
    
//    let orders: [Order] = []
    
    @State private var selectedSegment = "All"
    let segments = ["All", "Pending", "Completed"]
    
    var body: some View {
        
        NavigationView{
            VStack{
                // Segmented control
                Picker("Filter", selection: $selectedSegment) {
                    ForEach(segments, id: \.self) { segment in
                        Text(segment)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
            
            
                ScrollView{
                    VStack{
                        ForEach(0..<10) { _ in
                            OrderCardView()
                        }
                        
                    }
                }
            }
            .navigationTitle("All Orders")
            
        }
    }
}

#Preview {
    AllOrdersView()
}
