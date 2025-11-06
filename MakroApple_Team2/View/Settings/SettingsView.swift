import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var session: SessionManager

    @State private var showLogoutDialog = false
    @State private var isLoggingOut = false

    var body: some View {
        NavigationStack {
            List {
                // Group 1
                Section {
                    NavigationLink(destination: Set_BusinessDetailsView()) {
                        Label("Rincian Bisnis", systemImage: "building.2")
                    }

                    NavigationLink(destination: Set_MenuDetailsView()) {
                        Label("Rincian Menu / Katalog", systemImage: "list.bullet.rectangle.portrait")
                    }

                    NavigationLink(destination: Set_TemplateFormView()) {
                        Label("Template Formulir Bisnis", systemImage: "square.and.pencil")
                    }

                    NavigationLink(destination: Set_LanguageSettingsView()) {
                        Label("Pilih Bahasa", systemImage: "globe")
                    }
                }

                // Hapus akun
                Section {
                    NavigationLink(destination: Set_DeleteAccountView()) {
                        Label("Hapus Akun Saya", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                }

                // Logout
                Section {
                    NavigationLink(destination: EmptyView()) {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundStyle(.blue)
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        showLogoutDialog = true
                    })
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden) // biar background putih polos
            .background(Color.white)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Pengaturan")
                        .font(.title2.bold())
                }
            }
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
