//
//  AllOrdersView.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 10/10/25.
//

import SwiftUI

struct AllOrdersView: View {
    
    //    let orders: [Order] = []
    @SceneStorage("selectedTab") var selectedTab = 0
    @State private var searchText = ""
    @State private var selectedSegment = "Unpaid"
    let segments = ["Unpaid", "On Going", "Done", "Cancelled"]
    
    var body: some View {
        
        NavigationView{
            
            VStack{
                
                HStack{
                    
                    Spacer()
                    
                    // Card Left
                    VStack(alignment: .leading){
                        Text("Today's Order")
                        Spacer()
                        Text("38")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: 120)
                    .background(Color.green.opacity(0.8))
                    .cornerRadius(20)
                    
                    Spacer()
                    
                    // Info Card Right
                    VStack(alignment: .leading){
                        Text("Unpaid Orders")
                        Spacer()
                        Text("12")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: 120)
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(20)
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                // Segmented Control
                Picker("Filter", selection: $selectedSegment) {
                    ForEach(segments, id: \.self) { segment in
                        Text(segment)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top)
                
                // Order Lists
                ScrollView{
                    VStack{
                        ForEach(0..<10) { _ in
                            OrderCardView()
                        }
                        
                    }
                }
            }
            // Use line 84 to remove the search bar under navigation title
            //            .searchable(text: $searchText)
            .isSearchable(selectedTab: selectedTab, filter: $searchText)
            .navigationTitle("Hi, Petito Recipe !")
            
        }
    }
}

#Preview {
    AllOrdersView()
}

// Struct and Extension to remove the search bar under the navigation title,
// NOTE : Change to the real data filter later, code below is only a dummy.
struct IsSearchableModifier: ViewModifier {
    
    let selectedTab: Int
    @Binding var filter: String
    
    func body(content: Content) -> some View {
        if selectedTab == 4 {
            content
                .searchable(text: $filter)
        }
        else {
            content
        }
    }
}

extension View {
    func isSearchable(selectedTab: Int, filter: Binding<String>) -> some View {
        self.modifier(IsSearchableModifier(selectedTab: selectedTab, filter: filter))
    }
}
