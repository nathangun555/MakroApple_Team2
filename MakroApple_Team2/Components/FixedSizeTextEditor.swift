//
//  FixedSizeT.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 11/11/25.
//

import SwiftUI

public struct FixedPillTextField: View {
    @Binding var text: String
    public var placeholder: String = ""
    public var isEditing: Bool = true
    public var font: Font = .system(size: 16)
    public var lineHeight: CGFloat = 20
    public var verticalPadding: CGFloat = 4
    public var cornerRadius: CGFloat = 12
    public var borderColor: Color = .black
    public var borderWidth: CGFloat = 0.75
    public var keyboard: UIKeyboardType = .default
    public var contentType: UITextContentType? = nil
    public var autocap: TextInputAutocapitalization? = .sentences
    public var autocorrect: Bool = true
    public var maxChars: Int? = nil

    private var height: CGFloat { lineHeight + verticalPadding * 2 }

    public init(
        text: Binding<String>,
        placeholder: String = "",
        isEditing: Bool = true,
        font: Font = .system(size: 16),
        lineHeight: CGFloat = 20,
        verticalPadding: CGFloat = 4,
        cornerRadius: CGFloat = 12,
        borderColor: Color = .black,
        borderWidth: CGFloat = 0.75,
        keyboard: UIKeyboardType = .default,
        contentType: UITextContentType? = nil,
        autocap: TextInputAutocapitalization? = .sentences,
        autocorrect: Bool = true,
        maxChars: Int? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.isEditing = isEditing
        self.font = font
        self.lineHeight = lineHeight
        self.verticalPadding = verticalPadding
        self.cornerRadius = cornerRadius
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.keyboard = keyboard
        self.contentType = contentType
        self.autocap = autocap
        self.autocorrect = autocorrect
        self.maxChars = maxChars
    }

    public var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(font)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 12)
            }

            TextField("", text: Binding(
                get: { text },
                set: { newValue in
                    if let max = maxChars {
                        text = String(newValue.prefix(max))
                    } else {
                        text = newValue
                    }
                }
            ))
            .textInputAutocapitalization(autocap)
            .autocorrectionDisabled(!autocorrect)
            .keyboardType(keyboard)
            .textContentType(contentType)
            .font(font)
            .disabled(!isEditing)
            .padding(.horizontal, 12)
            .frame(height: height, alignment: .center)
            .background(Color.clear)
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

