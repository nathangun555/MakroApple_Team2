//
//  DoneToolbar.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 21/11/25.
//

// THIS IS FOR KEYPADS

import SwiftUI

struct DoneToolbar<T: Hashable>: ViewModifier {
    var isFocused: FocusState<T?>.Binding

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isFocused.wrappedValue = nil
                    }
                }
            }
    }
}

extension View {
    func doneToolbar<T: Hashable>(isFocused: FocusState<T?>.Binding) -> some View {
        self.modifier(DoneToolbar(isFocused: isFocused))
    }
}
