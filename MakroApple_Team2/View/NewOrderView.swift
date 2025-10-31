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
    @State private var savedImagePaths: [URL?] = [nil, nil, nil]
    
    @State private var isLoading = false
    @State private var resultJSON: String? = nil
    @State private var errorMessage: String? = nil
    
    let edgeFunctionURL = URL(string: "https://iznjcwyoziqjgfjahemb.supabase.co/functions/v1/form-template")!
    
    var body: some View {
        GeometryReader { geometry in
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
                                    .stroke(Color.gray.opacity(5), lineWidth: 0.5)
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

                        
                        
                        Text("Masukkan Foto Referensi")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.top)
                        
                        HStack(spacing: 12) {
                            ForEach(0..<3, id: \.self) { index in
                                VStack {
                                    if let image = selectedImages[index] {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 115, height: 115)
                                            .clipped()
                                            .cornerRadius(10)
                                            .overlay(
                                                Button(action: {
                                                    selectedImages[index] = nil
                                                    selectedItems[index] = nil
                                                    savedImagePaths[index] = nil
                                                }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(.white)
                                                        .background(Color.black.opacity(0.6))
                                                        .clipShape(Circle())
                                                }
                                            )
                                    } else {
                                        PhotosPicker(selection: Binding(
                                            get: { selectedItems[index] },
                                            set: { newValue in
                                                selectedItems[index] = newValue
                                                Task {
                                                    await loadImage(for: index)
                                                }
                                            }
                                        ), matching: .images) {
                                            VStack {
                                                Image(systemName: "photo.badge.plus")
                                                    .font(.title)
                                            }
                                            .foregroundColor(.black)
                                            .frame(width: 115, height: 115)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
                                                    .foregroundStyle(Color.secondary)
                                                    .background(.gray.opacity(0.1))
                                                    .cornerRadius(10)
                                            )
                                        }
                                    }
                                }
                            }
                            
                        }
                        
                        // Info penyimpanan gambar
                        if savedImagePaths.contains(where: { $0 != nil }) {
                            Text("✅ \(savedImagePaths.compactMap { $0 }.count) gambar terunggah.")
                                .font(.footnote)
                                .foregroundColor(.green)
                        }
                    }
                    .padding()
                }
                Button(action: {
                    Task{
                        await viewModel.parseOrder(text: formPesanan)
                        print("saved")
                    }
                }) {
                    Text("Tinjau Pesanan")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(30)
                        .padding(.horizontal)
                        .shadow(radius: 5)
                }
            }
            .navigationTitle("Add New Order")
            .task {
                viewModel.configure(userId: session.userId)
            }
            .navigationDestination(isPresented: $viewModel.navigateToConfirm) {
                EditOrderView(parsedOrderData: viewModel.parsedOrderData ?? [:])
            }
        }
    }
    // 🔹 Fungsi memuat dan menyimpan gambar per slot
    private func loadImage(for index: Int) async {
        guard let item = selectedItems[index] else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let uiImage = UIImage(data: data) {
            selectedImages[index] = uiImage
            if let savedPath = saveImageToDocuments(uiImage) {
                savedImagePaths[index] = savedPath
            }
        }
    }
    
    // 🔹 Fungsi simpan gambar ke Documents
    private func saveImageToDocuments(_ image: UIImage) -> URL? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let filename = UUID().uuidString + ".jpg"
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documents.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            print("✅ Saved image at: \(fileURL)")
            return fileURL
        } catch {
            print("❌ Error saving image: \(error)")
            return nil
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
