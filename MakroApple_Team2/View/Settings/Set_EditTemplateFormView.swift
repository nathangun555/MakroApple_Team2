////
////  Set_TemplateFormView.swift
////  MakroApple_Team2
////
////  Created by Nathan Gunawan on 17/10/25.
////

import SwiftUI
import Foundation

struct Set_EditTemplateFormView: View {
    @State private var viewModel = Set_EditTemplateFormViewModel()
    @EnvironmentObject var session: SessionManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView("Memuat template...")
            } else if let errorMessage = viewModel.errorMessage {
                VStack {
                    Text("❌ Error")
                        .font(.headline)
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        FormSection(
                            title: "Rincian Pelanggan",
                            fields: $viewModel.customerFields,
                            onAddColumn: { viewModel.addCustomerField() }
                        )

                        FormSection(
                            title: "Jadwal Pesanan",
                            fields: $viewModel.scheduleFields,
                            onAddColumn: { viewModel.addScheduleField() }
                        )

                        FormSection(
                            title: "Rincian Pesanan",
                            fields: $viewModel.orderFields,
                            onAddColumn: { viewModel.addOrderField() }
                        )

                        FormSection(
                            title: "Lain - Lain",
                            fields: $viewModel.otherFields,
                            onAddColumn: { viewModel.addOtherField() },
                            showDelete: true,
                            onDelete: { index in viewModel.deleteOtherField(at: index) },
                            isEditable: true
                        )

                        // Referensi Foto (nonaktif dulu)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Referensi Foto")
                                .font(.title3)
                                .fontWeight(.bold)

                            Button(action: {}) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                        .foregroundColor(.gray.opacity(0.5))
                                        .frame(width: 200, height: 200)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(12)
                                    VStack {
                                        Image(systemName: "photo.badge.plus")
                                            .font(.system(size: 40))
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .disabled(true)
                        }
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical)
                }
            }
        }
        .navigationTitle("Template Formulir Bisnis")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(action: {
                    Task { await viewModel.saveTemplate() }
                }) {
                    if viewModel.isSaving {
                        ProgressView()
                    } else {
                        Image(systemName: "checkmark")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.glassProminent)
                .tint(.primaryButton)
                .disabled(viewModel.isSaving)
            }
        }
        .task {
            viewModel.configure(userId: session.userId)
            await viewModel.loadTemplate()
        }
    }
}

#Preview {
    let session = SessionManager()
    session.isSignedIn = true
    session.userId = "083dc90d-ca03-4f45-a631-06fe21fe750f"
    return NavigationStack {
        Set_EditTemplateFormView()
            .environmentObject(session)
    }
}
