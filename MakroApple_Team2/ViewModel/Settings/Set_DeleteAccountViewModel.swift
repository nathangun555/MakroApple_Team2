//
//  Set_DeleteAccountViewModel.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 22/10/25.
//

import Foundation
import Combine

@MainActor
final class Set_DeleteAccountViewModel: ObservableObject {
  @Published var deletePhrase: String = ""
  @Published var deleting = false
  @Published var showConfirmAlert = false
  @Published var errorMessage: String?

  let requiredPhrase = "I want to delete my account"

  var canConfirmDelete: Bool {
    deletePhrase == requiredPhrase && !deleting
  }

  func handleDelete(session: SessionManager) async {
    guard canConfirmDelete, !deleting else { return }
    deleting = true
    defer { deleting = false }
    do {
      try await SupabaseManager.shared.deleteUserCompletely()
      await session.signOut()
    } catch {
      errorMessage = "Failed to delete account. Please try again."
      // Optionally log error details for debugging:
      print("Delete failed: \(error)")
    }
  }

  func reset() {
    deletePhrase = ""
    showConfirmAlert = false
    errorMessage = nil
  }
}
