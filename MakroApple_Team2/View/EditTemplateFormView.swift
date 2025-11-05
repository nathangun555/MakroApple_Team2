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
                            onAddColumn: { viewModel.addCustomerField() }
                        )
                        
                        // Jadwal Pesanan Section
                        FormSection(
                            title: "Jadwal Pesanan",
                            fields: $viewModel.scheduleFields,
                            onAddColumn: { viewModel.addScheduleField() }
                        )
                        
                        // Rincian Pesanan Section
                        FormSection(
                            title: "Rincian Pesanan",
                            fields: $viewModel.orderFields,
                            onAddColumn: { viewModel.addOrderField() },
//                                showDelete: true,
//                                onDelete: { index in viewModel.deleteOrderField(at: index) }
                        )
                        
                        // Lain-Lain Section
                        FormSection(
                            title: "Lain - Lain",
                            fields: $viewModel.otherFields,
                            onAddColumn: { viewModel.addOtherField() },
//                                showDelete: true,
//                                onDelete: { index in viewModel.deleteOtherField(at: index) }
                        )
                        
                        // Referensi Foto Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Referensi Foto")
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            Button(action: {
                                // Handle photo upload
                            }) {
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
                        }
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .disabled(true)
                    }
                    .padding(.vertical)
                }
            }
        }
        .navigationTitle("Formulir Pesanan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(action: {
                    print("")
                    Task {
                        await viewModel.saveTemplate()
                    }
                }) {
                    if viewModel.isSaving {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.right")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                }
                .disabled(viewModel.isSaving)
            }
        }
        .navigationDestination(isPresented: $viewModel.didSave) {
            InvoicePreviewView(orderId: nil)
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
    
    let view = EditTemplateFormView()
    
    return view.environmentObject(session)
}
