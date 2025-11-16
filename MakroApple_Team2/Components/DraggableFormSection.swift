//
//  DraggableFormSection.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 16/11/25.
//

import SwiftUI

struct DraggableFormSection: View {
    let title: String
    @Binding var fields: [FormFieldItem]
    let onAddColumn: () -> Void
    var showDelete: Bool = false
    var onDelete: ((Int) -> Void)? = nil

    // Controls edit mode for drag
    @State private var editMode: EditMode = .active // default: always draggable. Use .inactive for manual toggle

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Button(action: onAddColumn) {
                    Label("Tambahkan Kolom", systemImage: "plus")
                        .font(.subheadline)
                        .foregroundColor(.primaryButton)
                }
                .buttonStyle(.bordered)
                .tint(.gray)
            }
            .padding(.horizontal)

            // List with .onMove for drag
            List {
                ForEach(Array(fields.enumerated()), id: \.offset) { index, field in
                    if field.label != "Foto Referensi (optional)" {
                        HStack(spacing: 12) {
                            TextField(
                                "",
                                text: Binding(
                                    get: { fields[index].label },
                                    set: { fields[index].label = $0 }
                                )
                            )
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
                        .padding(.horizontal) // Card-style row
                    }
                }
                .onMove { indices, newOffset in
                    fields.move(fromOffsets: indices, toOffset: newOffset)
                }
            }
            .listStyle(.plain)
            .listRowSeparator(.hidden)
            .frame(height: CGFloat(fields.count) * 60 + 50)
            .environment(\.editMode, .constant(.active))
        }
    }
}
