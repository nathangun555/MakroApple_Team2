//
//  r.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 27/10/25.
//

import SwiftUI

struct FormSection: View {
    let title: String
    @Binding var fields: [FormFieldItem]
    let onAddColumn: () -> Void
    var showDelete: Bool = false
    var onDelete: ((Int) -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                if title == "Lain - Lain"{
                    Button(action: onAddColumn) {
                        Label("Tambahkan Kolom", systemImage: "plus")
                            .font(.subheadline)
                            .foregroundColor(.primaryButton)
//                            .background(.gray)
                    }
                    .buttonStyle(.bordered)
                    .tint(.gray)
                }
                
            }
            .padding(.horizontal)
            
            ForEach(Array(fields.enumerated()), id: \.offset) { index, field in
                if field.label != "Foto Referensi (optional)" {
                    HStack(spacing: 12) {
                        TextField("", text: Binding(
                                get: { field.label },
                                set: { fields[index].label = $0 }
                            ))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.body)
                            .multilineTextAlignment(.leading)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Text("")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            .foregroundColor(.secondary)
                        
                        if showDelete, let onDelete = onDelete {
                            Button(action: { onDelete(index) }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

#Preview {
    // Dummy binding
    @State var isDismissed = false

    // Dummy environment object
    let session = SessionManager()
    session.userId = "083dc90d-ca03-4f45-a631-06fe21fe750f"

    return NavigationStack {
        EditTemplateFormView(isDismissed: $isDismissed)
            .environmentObject(session)
    }
}
