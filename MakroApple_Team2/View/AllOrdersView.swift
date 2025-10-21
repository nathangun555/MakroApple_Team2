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
    
    @State private var scrollOffset: CGFloat = 0
    @State private var topInset: CGFloat = 0
    @State private var startTopInset: CGFloat = 0
    
    @State var activeTab: TabModel = .belumBayar
    
    @State private var distance = 0
    var body: some View {
        NavigationView{
            ScrollView{
                LazyVStack(pinnedViews: [.sectionHeaders]) {
                    
                    VStack{
                        
                        // Business Name
                        Text("Hi, Bake Buddy !")
                            .font(Font.largeTitle)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                        
                        // Deadline Card
                        DeadlineCard()
                        
                    }
                    
                    // Sticky Header for Custom Tab Bar
                    Section(
                        header:
                            VStack(spacing: 0){
                                
                                // Custom Tab Bar
                                CustomTabBar(activeTab: $activeTab)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical)
                            }
                    )
                    {
                        // Order Cards
                        ForEach(0..<10) { _ in
                            OrderCardView()
                            
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            
            
        }
        .isSearchable(selectedTab: selectedTab, filter: $searchText)
        
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
                .searchable(text: $filter, prompt: "Cari Nama atau Pesanan")
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
