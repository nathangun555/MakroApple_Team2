//
//  DeleteOverlayBus.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 09/11/25.
//

import SwiftUI
import Combine

final class DeleteOverlayBus: ObservableObject {
    @Published var show = false
    @Published var message = "Apakah Anda yakin ingin menghapus bagian ini?"
    var confirm: (() -> Void)?
    var cancel: (() -> Void)?

    func request(message: String? = nil, onConfirm: @escaping () -> Void) {
        if let m = message { self.message = m }
        self.confirm = onConfirm
        self.cancel = { }
        self.show = true
    }

    func closeConfirm(_ confirmed: Bool) {
        let action = confirmed ? confirm : cancel
        self.show = false
        DispatchQueue.main.async { action?() }
        self.confirm = nil
        self.cancel = nil
    }
}
