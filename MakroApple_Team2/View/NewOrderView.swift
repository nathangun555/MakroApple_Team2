//
//  NewOrderView.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 10/10/25.
//

import SwiftUI
import Foundation
import PhotosUI

struct NewOrderView: View {
    @State private var viewModel = NewOrderViewModel()
    @EnvironmentObject var session: SessionManager
    @State private var formPesanan = ""
    
    @State private var selectedItems: [PhotosPickerItem?] = [nil, nil, nil]
    @State private var selectedImages: [UIImage?] = [nil, nil, nil]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // MARK: - Form Section
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Formulir Pesanan")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                
                                Spacer()
                                
                                Button(action: {
                                    if let clipboard = UIPasteboard.general.string {
                                        formPesanan = clipboard
                                    }
                                }) {
                                    Label("Tempel", systemImage: "list.clipboard.fill")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .padding(8)
                                        .labelStyle(.titleAndIcon)
                                        .foregroundColor(.white)
                                        .background(.blue)
                                        .cornerRadius(20)
                                }
                            }
                            
                            TextEditor(text: $formPesanan)
                                .padding(3)
                                .frame(height: geometry.size.height / 3)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 0.5)
                                )
                                .overlay(
                                    Group {
                                        if formPesanan.isEmpty {
                                            Text("Tempel formulir pesanan anda di sini ✨")
                                                .foregroundColor(.gray)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 12)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                    }
                                )
                        }
                        
                        PhotoSection(
                            selectedItems: $selectedItems,
                            selectedImages: $selectedImages
                        )
                        
                        if let error = viewModel.errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(error)
                                    .font(.footnote)
                            }
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                }
                
                // MARK: - Submit Button
                Button(action: {
                    Task {
                        await viewModel.parseOrder(text: formPesanan)
                    }
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                        Text("Tinjau Pesanan")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(30)
                    .padding(.horizontal)
                    .shadow(radius: 5)
                }
                .disabled(viewModel.isLoading || formPesanan.isEmpty)
            }
            .navigationTitle("Add New Order")
            .task {
                viewModel.configure(userId: session.userId)
            }
            .navigationDestination(isPresented: $viewModel.navigateToConfirm) {
                if let parsedData = viewModel.parsedOrderData {
                    EditOrderView(
                        parsedOrderData: parsedData,
                        selectedImages: $selectedImages
                    )
                }
            }
        }
    }
}

#Preview {
    let session = SessionManager()
    session.isSignedIn = true
    session.userId = "083dc90d-ca03-4f45-a631-06fe21fe750f"
    
    return NewOrderView()
        .environmentObject(session)
}
