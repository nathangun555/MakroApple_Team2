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
    let sectionType: String   // "customer", "schedule", "other"
    let fieldErrors: Set<String>

    @FocusState private var focusedField: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal)

            ForEach(Array(fields.enumerated()), id: \.offset) { index, field in
                let key = "\(sectionType)-\(index)"

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 12) {
                        Text(field.label)
                            .frame(width: 140, alignment: .trailing)
                            .font(.body)
                            .foregroundColor(.primary)

                        TextField("Silakan isi kolom", text: Binding(
                            get: { fields[index].value },
                            set: { fields[index].value = $0 }
                        ))
                        .focused($focusedField, equals: key) // fokuskan jika error
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.white))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    fieldErrors.contains(key) ? Color.red : Color(.systemGray4),
                                    lineWidth: fieldErrors.contains(key) ? 2 : 1
                                )
                        )
                    }

                    if fieldErrors.contains(key) {
                        HStack {
                            Spacer().frame(width: 140)
                            Text("Field ini wajib diisi")
                                .font(.caption)
                                .foregroundStyle(.red)
                                .padding(.leading, 12)
                            Spacer()
                        }
                    }
                }
                .id(key) // penting: samakan id dengan key error
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
