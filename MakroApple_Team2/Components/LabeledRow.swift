//
//  LabeledRow.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 11/11/25.
//

import SwiftUI

struct LabeledRow<Content: View>: View {
    let label: String
    let labelWidth: CGFloat
    @ViewBuilder var field: () -> Content
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(label)
                .font(.subheadline) // 💡 ganti jadi caption1 sesuai permintaanmu
                .frame(width: labelWidth, alignment: .leading)
            field()
        }
        .padding(.vertical, 6)
    }
}
