//
//  Set_MenuDetailsViewModel.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 22/10/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class Set_MenuDetailsViewModel: ObservableObject {
  @Published var products: [ProductRecord] = []
  @Published var isLoading = false
  @Published var errorMessage: String?

  private(set) var userId: String?

  func configure(userId: String?) { self.userId = userId }

  func load() async {
    guard let userId, let uuid = UUID(uuidString: userId) else {
      errorMessage = "User belum login atau UID tidak valid."
      return
    }
    isLoading = true
    errorMessage = nil
    defer { isLoading = false }

    do {
      products = try await SupabaseManager.shared.fetchProducts(for: uuid)
    } catch {
      errorMessage = "Gagal memuat produk: \(error.localizedDescription)"
    }
  }
}
