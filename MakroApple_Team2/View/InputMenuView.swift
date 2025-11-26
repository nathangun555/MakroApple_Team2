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
    @State private var showLoading = false
    @State private var navigateToConfirm = false
    @State private var showManualInput = false
    @EnvironmentObject var session: SessionManager
    @Environment(\.dismiss) private var dismiss
    @State private var submitState: SubmitState = .idle
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var scannedCategories: [MenuCategory] = []
    
    @Binding var isDismissed: Bool
    
    @State var viewModel = InputMenuViewModel()
    
    var body: some View {
        mainContent
            .navigationTitle("Rincian Menu / Katalog")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .task { viewModel.configure(userId: session.userId) }
            .fileImporter(
                isPresented: $showUploadOptions,
                allowedContentTypes: [.pdf], // Only allow PDFs
                allowsMultipleSelection: true
            ) { result in
                handleFileImport(result)
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                  Button {
                      dismiss()
                  } label: {
                    Image(systemName: "chevron.left")
                          .font(.title3)
                      .foregroundStyle(.primaryButton)
                  }
                }
                ToolbarItem {
                    if !uploadedFiles.isEmpty {
                        
                        Button(action: {
                            submitFiles()
                        }){
                            Image(systemName: "chevron.right")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(Color.primaryButton)
                        
                    }
                    
                    else {
                        Button(action: {
                            
                        }){
                            Image(systemName: "chevron.right")
                                .font(.title3)
                                .foregroundColor(.primaryButton)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(.white)
                    }
                }
            }
            .navigationDestination(isPresented: $showLoading) {
                LoadingView(model: viewModel, context: "menu")
            }
            .navigationDestination(isPresented: $navigateToConfirm) {
                ConfirmMenuView(isDismissed: $isDismissed, scannedCategories: scannedCategories, manualInput: false)
            }
            .navigationDestination(isPresented: $showManualInput) {
                ConfirmMenuView(isDismissed: $isDismissed, scannedCategories: scannedCategories, manualInput: true)
            }
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                uploadSection
                
                Button {
                    showManualInput = true
                } label: {
                    Text("Atau buat menu / katalog secara manual")
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .underline(true)
                }
                .padding(.horizontal)
                
                Spacer()

            }
            .padding(.vertical)
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Input List Harga")
                .font(.body)
                .bold()
            
            Text("Menu / Katalog :")
                .font(.footnote)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Upload Section
    @ViewBuilder
    private var uploadSection: some View {
        if uploadedFiles.isEmpty { emptyStateView } else { uploadedFilesView }
    }
    
    private var emptyStateView: some View {
        RoundedRectangle(cornerRadius: 12)
            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
            .foregroundColor(.gray)
            .frame(height: 120)
            .overlay(
                VStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.up.fill")
                        .font(.headline)
                        .foregroundColor(.primaryButton)
                    Text("Unggah katalog bisnis anda di sini untuk\nmenyimpan daftar produk dan harga.")
                        .font(.subheadline)
                        .foregroundColor(.primaryButton)
                        .multilineTextAlignment(.center)
                    Text("Format PDF maksimal 10 MB.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            )
            .padding(.horizontal)
            .onTapGesture { showUploadOptions = true }
            .background(Color.gray.opacity(0.05))
    }
    
    private var uploadedFilesView: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(uploadedFiles) { file in
                fileRow(file: file)
            }
        }
        .padding(.horizontal)
    }
    
    private func fileRow(file: UploadedFileItem) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 50, height: 50)
                    .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                
                Text(file.isPDF ? "PDF" : "IMG")
                    .font(.caption)
                    .bold()
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(file.fileName)
                    .font(.footnote)
                    .lineLimit(1)
                Text(file.fileSize)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
            }
            
            Spacer()
            
            Button(action: {
                uploadedFiles.removeAll { $0.id == file.id }
            }) {
                Image(systemName: "trash.fill")
                    .foregroundColor(.gray)
                    .font(.footnote)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Helper
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls): urls.forEach { addFile(url: $0) }
        case .failure(let error):
            errorMessage = "Failed to import file: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }
    
    private func addFile(url: URL) {
        let fileName = url.lastPathComponent
        let fileSize = getFileSize(url: url)
        let isPDF = url.pathExtension.lowercased() == "pdf"
        guard isPDF else {
            errorMessage = "Only PDF files are allowed."
            showErrorAlert = true
            return
        }
        let item = UploadedFileItem(url: url, fileName: fileName, fileSize: fileSize, isPDF: isPDF)
        uploadedFiles.append(item)
    }
    
    private func getFileSize(url: URL) -> String {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? Int64 else {
            return "00 MB of 10 MB"
        }
        let sizeInMB = Double(fileSize) / (1024 * 1024)
        return String(format: "%.2f MB of 10 MB", sizeInMB)
    }
    
    // MARK: - Merge categories utility
    private func mergeCategoriesForApp(_ newCats: [MenuCategory]) {
        for cat in newCats {
            if let idx = scannedCategories.firstIndex(where: {
                $0.categoryName.caseInsensitiveCompare(cat.categoryName) == .orderedSame
            }) {
                // Salin ke var, lalu buat array products yang mutable
                var existing = scannedCategories[idx]
                var mergedProducts = existing.products  // salinan mutable

                var seen = Set(mergedProducts.map { "\($0.name)@@\($0.price)" })
                for p in cat.products {
                    let sig = "\(p.name)@@\(p.price)"
                    if !seen.contains(sig) {
                        mergedProducts.append(p)
                        seen.insert(sig)
                    }
                }

                // Assign kembali dengan struct baru (immutability-safe)
                scannedCategories[idx] = MenuCategory(
                    categoryName: existing.categoryName,
                    products: mergedProducts
                )
            } else {
                scannedCategories.append(cat)
            }
        }
    }

    
    // MARK: - Submit (upload -> scan per-batch 1 URL)
    private func submitFiles() {
        submitState = .loading
        showLoading = true
        Task {
            do {
                // 1) Konversi PDF -> JPG lokal
                var convertedUrls: [URL] = []
                for file in uploadedFiles {
                    if file.isPDF {
                        let images = viewModel.pdfToImages(pdfUrl: file.url)
                        for (index, image) in images.enumerated() {
                            let temp = FileManager.default.temporaryDirectory.appendingPathComponent("\(file.id)_page\(index).jpg")
                            if let data = image.jpegData(compressionQuality: 0.8) { try? data.write(to: temp); convertedUrls.append(temp) }
                        }
                        viewModel.setProgress(0.25)
                    } else {
                        convertedUrls.append(file.url)
                    }
                }

                // 2) Upload lalu scan per-URL (serial)
                scannedCategories = []
                for (i, localUrl) in convertedUrls.enumerated() {
                    let publicUrl = try await withCheckedThrowingContinuation { cont in
                        viewModel.uploadMenu(fileUrl: localUrl) { result in
                            switch result {
                            case .success(let url):
                                let progress = 0.25 + (0.50 * Double(i+1) / Double(convertedUrls.count))
                                viewModel.setProgress(progress)
                                cont.resume(returning: url)
                            case .failure(let err): cont.resume(throwing: err)
                            }
                        }
                    }

                    let scanJson = try await withCheckedThrowingContinuation { cont in
                        viewModel.menuScanBatch(imageUrls: [publicUrl]) { json in
                            if let json {
                                cont.resume(returning: json)
                            }
                            else { cont.resume(throwing: NSError(domain: "scan", code: -1, userInfo: [NSLocalizedDescriptionKey: "Scan failed"])) }
                        }
                    }

                    if let data = scanJson.data(using: .utf8),
                       let resp = try? JSONDecoder().decode(MenuScanResponse.self, from: data) {
                        mergeCategoriesForApp(resp.categories)
                    }

                    print("Progress \(i+1)/\(convertedUrls.count)")
                }
                viewModel.setProgress(1.0)
                navigateToConfirm = true
                showLoading = false
                submitState = .success
            } catch {
                submitState = .failure(error.localizedDescription)
                errorMessage = error.localizedDescription
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
