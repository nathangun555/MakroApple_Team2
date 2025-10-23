//
//  Set_DeleteAccountView.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 22/10/25.
//

import SwiftUI

struct Set_DeleteAccountView: View {
  @EnvironmentObject var session: SessionManager
  @StateObject private var vm = Set_DeleteAccountViewModel()
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    Form {
      Section {
        Text("Type the exact phrase below to confirm deletion. This action is permanent.")
          .font(.subheadline)
        Text("I want to delete my account")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .padding(.vertical, 4)
      }

      Section {
        TextField("I want to delete my account", text: $vm.deletePhrase)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
          .submitLabel(.done)
      }

      Section {
        Button {
          vm.showConfirmAlert = true
        } label: {
          if vm.deleting {
            HStack { ProgressView(); Text("Deleting…") }
          } else {
            Text("Delete My Account")
          }
        }
        .buttonStyle(.borderedProminent)
        .tint(.red)
        .disabled(!vm.canConfirmDelete)
      } footer: {
        Text("All your orders, products, and profile data will be deleted and you will be signed out.")
      }
    }
    .navigationTitle("Delete Account")
    .toolbar {
      if vm.deleting {
        ToolbarItem(placement: .topBarTrailing) {
          ProgressView()
        }
      }
    }
    .interactiveDismissDisabled(vm.deleting)

    // Final confirmation before delete
    .alert("Are you sure?", isPresented: $vm.showConfirmAlert) {
      Button("Delete", role: .destructive) {
        Task { await vm.handleDelete(session: session) }
      }
      Button("Cancel", role: .cancel) { }
    } message: {
      Text("This cannot be undone.")
    }

    // Error surfaced from the ViewModel
    .alert("Delete failed", isPresented: Binding(
      get: { vm.errorMessage != nil },
      set: { if !$0 { vm.errorMessage = nil } }
    )) {
      Button("OK", role: .cancel) {
        vm.errorMessage = nil
      }
    } message: {
      Text(vm.errorMessage ?? "")
    }

    .onDisappear {
      // Clean up local state when leaving the screen
      vm.deletePhrase = ""
      vm.showConfirmAlert = false
      vm.errorMessage = nil
    }
  }
}

#Preview {
  let session = SessionManager()
  session.isSignedIn = true
  return NavigationStack {
    Set_DeleteAccountView()
      .environmentObject(session)
  }
}
