//
//  InvoiceVisibilityView.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 24/10/25.
//

import SwiftUI
import Foundation

struct InvoiceVisibilityView: View {
    @State private var viewModel = EditTemplateViewModel()
    @EnvironmentObject var session: SessionManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
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
                            FormSectionInvoice(
                                title: "Rincian Pelanggan",
                                fields: $viewModel.customerFields,
                                onAddColumn: { viewModel.addCustomerField() }
                            )
                            
                            // Jadwal Pesanan Section
                            FormSectionInvoice(
                                title: "Jadwal Pesanan",
                                fields: $viewModel.scheduleFields,
                                onAddColumn: { viewModel.addScheduleField() }
                            )
                            
                            // Rincian Pesanan Section
                            FormSectionInvoice(
                                title: "Rincian Pesanan",
                                fields: $viewModel.orderFields,
                                onAddColumn: { viewModel.addOrderField() },
                                showDelete: true,
                                onDelete: { index in viewModel.deleteOrderField(at: index) }
                            )
                            
                            // Lain-Lain Section
                            FormSectionInvoice(
                                title: "Lain - Lain",
                                fields: $viewModel.otherFields,
                                onAddColumn: { viewModel.addOtherField() },
                                showDelete: true,
                                onDelete: { index in viewModel.deleteOtherField(at: index) }
                            )
                            
                            // Referensi Foto Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Referensi Foto")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                
                                Button(action: {
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
            .navigationTitle("Rincian Invoice")
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
                Set_InvoiceVisibilityView()
            }
        }
        .task {
            viewModel.configure(userId: session.userId)
            await viewModel.loadTemplate()
        }
    }
}

// MARK: - Form Section Component
struct FormSectionInvoice: View {
    let title: String
    @Binding var fields: [FormFieldItem]
    let onAddColumn: () -> Void
    var showDelete: Bool = false
    var onDelete: ((Int) -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
            }
            .padding(.horizontal)
            
            ForEach(Array(fields.enumerated()), id: \.offset) { index, field in
                if field.label != "Foto Referensi (optional)" {
                    HStack(spacing: 12) {
                        Text("\(field.label) :")
                            .frame(width: 140, alignment: .trailing)
                            .font(.body)
                        
                        Text("")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

#Preview {
    let session = SessionManager()
    session.isSignedIn = true
    session.userId = "083dc90d-ca03-4f45-a631-06fe21fe750f"
    
    let view = InvoiceVisibilityView()
    
    return view.environmentObject(session)
}
