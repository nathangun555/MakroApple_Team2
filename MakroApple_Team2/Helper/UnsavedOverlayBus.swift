//
//  UnsavedOverlayBus.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 10/11/25.
//

import SwiftUI
import Combine

final class UnsavedOverlayBus: ObservableObject {
    @Published var show = false
    @Published var title = "Perubahan Belum Disimpan"
    @Published var message = "Apakah Anda yakin ingin membatalkan perubahan yang telah dibuat?"
    @Published var cancelTitle = "Tidak"
    @Published var confirmTitle = "Ya"

    var onConfirm: (() -> Void)?
    var onCancel: (() -> Void)?

    func request(
        title: String? = nil,
        message: String? = nil,
        cancelTitle: String? = nil,
        confirmTitle: String? = nil,
        onCancel: @escaping () -> Void,
        onConfirm: @escaping () -> Void
    ) {
        if let t = title { self.title = t }
        if let m = message { self.message = m }
        if let c = cancelTitle { self.cancelTitle = c }
        if let k = confirmTitle { self.confirmTitle = k }
        self.onCancel = onCancel
        self.onConfirm = onConfirm
        self.show = true
    }

    func close(_ confirmed: Bool) {
        let action = confirmed ? onConfirm : onCancel
        self.show = false
        DispatchQueue.main.async { action?() }
        self.onConfirm = nil
        self.onCancel = nil
    }
}

