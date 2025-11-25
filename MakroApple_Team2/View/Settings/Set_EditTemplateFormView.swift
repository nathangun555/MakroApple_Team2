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
    
    @Binding var isDismissed: Bool
    
    @FocusState private var focusedOtherField: Int?
    
    // ✅ State untuk delete alert
    @State private var showDeleteFieldAlert = false
    @State private var deleteFieldIndex: Int?

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
                            onAddColumn: { viewModel.addCustomerField() },
                            isEditable: false,
                            focusedIndex: $focusedOtherField
                        )

                        FormSection(
                            title: "Jadwal Pesanan",
                            fields: $viewModel.scheduleFields,
                            onAddColumn: { viewModel.addScheduleField() },
                            isEditable: false,
                            focusedIndex: $focusedOtherField
                        )

                        FormSection(
                            title: "Rincian Pesanan",
                            fields: $viewModel.orderFields,
                            onAddColumn: { viewModel.addOrderField() },
                            isEditable: false,
                            focusedIndex: $focusedOtherField
                        )

                        FormSection(
                            title: "Lain - Lain",
                            fields: $viewModel.otherFields,
                            onAddColumn: {
                                viewModel.addOtherField()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    focusedOtherField = 0
                                }
                            },
                            showDelete: true,
                            onDelete: { index in
                                deleteFieldIndex = index
                                showDeleteFieldAlert = true
                            },
                            isEditable: true,
                            focusedIndex: $focusedOtherField
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
                .disabled(showDeleteFieldAlert)
            }
            
            // ✅ Delete alert overlay
            if showDeleteFieldAlert {
                CustomDeleteAlertComponent(
                    title: "Hapus Field",
                    message: "Apakah Anda yakin ingin menghapus field ini?",
                    cancelTitle: "Batal",
                    confirmTitle: "Hapus",
                    onCancel: {
                        showDeleteFieldAlert = false
                        deleteFieldIndex = nil
                    },
                    onConfirm: {
                        if let index = deleteFieldIndex {
                            viewModel.deleteOtherField(at: index)
                        }
                        showDeleteFieldAlert = false
                        deleteFieldIndex = nil
                    }
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(999)
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
        .navigationTitle("Template Formulir Bisnis")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    if !showDeleteFieldAlert {
                        dismiss()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(showDeleteFieldAlert ? .gray : .primaryButton)
                }
                .disabled(showDeleteFieldAlert)
            }
            
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(action: {
                    if !showDeleteFieldAlert {
                        Task {
                            await viewModel.saveTemplate()
                            isDismissed = true
                            dismiss()
                        }
                    }
                }) {
                    if viewModel.isSaving {
                        ProgressView()
                    } else {
                        Image(systemName: "checkmark")
                            .font(.title3)
                            .foregroundColor(showDeleteFieldAlert ? .gray : .white)
                    }
                }
                .buttonStyle(.glassProminent)
                .tint(showDeleteFieldAlert ? .gray : .primaryButton)
                .disabled(viewModel.isSaving || showDeleteFieldAlert)
            }
        }
        .task {
            viewModel.configure(userId: session.userId)
            await viewModel.loadTemplate()
        }
    }
}

//#Preview {
//    let session = SessionManager()
//    session.isSignedIn = true
//    session.userId = "083dc90d-ca03-4f45-a631-06fe21fe750f"
//    return NavigationStack {
//        Set_EditTemplateFormView()
//            .environmentObject(session)
//    }
//}
