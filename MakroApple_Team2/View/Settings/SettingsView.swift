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
                        HStack {
                            Image(systemName: "building.2")
                                .foregroundStyle(.primaryButton)
                                .imageScale(.large)
                            Text("Rincian Bisnis")
                        }
                    }

                    NavigationLink(destination: Set_MenuDetailsView()) {
                        HStack {
                            Image(systemName: "list.bullet.rectangle.portrait")
                                .foregroundStyle(.primaryButton)
                                .imageScale(.large)
                            Text("Rincian Menu / Katalog")
                        }
                    }

                    NavigationLink(destination: Set_TemplateFormView()) {
                        HStack {
                            Image(systemName: "square.and.pencil")
                                .foregroundStyle(.primaryButton)
                                .imageScale(.large)
                            Text("Template Formulir Bisnis")
                        }
                    }

                    NavigationLink(destination: Set_LanguageSettingsView()) {
                        HStack {
                            Image(systemName: "globe")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.primaryButton)
                                .imageScale(.large)
                            Text("Pilih Bahasa")
                        }
                    }
                }


                // Hapus akun
                Section {
                    NavigationLink(destination: Set_DeleteAccountView()) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                                .imageScale(.large)
                            Text("Hapus Akun Saya")
                                .foregroundStyle(.red)
                        }
                    }
                }

                // Logout
                Section {
                    NavigationLink(destination: EmptyView()) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundStyle(.primaryButton)
                                .imageScale(.medium)
                            Text("Logout")
                        }
                       
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
