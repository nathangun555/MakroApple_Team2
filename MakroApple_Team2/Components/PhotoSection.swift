//
//  PhotoSection.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 01/11/25.
//

import SwiftUI
import PhotosUI

struct PhotoSection: View {
    @Binding var selectedItems: [PhotosPickerItem?]
    @Binding var selectedImages: [UIImage?]
    
    private let maxPhotos = 3
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Masukkan Foto Referensi")
                .font(.title3)
                .fontWeight(.bold)
            
            HStack(spacing: 12) {
                ForEach(0..<selectedImages.count, id: \.self) { index in
                    VStack {
                        if let image = selectedImages[index] {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 115, height: 115)
                                    .clipped()
                                    .cornerRadius(10)
                                
                                Button(action: {
                                    removePhoto(at: index)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                }
                                .offset(x: 8, y: -8)
                            }
                        } else {
                            PhotosPicker(
                                selection: Binding(
                                    get: { selectedItems[index] },
                                    set: { newValue in
                                        selectedItems[index] = newValue
                                        Task { await loadImage(for: index) }
                                    }
                                ),
                                matching: .images
                            ) {
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
        }
        .onChange(of: selectedImages) { _ in
            updatePhotoSlots()
        }
    }
    
    private func loadImage(for index: Int) async {
        guard let item = selectedItems[index] else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let uiImage = UIImage(data: data) {
            selectedImages[index] = uiImage
            print("✅ Photo \(index + 1) loaded")
        }
    }
    
    private func removePhoto(at index: Int) {
        selectedImages[index] = nil
        selectedItems[index] = nil
        updatePhotoSlots()
    }
    
    private func updatePhotoSlots() {
        // Keep only the real photos and items (non-nil)
        let realPhotos = selectedImages.compactMap { $0 }
        let realItems = selectedItems.enumerated().compactMap { index, item in
            selectedImages[index] != nil ? item : nil
        }

        // Convert back to optional arrays
        selectedImages = realPhotos
        selectedItems = realItems

        // Ensure there is exactly one empty slot at the end if max not reached
        if selectedImages.count < maxPhotos {
            selectedImages.append(nil)
            selectedItems.append(nil)
        }

        // If all deleted, ensure only one slot remains
        if selectedImages.isEmpty {
            selectedImages = [nil]
            selectedItems = [nil]
        }
    }





}
