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
    
    @State private var selectedItems: [PhotosPickerItem?] = [nil]
    @State private var selectedImages: [UIImage?] = [nil]

    @State private var savedImagePaths: [URL?] = [nil]
    @State private var isLoading = false
    @State private var resultJSON: String? = nil
    @State private var errorMessage: String? = nil
    
    @Binding var sharedText: String
    @Binding var sharedImages: [UIImage]
    @Binding var isDismissed: Bool
    
    let edgeFunctionURL = URL(string: "https://iznjcwyoziqjgfjahemb.supabase.co/functions/v1/form-template")!
    
    @FocusState private var isTextEditorFocused: Bool

    
    var body: some View {
        // flag to show that this is the latest iwak's code
        ZStack{
            
            ZStack(alignment: .bottom){
                ScrollView{
                    VStack(alignment: .leading){
                        HStack{
                            
                            
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
                                    .background(.primaryButton)
                                    .cornerRadius(20)
                            }
                        }
                        
                        
                        ZStack(alignment: .topLeading) {
                            
                            
                            TextEditor(text: $formPesanan)
                                .padding(8)
                                .frame(minHeight: 200)
                                .focused($isTextEditorFocused)
                            
                            if formPesanan.isEmpty && !isTextEditorFocused {
                                    Text("Tempel formulir pesanan anda di sini ✨")
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 12)
                                }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.4), lineWidth: 0.8)
                        )
                        
                        
                        
                        
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
//                Button(action: {
//                    Task {
//                        await viewModel.parseOrder(text: formPesanan)
//                    }
//                }) {
//                    HStack {
//                        if viewModel.isLoading {
//                            ProgressView()
//                                .tint(.white)
//                        }
//                        Text("Tinjau Pesanan")
//                            .fontWeight(.semibold)
//                    }
//                    .frame(maxWidth: .infinity)
//                    .padding()
//                    .background(Color.primaryButton)
//                    .foregroundColor(.white)
//                    .cornerRadius(30)
//                    .padding(.horizontal)
//                    .shadow(radius: 5)
//                }
//                .disabled(viewModel.isLoading || formPesanan.isEmpty)
            }
            
            .onAppear {
                
                // Load shared text if exists
                if !sharedText.isEmpty && formPesanan.isEmpty {
                    formPesanan = sharedText
                    print("📥 Initial shared text loaded into formPesanan: \(sharedText)")
                }

                // Load shared images into the photo picker
                if !sharedImages.isEmpty {
                    for (index, image) in sharedImages.prefix(3).enumerated() {
                        selectedImages[index] = image
                    } 
                    print("📸 Auto-filled shared images into photo slots")
                }
            }

            .onChange(of: sharedText) { newValue in
                print("SHARED TEXT INSIDE THE NEW ORDER \(newValue)")
                formPesanan = newValue
            }
        }
        
//        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SharedTextReceived"))) { notif in
//            if let text = notif.object as? String {
//                formPesanan = text    // paste into TextEditor
//            }
//        }
        
        .navigationTitle("Add New Order")
        .task {
            viewModel.configure(userId: session.userId)
        }
        .navigationDestination(isPresented: $viewModel.navigateToConfirm) {
            if let parsedData = viewModel.parsedOrderData {
                EditOrderView(
                    parsedOrderData: parsedData,
                    
                    selectedImages: $selectedImages,
                    selectedItems : $selectedItems,
                    isDismissed: $isDismissed
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    isDismissed = true
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
                
//                .buttonStyle(.glassProminent)
                .disabled(viewModel.isLoading)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        await viewModel.parseOrder(text: formPesanan)
                    }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    else {
                        Image(systemName: "chevron.right")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                    
                        
                }
                .buttonStyle(.glassProminent)
                .disabled(viewModel.isLoading || formPesanan.isEmpty)
                .tint(.primaryButton)
            }
        }
        
    }
    
    private func cleanUpEmptySlots() {
        // Remove all trailing nils except one at the end
        while selectedImages.count > 1, selectedImages.last == nil, selectedImages.dropLast().contains(nil) {
            selectedImages.removeLast()
            selectedItems.removeLast()
            savedImagePaths.removeLast()
        }
        
        // Always ensure exactly one empty slot at the end
        if selectedImages.last != nil {
            selectedImages.append(nil)
            selectedItems.append(nil)
            savedImagePaths.append(nil)
        }
    }
}


#Preview {
    // Dummy bindings
    @State var sharedText = ""
    @State var sharedImages: [UIImage] = []
    @State var isDismissed = false

    // Dummy environment object
    let session = SessionManager()
    session.userId = "dummyUserId" // wajib ada karena view butuh @EnvironmentObject

    return NavigationStack {
        NewOrderView(
            sharedText: $sharedText,
            sharedImages: $sharedImages,
            isDismissed: $isDismissed
        )
        .environmentObject(session)
    }
}
