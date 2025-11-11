//
//  InputMenuView.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 06/11/25.
//

import SwiftUI
import UniformTypeIdentifiers
import UIKit
import Foundation
import PDFKit

enum SubmitState: Equatable {
    case idle
    case loading
    case success
    case failure(String)
}

struct UploadedFileItem: Identifiable {
    let id = UUID()
    let url: URL
    let fileName: String
    let fileSize: String
    let isPDF: Bool
}

struct InputMenuView: View {
    @State private var uploadedFiles: [UploadedFileItem] = []
    @State private var isFileImporterPresented = false
    @State private var isPhotoPickerPresented = false
    @State private var isCameraPresented = false
    @State private var showUploadOptions = false
    @State private var navigateToConfirm = false
    @EnvironmentObject var session: SessionManager
    @Environment(\.dismiss) private var dismiss
    @State private var submitState: SubmitState = .idle
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var scannedCategories: [MenuCategory] = []
    
    @Binding var isDismissed: Bool
    
    var viewModel = InputMenuViewModel()
    
    var body: some View {
        mainContent
            .navigationTitle("Rincian Menu / Katalog")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                viewModel.configure(userId: session.userId)
            }
            .fileImporter(
                isPresented: $isFileImporterPresented,
                allowedContentTypes: [.pdf, .image],
                allowsMultipleSelection: true
            ) { result in
                handleFileImport(result)
            }
            .sheet(isPresented: $isPhotoPickerPresented) {
                ImagePicker(sourceType: .photoLibrary) { url in
                    if let url = url {
                        addFile(url: url)
                    }
                }
            }
//            .sheet(isPresented: $isCameraPresented) {
//                ImagePicker(sourceType: .camera) { url in
//                    if let url = url {
//                        addFile(url: url)
//                    }
//                }
//            }
            .confirmationDialog("Pilih Sumber File", isPresented: $showUploadOptions, titleVisibility: .visible) {
                Button("Pilih File PDF") { isFileImporterPresented = true }
                Button("Pilih Gambar dari Galeri") { isPhotoPickerPresented = true }
//                Button("Ambil Foto") { isCameraPresented = true }
                Button("Batal", role: .cancel) {}
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .navigationDestination(isPresented: $navigateToConfirm) {
                ConfirmMenuView(isDismissed: $isDismissed, scannedCategories: scannedCategories)
            }
    }
    
