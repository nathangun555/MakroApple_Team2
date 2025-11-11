//
//  FieldStatusIcon.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 11/11/25.
//

import SwiftUI

struct FieldStatusIcon: ViewModifier {
    enum Kind { case error, success, info }
    
    var show: Bool
    var kind: Kind = .error
    var alignment: Alignment = .trailing
    var paddingTrailing: CGFloat = 6
    var paddingTop: CGFloat = 0
    var size: CGFloat = 14

    @ViewBuilder
    private func iconView() -> some View {
        switch kind {
        case .error:
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red)
        case .success:
            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
        case .info:
            Image(systemName: "info.circle.fill").foregroundColor(.blue)
        }
    }

    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if show {
                        iconView()
                            .font(.system(size: size, weight: .bold))
                            .padding(.trailing, paddingTrailing)
                            .padding(.top, paddingTop)
                            .transition(.scale.combined(with: .opacity))
                    }
                },
                alignment: alignment
            )
    }
}

extension View {
    func fieldStatusIcon(
        show: Bool,
        kind: FieldStatusIcon.Kind = .error,
        alignment: Alignment = .trailing,
        paddingTrailing: CGFloat = 6,
        paddingTop: CGFloat = 0,
        size: CGFloat = 14
    ) -> some View {
        modifier(FieldStatusIcon(
            show: show,
            kind: kind,
            alignment: alignment,
            paddingTrailing: paddingTrailing,
            paddingTop: paddingTop,
            size: size
        ))
    }
}
