//
//  OrderFormSection.swift
//  MakroApple_Team2
//
//  Created by Assistant on 30/10/25.
//

import SwiftUI

struct OrderFormSection: View {
    let title: String
    @Binding var fields: [OrderField]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            ForEach(Array(fields.enumerated()), id: \.offset) { index, field in
                HStack(spacing: 12) {
                    Text(field.label)
                        .frame(width: 140, alignment: .trailing)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    TextField("Silakan isi kolom", text: Binding(
                        get: { fields[index].value },
                        set: { fields[index].value = $0 }
                    ))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Model
struct OrderField: Identifiable {
    let id = UUID()
    var label: String
    var value: String
}