    // ✅ MARK: - Main Content
    private var mainContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                uploadSection
                Spacer().frame(height: 40)
                submitButton
            }
            .padding(.vertical)
        }
    }
    
    // ✅ MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Input List Harga")
                .font(.title)
                .bold()
                .padding(.horizontal)
            
            Text("Menu / Katalog :")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
    }
    
    // ✅ MARK: - Upload Section
    @ViewBuilder
    private var uploadSection: some View {
        if uploadedFiles.isEmpty {
            emptyStateView
        } else {
            uploadedFilesView
        }
    }
    
    // ✅ MARK: - Empty State
    private var emptyStateView: some View {
        RoundedRectangle(cornerRadius: 12)
            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
            .foregroundColor(.blue)
            .frame(height: 200)
            .overlay(
                VStack(spacing: 12) {
                    Image(systemName: "arrow.up.doc.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("Unggah katalog bisnis anda di sini untuk\nmenyimpan daftar produk dan harga.")
                        .font(.body)
                        .foregroundColor(.blue)
                        .multilineTextAlignment(.center)
                    
                    Text("format PDF, JPEG, dan PNG, sampai dengan 25 MB.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            )
            .padding(.horizontal)
            .onTapGesture {
                showUploadOptions = true
            }
    }
    
    // ✅ MARK: - Uploaded Files View
    private var uploadedFilesView: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(uploadedFiles) { file in
                fileRow(file: file)
            }
            
            // Uncomment if you want to allow adding more files
            // addMoreButton
        }
        .padding(.horizontal)
    }
    
    // ✅ MARK: - File Row
    private func fileRow(file: UploadedFileItem) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Text("PDF")
                    .font(.caption)
                    .bold()
                    .foregroundColor(.red)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(file.fileName)
                    .font(.body)
                    .lineLimit(1)
                
                Text(file.fileSize)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ProgressView(value: 1.0)
                    .progressViewStyle(.linear)
                    .tint(.blue)
            }
            
            Spacer()
            
            Button(action: {
                uploadedFiles.removeAll { $0.id == file.id }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
                    .font(.title3)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // ✅ MARK: - Submit Button
    private var submitButton: some View {
        Button(action: {
            submitFiles()
        }) {
            if submitState == .loading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 55)
                    .tint(.white)
            } else {
                Text("Pindai Katalog")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 55)
            }
        }
        .buttonStyle(.borderedProminent)
        .disabled(uploadedFiles.isEmpty || submitState == .loading)
        .padding(.horizontal)
    }
    
    // ✅ MARK: - Add More Button (optional)
    private var addMoreButton: some View {
        Button(action: {
            showUploadOptions = true
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Tambah File")
            }
            .font(.body)
            .foregroundColor(.blue)
        }
    }
    
    // MARK: - Helper Functions
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                addFile(url: url)
            }
        case .failure(let error):
            errorMessage = "Failed to import file: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }
    
    private func addFile(url: URL) {
        let fileName = url.lastPathComponent
        let fileSize = getFileSize(url: url)
        let isPDF = url.pathExtension.lowercased() == "pdf"
        
        let item = UploadedFileItem(
            url: url,
            fileName: fileName,
            fileSize: fileSize,
            isPDF: isPDF
        )
        uploadedFiles.append(item)
    }
    
    private func getFileSize(url: URL) -> String {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? Int64 else {
            return "00 MB of 00 MB"
        }
        let sizeInMB = Double(fileSize) / (1024 * 1024)
        return String(format: "%.2f MB of 25 MB", sizeInMB)
    }
    
    private func submitFiles() {
        submitState = .loading
        
        Task {
            var convertedUrls: [URL] = []
            
            for file in uploadedFiles {
                if file.isPDF {
                    let images = viewModel.pdfToImages(pdfUrl: file.url)
                    for (index, image) in images.enumerated() {
                        let tempUrl = FileManager.default.temporaryDirectory
                            .appendingPathComponent("\(file.id)_page\(index).jpg")
                        if let data = image.jpegData(compressionQuality: 0.8) {
                            try? data.write(to: tempUrl)
                            convertedUrls.append(tempUrl)
                        }
                    }
                } else {
                    convertedUrls.append(file.url)
                }
            }
            
            var uploadedPublicUrls: [String] = []
            
            for url in convertedUrls {
                viewModel.uploadMenu(fileUrl: url) { result in
                    switch result {
                    case .success(let publicUrl):
                        uploadedPublicUrls.append(publicUrl)
                        
                        if uploadedPublicUrls.count == convertedUrls.count {
                            scanAllFiles(urls: uploadedPublicUrls)
                        }
                        
                    case .failure(let error):
                        submitState = .failure("Upload failed: \(error.localizedDescription)")
                        errorMessage = "Upload failed: \(error.localizedDescription)"
                        showErrorAlert = true
                    }
                }
            }
        }
    }
    
    private func scanAllFiles(urls: [String]) {
        viewModel.menuScanBatch(imageUrls: urls) { scanResult in
            if let scanResult = scanResult {
                if let jsonData = scanResult.data(using: .utf8),
                   let response = try? JSONDecoder().decode(MenuScanResponse.self, from: jsonData) {
                    scannedCategories = response.categories
                    navigateToConfirm = true
                    submitState = .success
                } else {
                    submitState = .failure("Failed to parse scan result")
                    errorMessage = "Failed to parse menu data"
                    showErrorAlert = true
                }
            } else {
                submitState = .failure("Scan failed")
                errorMessage = "Scan failed. Please try again."
                showErrorAlert = true
            }
        }
    }
}

// MARK: - UIImagePickerController wrapper
struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    var completion: (URL?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var completion: (URL?) -> Void

        init(completion: @escaping (URL?) -> Void) {
            self.completion = completion
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                if let data = image.jpegData(compressionQuality: 0.8) {
                    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
                    try? data.write(to: url)
                    completion(url)
                } else {
                    completion(nil)
                }
            } else {
                completion(nil)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            completion(nil)
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    let session = SessionManager()
    session.isSignedIn = true
    session.userId = "083dc90d-ca03-4f45-a631-06fe21fe750f"

    let dismiss = Binding.constant(false)

    return NavigationStack {
        InputMenuView(isDismissed: dismiss)
            .environmentObject(session)
    }
}
