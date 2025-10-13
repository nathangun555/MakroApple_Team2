//
//  AllOrdersView.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 10/10/25.
//

import SwiftUI

struct AllOrdersView: View {
    
    @State private var searchText = ""
    
    var body: some View {
        NavigationView{
            List{
                
            }
            .searchable(text: $searchText)
        }
    }
}

#Preview {
    AllOrdersView()
}
