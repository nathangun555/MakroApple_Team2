//
//  OrderFormSection.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 30/10/25.
//

import SwiftUI

private let dateFormatterHelper = DateFormatterHelper()

struct OrderFormSection: View {
    @State private var useTime = false
    let title: String
    @Binding var fields: [OrderField]
    let sectionType: String   // "customer", "schedule", "other"
    let fieldErrors: Set<String>

    @FocusState private var focusedField: String?

    private let labelWidth: CGFloat = 120
    private let colonWidth: CGFloat = 10

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal)

            ForEach(Array(fields.enumerated()), id: \.offset) { index, field in
                let key = "\(sectionType)-\(index)"

                VStack(alignment: .leading, spacing: 4) {

                    HStack(spacing: 8) {
                        Text(field.label)
                            .frame(width: labelWidth, alignment: .leading)
                            .font(.body)
                            .foregroundColor(.primary)

                        Text(":")
                            .frame(width: colonWidth, alignment: .center)

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
                                in: Date()...,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .fixedSize()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .onAppear {
                                if fields[index].value.isEmpty {
                                    fields[index].value = dateFormatterHelper.formatIndonesianDate(Date())
                                }
                            }

                        } else if field.label.lowercased().contains("jam kirim") {

                            HStack(spacing: 12) {
                                DatePicker(
                                    "",
                                    selection: Binding(
                                        get: {
                                            dateFormatterHelper.parseTime(fields[index].value) ?? Date()
                                        },
                                        set: {
                                            if fields[index].useTime {
                                                fields[index].value = dateFormatterHelper.formatTime($0)
                                            }
                                        }
                                    ),
                                    displayedComponents: .hourAndMinute
                                )
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .fixedSize()
                                .disabled(!fields[index].useTime)
                                .opacity(!fields[index].useTime ? 0.7 : 1.0)
                                .background(!fields[index].useTime ? Color.gray.opacity(0.1) : Color.white)
                                .cornerRadius(20)
                                
                                Spacer()

                                Toggle("", isOn: Binding(
                                    get: { fields[index].useTime },
                                    set: { newValue in
                                        fields[index].useTime = newValue
                                        if newValue && fields[index].value.isEmpty {
                                            fields[index].value = dateFormatterHelper.formatTime(Date())
                                        }
                                        if !newValue {
                                            fields[index].value = ""
                                        }
                                    }
                                ))
                                .labelsHidden()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                        } else {

                            TextField("Silakan isi kolom", text: Binding(
                                get: { fields[index].value },
                                set: { fields[index].value = $0 }
                            ))
                            .keyboardType(field.label.lowercased().contains("telp") ? .numbersAndPunctuation : .default)
                            .focused($focusedField, equals: key)
                            .frame(maxWidth: .infinity, alignment: .leading)
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

                    // Error message tetap pakai spacer, tapi selaras dengan content
                    if fieldErrors.contains(key) && !isOptionalField(field.label) {
                        HStack {
                            Spacer().frame(width: labelWidth + colonWidth)
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                                .font(.system(size: 12, weight: .semibold))
                            Text("Field ini wajib diisi")
                                .font(.caption)
                                .foregroundStyle(.red)
                            Spacer()
                        }
                        .padding(.leading, 12)
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
    var useTime: Bool = false
}

func isOptionalField(_ label: String) -> Bool {
    let lower = label.lowercased()
    return lower.contains("tanggal pesanan") || lower.contains("jam kirim")
}
