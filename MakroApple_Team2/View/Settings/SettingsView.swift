//
//  SettingsView.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 10/10/25.
//

import SwiftUI

struct SettingsView: View {
  @State private var showDeleteDialog = false
  @State private var showLogoutDialog = false

  var body: some View {
    NavigationStack {
      List {
        // Profil Saya (baru)
        NavigationLink {
          Set_ProfileView()
        } label: {
          Label("Profil Saya", systemImage: "person.crop.circle")
        }

        // 1) Ubah Rincian Bisnis
        NavigationLink {
          Set_BusinessDetailsView()
        } label: {
          Label("Ubah Rincian Bisnis", systemImage: "building.2")
        }

        // 2) Ubah Template Form
        NavigationLink {
          Set_TemplateFormView()
        } label: {
          Label("Ubah Template Form", systemImage: "square.and.pencil")
        }

        // 3) Ubah Visibilitas Rincian Invoice
        NavigationLink {
          Set_InvoiceVisibilityView()
        } label: {
          Label("Ubah Visibilitas Rincian Invoice", systemImage: "doc.text.magnifyingglass")
        }

        // 4) Ubah Rincian Menu
        NavigationLink {
          Set_MenuDetailsView()
        } label: {
          Label("Ubah Rincian Menu", systemImage: "list.bullet.rectangle.portrait")
        }

        // 5) Language
        NavigationLink {
          Set_LanguageSettingsView()
        } label: {
          Label("Language", systemImage: "globe")
        }

        // 6) Delete My Account (confirmation)
        Button(role: .destructive) {
          showDeleteDialog = true
        } label: {
          Label("Delete My Account", systemImage: "trash")
            .foregroundStyle(.red)
        }

        // 7) Logout (confirmation)
        Button {
          showLogoutDialog = true
        } label: {
          Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
            .foregroundStyle(.blue)
        }
      }
      .navigationTitle("Settings")

      .confirmationDialog(
        "Yakin hapus akun?",
        isPresented: $showDeleteDialog,
        titleVisibility: .visible
      ) {
        Button("Delete My Account", role: .destructive) {
          Task { await SettingsActions.deleteAccount() }
        }
        Button("Cancel", role: .cancel) { }
      } message: {
        Text("Tindakan ini permanen.")
      }

      .confirmationDialog(
        "Keluar dari akun?",
        isPresented: $showLogoutDialog,
        titleVisibility: .visible
      ) {
        Button("Logout", role: .destructive) {
          Task { await SettingsActions.logout() }
        }
        Button("Cancel", role: .cancel) { }
      } message: {
        Text("Anda bisa masuk kembali kapan saja.")
      }
    }
  }
}



enum SettingsActions {
  static func deleteAccount() async { /* implement */ }
  static func logout() async { /* implement */ }
}

#Preview { SettingsView() }
