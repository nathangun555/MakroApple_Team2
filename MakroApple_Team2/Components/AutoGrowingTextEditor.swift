//
//  AutoGrowingTextEditor.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 11/11/25.
//

import SwiftUI

public struct AutoGrowingTextEditor: View {
    @Binding var text: String
    public var placeholder: String = ""
    public var isEditing: Bool = true
    public var font: Font = .system(size: 16)
    public var lineHeight: CGFloat = 20
    public var verticalPadding: CGFloat = 4
    public var maxChars: Int = 70
    public var cornerRadius: CGFloat = 12
    public var borderColor: Color = .black
    public var borderWidth: CGFloat = 0.75

    private var oneRow: CGFloat { lineHeight + verticalPadding * 2 }
    private var twoRows: CGFloat { lineHeight * 2 + verticalPadding * 2 }

    public init(
        text: Binding<String>,
        placeholder: String = "",
        isEditing: Bool = true,
        font: Font = .system(size: 16),
        lineHeight: CGFloat = 20,
        verticalPadding: CGFloat = 4,
        maxChars: Int = 70,
        cornerRadius: CGFloat = 12,
        borderColor: Color = .black,
        borderWidth: CGFloat = 0.75
    ) {
        self._text = text
        self.placeholder = placeholder
        self.isEditing = isEditing
        self.font = font
        self.lineHeight = lineHeight
        self.verticalPadding = verticalPadding
        self.maxChars = maxChars
        self.cornerRadius = cornerRadius
        self.borderColor = borderColor
        self.borderWidth = borderWidth
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, verticalPadding)
                    .allowsHitTesting(false)
            }

            TextEditor(text: Binding(
                get: { text },
                set: { newValue in
                    // collapse triple spaces and multiple blank lines
                    let collapsed = newValue
                        .replacingOccurrences(of: "\\n{2,}", with: "\n", options: .regularExpression)
                        .replacingOccurrences(of: "\\s{3,}", with: "  ", options: .regularExpression)
                    text = String(collapsed.prefix(maxChars))
                }
            ))
            .font(.subheadline)
            .disabled(!isEditing)
            .padding(.horizontal, 6)
            .padding(.vertical, verticalPadding)
            .autocorrectionDisabled(true)
            .textInputAutocapitalization(.words)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .frame(minHeight: oneRow, maxHeight: twoRows, alignment: .top)
            .onAppear {
                UITextView.appearance().textContainerInset = .zero
                UITextView.appearance().textContainer.lineFragmentPadding = 0
            }
        }
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(borderColor, lineWidth: borderWidth)
                .allowsHitTesting(false)
        )
        .cornerRadius(cornerRadius)
    }
}
