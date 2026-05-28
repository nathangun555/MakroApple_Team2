import SwiftUI
import PhotosUI

struct PhotoSection: View {
    @Binding var selectedItems: [PhotosPickerItem?]
    @Binding var selectedImages: [UIImage?]
    private let maxPhotos = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                                    get: {
                                        selectedItems[index]
                                    },
                                    set: { newValue in
                                        updateItem(newValue, at: index)
                                        Task { await loadImage(for: index) }
                                    }
                                ),
                                matching: .images
                            ) {
                                VStack {
                                    Image(systemName: "photo.badge.plus")
                                        .font(.title)
                                }
                                .frame(width: 115, height: 115)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                                        .foregroundColor(.secondary)
                                        .background(.gray.opacity(0.1))
                                )
                            }
                        }
                    }
                }
            }
            .onChange(of: selectedImages) { _ in
                syncSlots()
            }
            .onAppear {
                syncSlots(initial: true)
            }
        }
    }

    private func updateItem(_ item: PhotosPickerItem?, at index: Int) {
        if index < selectedItems.count {
            selectedItems[index] = item
        } else {
            selectedItems.append(item)
        }
    }

    private func loadImage(for index: Int) async {
        guard let item = selectedItems[safe: index] else { return }
        if let data = try? await item?.loadTransferable(type: Data.self),
           let uiImage = UIImage(data: data) {
            selectedImages[index] = uiImage
        }
        syncSlots()
    }

    private func removePhoto(at index: Int) {
        if selectedImages.indices.contains(index) {
            selectedImages.remove(at: index)
            selectedItems.remove(at: index)
        }
        syncSlots()
    }

    /// Sinkronisir slot foto sesuai aturan (1 slot kosong, max 3 total)
    private func syncSlots(initial: Bool = false) {
        let images = selectedImages.compactMap { $0 } // Hapus semua nil
        if images.count < maxPhotos {
            selectedImages = images + [nil] // Tambah 1 slot
            selectedItems = selectedItems.prefix(images.count) + [nil]
        } else {
            selectedImages = Array(images.prefix(maxPhotos))
            selectedItems = Array(selectedItems.prefix(maxPhotos))
        }

        if initial && selectedImages.isEmpty {
            selectedImages = [nil] // Slot awal
            selectedItems = [nil]
        }
    }
}

extension Array {
    subscript(safe index: Index) -> Element? {
        get {
            indices.contains(index) ? self[index] : nil
        }
        set {
            if indices.contains(index), let newValue = newValue {
                self[index] = newValue
            }
        }
    }
}
