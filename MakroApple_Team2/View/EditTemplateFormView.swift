//
//  EditTemplateFormView.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 22/10/25.
//

import SwiftUI
import Foundation

struct EditTemplateFormView: View {
    @State private var viewModel = EditTemplateViewModel()
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
                        // Rincian Pelanggan Section
                        FormSection(
                            title: "Rincian Pelanggan",
                            fields: $viewModel.customerFields,
                            onAddColumn: { viewModel.addCustomerField() },
                            isEditable: false,
                            focusedIndex: $focusedOtherField
                        )
                        
                        // Jadwal Pesanan Section
                        FormSection(
                            title: "Jadwal Pesanan",
                            fields: $viewModel.scheduleFields,
                            onAddColumn: { viewModel.addScheduleField() },
                            isEditable: false,
                            focusedIndex: $focusedOtherField
                        )
                        
                        // Rincian Pesanan Section
                        FormSection(
                            title: "Rincian Pesanan",
                            fields: $viewModel.orderFields,
                            onAddColumn: { viewModel.addOrderField() },
                            isEditable: false,
                            focusedIndex: $focusedOtherField
                        )
                        
                        // Lain-Lain Section
                        FormSection(
                            title: "Lain - Lain",
                            fields: $viewModel.otherFields,
                            onAddColumn: { viewModel.addOtherField() },
                            showDelete: true,
                            onDelete: { index in
                                deleteFieldIndex = index
                                showDeleteFieldAlert = true
                            },
                            isEditable: true,
                            focusedIndex: $focusedOtherField
                        )

                        
                        // Referensi Foto Section
                        
                        HStack{
                            VStack(alignment: .leading){
                                Image(systemName: "photo.badge.plus.fill")
                                    .font(.title)
                                    .foregroundColor(.gray)
                                Text("No photos")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 115, height: 115)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 0.5))
                                    .foregroundStyle(Color.primary)
                                    .background(.gray.opacity(0.1))
                                    .cornerRadius(10)
                            )
                            Spacer()
                        }
                        .padding(.horizontal)
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
        .navigationTitle("Formulir Pesanan")
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
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if !showDeleteFieldAlert {
                        Task {
                            await viewModel.saveTemplate()
                        }
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(showDeleteFieldAlert ? .gray : .white)
                }
                .buttonStyle(.glassProminent)
                .disabled(viewModel.isSaving || showDeleteFieldAlert)
                .tint(showDeleteFieldAlert ? .gray : .primaryButton)
            }
        }
        .navigationDestination(isPresented: $viewModel.didSave) {
            InvoicePreviewView(isDismissed: $isDismissed)
        }
        .task {
            viewModel.configure(userId: session.userId)
            await viewModel.loadTemplate()
        }
    }
}

#Preview {
    // Dummy binding
    @State var isDismissed = false

    // Dummy environment object
    let session = SessionManager()
    session.userId = "083dc90d-ca03-4f45-a631-06fe21fe750f"

    return NavigationStack {
        EditTemplateFormView(isDismissed: $isDismissed)
            .environmentObject(session)
    }
}
