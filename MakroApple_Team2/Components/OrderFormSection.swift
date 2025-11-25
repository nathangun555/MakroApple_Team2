//
//  OrderFormSection.swift
//  MakroApple_Team2
//
//  Created by Assistant on 30/10/25.
//

import SwiftUI

private let dateFormatterHelper = DateFormatterHelper()

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
                            .frame(width: 140, alignment: .leading)
                            .font(.body)
                            .foregroundColor(.primary)

                        // -------- ALWAYS DATE PICKER WHEN LABEL HAS "tanggal" --------
                        if field.label.lowercased().contains("tanggal pesanan") {

                            DatePicker(
                                "",
                                selection: Binding(
                                    get: {
                                        dateFormatterHelper.parseIndonesianDate(fields[index].value) ?? Date()
                                    },
                                    set: {
                                        fields[index].value = dateFormatterHelper.formatIndonesianDate($0)
                                    }
                                ),
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .frame(maxWidth: .infinity)

                        // -------- ALWAYS TIME PICKER WHEN LABEL HAS "jam" --------
                        } else if field.label.lowercased().contains("jam kirim") {

                            DatePicker(
                                "",
                                selection: Binding(
                                    get: {
                                        dateFormatterHelper.parseTime(fields[index].value) ?? Date()
                                    },
                                    set: {
                                        fields[index].value = dateFormatterHelper.formatTime($0)
                                    }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .frame(maxWidth: .infinity)

                        // -------- NORMAL TEXT FIELD --------
                        } else {

                            TextField("Silakan isi kolom", text: Binding(
                                get: { fields[index].value },
                                set: { fields[index].value = $0 }
                            ))
                            .focused($focusedField, equals: key)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        (fieldErrors.contains(key) && !isOptionalField(field.label))
                                            ? Color.red
                                            : Color(.systemGray4),
                                        lineWidth: (fieldErrors.contains(key) && !isOptionalField(field.label))
                                            ? 2 : 1
                                    )
                            )

                        }
                    }

                    // Nathan Merubah Ini buat alert
                    // Error message
                    if fieldErrors.contains(key) && !isOptionalField(field.label) {
                        HStack {
                            Spacer().frame(width: 140)
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                Text("Field ini wajib diisi")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                            .padding(.leading, 12)
                            Spacer()
                        }
                    }

                }
                .id(key)
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

func isOptionalField(_ label: String) -> Bool {
    let lower = label.lowercased()
    return lower.contains("tanggal pesanan") || lower.contains("jam kirim")
}
