//
//  EditOrderDetailView.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 24/11/25.
//

import SwiftUI
import Foundation

struct EditOrderDetailView: View {
    var orderId: String
    var parsedOrderData: [String: Any]
    @Binding var isDismissed: Bool

    @State private var viewModel = EditOrderViewModel()
    @State private var firstErrorId: String?
    @FocusState private var focusedField: String?
    @State private var lastOrderId: String = ""
    @State private var showSaveSuccess: Bool = false
    @State private var showConfirmInvoice: Bool = false
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var session: SessionManager

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Customer
                        OrderFormSection(
                            title: "Rincian Pelanggan",
                            fields: $viewModel.customerFields,
                            sectionType: "customer",
                            fieldErrors: viewModel.fieldErrors
                        )
                        // Schedule
                        OrderFormSection(
                            title: "Jadwal Pesanan",
                            fields: $viewModel.scheduleFields,
                            sectionType: "schedule",
                            fieldErrors: viewModel.fieldErrors
                        )
                        // Produk
                        ProductsSection(
                            products: $viewModel.products,
                            onAdd: { viewModel.addProduct() },
                            onDelete: { viewModel.deleteProduct(at: $0) },
                            fieldErrors: viewModel.fieldErrors
                        )
                        // Lain-lain
                        OrderFormSection(
                            title: "Lain - Lain",
                            fields: $viewModel.otherFields,
                            sectionType: "other",
                            fieldErrors: viewModel.fieldErrors
                        )
                    }
                    .padding(.vertical)
                    .padding(.horizontal)
                }
                .onChange(of: viewModel.fieldErrors) { _, newErrors in
                    if let first = firstErrorId ?? firstErrorKey(from: newErrors) {
                        withAnimation(.easeInOut) {
                            proxy.scrollTo(first, anchor: .center)
                            focusedField = first
                        }
                    }
                }
                .onChange(of: firstErrorId) { _, newVal in
                    if let id = newVal {
                        withAnimation(.easeInOut) {
                            proxy.scrollTo(id, anchor: .center)
                            focusedField = id
                        }
                    }
                }
            }
            .navigationTitle("Edit Pesanan")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                           isDismissed = true
                           dismiss()
                       } label: {
                           Image(systemName: "xmark")
                               .font(.title3)
                               .foregroundColor(.primaryButton)
                       }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        if viewModel.validateAllFields() {
                            Task {
                                let order = await viewModel.saveOrder(photos: []) // No photos version
                                if let order = order {
                                    lastOrderId = order.id.uuidString
                                    showSaveSuccess = true
                                }
                            }
                        } else {
                            firstErrorId = firstErrorKey(from: viewModel.fieldErrors)
                        }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Image(systemName: "checkmark")
                                .font(.title2)
                                .foregroundColor(.primaryButton)
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .alert("Berhasil!", isPresented: $showSaveSuccess) {
                Button("OK") {
                    showConfirmInvoice = true
                }
            } message: {
                Text("Pesanan berhasil disimpan!")
            }
            .navigationDestination(isPresented: $showConfirmInvoice) {
                ConfirmInvoiceView(orderId: orderId, isDismissed: $isDismissed)
            }
            .onAppear {
                viewModel.configure(userId: session.userId, parsedOrderData: parsedOrderData)
                viewModel.orderIdNow = orderId
            }
        }
    }

    // Helper for scrolling to the first error
    private func firstErrorKey(from errors: Set<String>) -> String? {
        let sections = ["customer", "schedule", "product", "other"]
        for section in sections {
            if let match = errors.sorted().first(where: { $0.hasPrefix(section + "-") }) {
                return match
            }
        }
        return errors.sorted().first
    }
}
