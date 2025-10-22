import SwiftUI

struct SettingsView: View {
  @EnvironmentObject var session: SessionManager

  @State private var showLogoutDialog = false
  @State private var isLoggingOut = false

  var body: some View {
    NavigationStack {
      List {
        NavigationLink { Set_ProfileView() } label: {
          Label("Profil Saya", systemImage: "person.crop.circle")
        }
        NavigationLink { Set_BusinessDetailsView() } label: {
          Label("Ubah Rincian Bisnis", systemImage: "building.2")
        }
        NavigationLink { Set_TemplateFormView() } label: {
          Label("Ubah Template Form", systemImage: "square.and.pencil")
        }
        NavigationLink { Set_InvoiceVisibilityView() } label: {
          Label("Ubah Visibilitas Rincian Invoice", systemImage: "doc.text.magnifyingglass")
        }
        NavigationLink { Set_MenuDetailsView() } label: {
          Label("Ubah Rincian Menu", systemImage: "list.bullet.rectangle.portrait")
        }
        NavigationLink { Set_LanguageSettingsView() } label: {
          Label("Language", systemImage: "globe")
        }

        // Delete account full-screen flow
        NavigationLink {
          Set_DeleteAccountView()
        } label: {
          Label("Delete My Account", systemImage: "trash")
            .foregroundStyle(.red)
        }

        // Logout
        Button {
          showLogoutDialog = true
        } label: {
          if isLoggingOut {
            HStack { ProgressView(); Text("Logging out…") }
          } else {
            Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
              .foregroundStyle(.blue)
          }
        }
        .disabled(isLoggingOut || showLogoutDialog)
      }
      .navigationTitle("Settings")
      //.toolbarTitleDisplayMode(.large) // optional styling

      .alert("Keluar dari akun?", isPresented: $showLogoutDialog) {
        Button("Logout", role: .destructive) {
          isLoggingOut = true
          Task {
            defer {
              isLoggingOut = false
              showLogoutDialog = false
            }
            await session.signOut()
          }
        }
        Button("Cancel", role: .cancel) {
          showLogoutDialog = false
        }
      } message: {
        Text("Anda bisa masuk kembali kapan saja.")
      }
    }
  }
}

#Preview {
  let session = SessionManager()
  session.isSignedIn = true
  session.userId = "083dc90d-ca03-4f45-a631-06fe21fe750f"
  return NavigationStack { SettingsView() }
    .environmentObject(session)
}
