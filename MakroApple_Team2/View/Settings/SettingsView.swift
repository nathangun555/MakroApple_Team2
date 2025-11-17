//
//  SettingsView.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 17/10/25.
//
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var session: SessionManager

    @State private var showLogoutDialog = false
    @State private var isLoggingOut = false

    // Navigasi dinamis (template form)
    @State private var navigateToNewTemplate = false
    @State private var navigateToEditTemplate = false

    // State loading & error saat cek template_format
    @State private var isCheckingTemplate = false
    @State private var checkError: String?

    // Navigasi dinamis (menu katalog) - untuk fullScreenCover
    @State private var showInputMenu = false
    @State private var showMenuDetails = false
    @State private var isCheckingProducts = false
    @State private var productCheckError: String?
    
    // Binding untuk dismiss all sheets (dipakai Set_InputMenuView / Set_ConfirmMenuView / Set_ManualInputView)
    @State private var isDismissedFromMenu = false

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

                    // Tombol dengan pengecekan produk sebelum navigasi
                    Button {
                        Task { await decideMenuDestination() }
                    } label: {
                        HStack {
                            Image(systemName: "list.bullet.rectangle.portrait")
                                .foregroundStyle(.primaryButton)
                                .imageScale(.large)
                            Text("Rincian Menu / Katalog")
                            Spacer()
                            if isCheckingProducts {
                                ProgressView().scaleEffect(0.8)
                            } else {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(Color(.systemGray2))
                                    .imageScale(.small)
                            }
                        }
                    }
                    .disabled(isCheckingProducts)

                    if let err = productCheckError {
                        Text(err)
                            .font(.caption)
                            .foregroundColor(.red)
                            .lineLimit(2)
                    }

                    // Template Formulir Bisnis (cek Supabase dulu)
                    Button {
                        Task { await checkTemplateAndNavigate() }
                    } label: {
                        HStack {
                            Image(systemName: "square.and.pencil")
                                .foregroundStyle(.primaryButton)
                                .imageScale(.large)
                            Text("Template Formulir Bisnis")
                            Spacer()
                            if isCheckingTemplate {
                                ProgressView().scaleEffect(0.8)
                            } else {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(Color(.systemGray2))
                                    .imageScale(.small)
                            }
                        }
                    }
                    .disabled(isCheckingTemplate)

                    if let err = checkError {
                        Text(err)
                            .font(.caption)
                            .foregroundColor(.red)
                            .lineLimit(2)
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
            .scrollContentBackground(.hidden)
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
                Button("Cancel", role: .cancel) { showLogoutDialog = false }
            } message: {
                Text("Anda bisa masuk kembali kapan saja.")
            }

            // Destinasi dinamis Template
            .navigationDestination(isPresented: $navigateToNewTemplate) {
                Set_NewTemplateFormView(onAfterSave: {
                    navigateToNewTemplate = false
                })
                .environmentObject(session)
            }
            .navigationDestination(isPresented: $navigateToEditTemplate) {
                Set_EditTemplateFormView()
                    .environmentObject(session)
            }

            // fullScreenCover untuk Menu flows
            .fullScreenCover(isPresented: $showInputMenu) {
                Set_InputMenuView(isDismissed: $isDismissedFromMenu)
                    .environmentObject(session)
                // DeleteOverlayBus & UnsavedOverlayBus ikut turun dari root, tidak dibuat ulang di sini
            }
            .fullScreenCover(isPresented: $showMenuDetails) {
                Set_MenuDetailsView()
                    .environmentObject(session)
                // Bus juga ikut dari root
            }
            .onChange(of: isDismissedFromMenu) { oldValue, newValue in
                if newValue {
                    showInputMenu = false
                    showMenuDetails = false
                    isDismissedFromMenu = false
                }
            }
        }
    }

    // MARK: - Logic cek template_format dan navigasi
    private func checkTemplateAndNavigate() async {
        guard let userId = session.userId, let uuid = UUID(uuidString: userId) else {
            checkError = "User belum login atau UID tidak valid."
            return
        }
        isCheckingTemplate = true
        checkError = nil
        defer { isCheckingTemplate = false }

        do {
            let template = try await SupabaseManager.shared.fetchUser(by: uuid)
            if let temp = template, let format = temp.templateFormat, format.isEmpty || template?.templateFormat == nil {
                navigateToNewTemplate = true
            } else {
                navigateToEditTemplate = true
            }
        } catch {
            checkError = "Gagal memeriksa template: \(error.localizedDescription)"
        }
    }

    // MARK: - Logic cek jumlah produk dan navigasi
    private func decideMenuDestination() async {
        guard let userId = session.userId, let uuid = UUID(uuidString: userId) else {
            productCheckError = "User belum login atau UID tidak valid."
            return
        }
        isCheckingProducts = true
        productCheckError = nil
        defer { isCheckingProducts = false }

        do {
            let hasAny = try await SupabaseManager.shared.hasAnyProduct(for: uuid)
            if hasAny {
                showMenuDetails = true
            } else {
                showInputMenu = true
            }
        } catch {
            productCheckError = "Gagal memeriksa produk: \(error.localizedDescription)"
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
