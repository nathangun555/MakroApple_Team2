//
//  HideKeyboard.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 25/11/25.
//

import SwiftUI

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}
