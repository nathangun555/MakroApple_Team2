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
                            isEditable: false
                        )
                        
                        // Jadwal Pesanan Section
                        FormSection(
                            title: "Jadwal Pesanan",
                            fields: $viewModel.scheduleFields,
                            onAddColumn: { viewModel.addScheduleField() },
                            isEditable: false
                        )
                        
                        // Rincian Pesanan Section
                        FormSection(
                            title: "Rincian Pesanan",
                            fields: $viewModel.orderFields,
                            onAddColumn: { viewModel.addOrderField() },
                            isEditable: false
//                                showDelete: true,
//                                onDelete: { index in viewModel.deleteOrderField(at: index) }
                        )
                        
                        // Lain-Lain Section
//                        DraggableFormSection(
//                            title: "Lain - Lain",
//                            fields: $viewModel.otherFields,
//                            onAddColumn: { viewModel.addOtherField() },
//                            showDelete: true,
//                            onDelete: { index in viewModel.deleteOtherField(at: index) }
//                        )
                        FormSection(
                            title: "Lain - Lain",
                            fields: $viewModel.otherFields,
                            onAddColumn: { viewModel.addOtherField() },
                            showDelete: true,
                            onDelete: { index in viewModel.deleteOtherField(at: index) },
                            isEditable: true
                        )
                        
                        
                        // Referensi Foto Section
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
        .navigationTitle("Formulir Pesanan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        await viewModel.saveTemplate()
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(.white)
                        
                }
                .buttonStyle(.glassProminent)
                .disabled(viewModel.isSaving)
                .tint(.primaryButton)
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

//#Preview {
//    let session = SessionManager()
//    session.isSignedIn = true
//    session.userId = "083dc90d-ca03-4f45-a631-06fe21fe750f"
//    
//    let view = EditTemplateFormView()
//    
//    return view.environmentObject(session)
//}
