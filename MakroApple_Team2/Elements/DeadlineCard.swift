//
//  DeadlieCard.swift
//  MakroApple_Team2
//
//  Created by Edward Suwandi on 21/10/25.
//

import SwiftUI

struct DeadlineCard: View {
    var body: some View {
        
        // Today's Deadline Card
        VStack(alignment: .leading){
            Text("Deadline Hari Ini")
            Spacer()
            Text("38")
                .font(.largeTitle)
                .fontWeight(.bold)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 100)
        .cornerRadius(30)
        .glassEffect(.regular, in: .rect(cornerRadius:30))
        .padding(.horizontal)
        
    }
}

#Preview {
    DeadlineCard()
}
