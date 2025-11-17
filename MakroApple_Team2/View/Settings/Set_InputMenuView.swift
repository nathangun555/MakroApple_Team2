//
//  Set_InputMenuView.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 16/11/25.
//

import SwiftUI
import UniformTypeIdentifiers
import UIKit
import Foundation
import PDFKit

enum SetSubmitState: Equatable {
    case idle
    case loading
    case success
    case failure(String)
}

struct SetUploadedFileItem: Identifiable {
    let id = UUID()
    let url: URL
    let fileName: String
    let fileSize: String
    let isPDF: Bool
}

struct Set_InputMenuView: View {
    @State private var uploadedFiles: [SetUploadedFileItem] = []
    @State private var isFileImporterPresented = false
    @State private var isPhotoPickerPresented = false
    @State private var showUploadOptions = false

    @EnvironmentObject var session: SessionManager
    @Environment(\.dismiss) private var dismiss

    @State private var submitState: SetSubmitState = .idle
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var scannedCategories: [MenuCategory] = []

    // Navigasi ke Confirm (bukan ke MenuDetails)
    @State private var navigateToConfirm = false

    @Binding var isDismissed: Bool

    var viewModel = Set_InputMenuViewModel()

    var body: some View {
        mainContent
            .navigationTitle("Rincian Menu / Katalog")
            .navigationBarTitleDisplayMode(.inline)
            .task { viewModel.configure(userId: session.userId) }
            .fileImporter(
                isPresented: $isFileImporterPresented,
                allowedContentTypes: [.pdf, .image],
                allowsMultipleSelection: true
            ) { result in
                handleFileImport(result)
            }
            .sheet(isPresented: $isPhotoPickerPresented) {
                SetImagePicker(sourceType: .photoLibrary) { url in
                    if let url = url { addFile(url: url) }
                }
            }
            .confirmationDialog("Pilih Sumber File", isPresented: $showUploadOptions, titleVisibility: .visible) {
                Button("Pilih File PDF") { isFileImporterPresented = true }
                Button("Pilih Gambar dari Galeri") { isPhotoPickerPresented = true }
                Button("Batal", role: .cancel) {}
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .navigationDestination(isPresented: $navigateToConfirm) {
                Set_ConfirmMenuView(
                    scannedCategories: scannedCategories,
                    onAfterSave: {
                        // Pop Confirm
                        dismiss()
                        // Pop Input (kembali ke Settings)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            dismiss()
                        }
                    }
                )
                .environmentObject(session)
//                .environmentObject(DeleteOverlayBus())
//                .environmentObject(UnsavedOverlayBus())
            }
    }

    // MARK: - Main Content
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

    // MARK: - Header
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

    // MARK: - Upload Section
    @ViewBuilder
    private var uploadSection: some View {
        if uploadedFiles.isEmpty { emptyStateView } else { uploadedFilesView }
    }

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
            .onTapGesture { showUploadOptions = true }
    }

    private var uploadedFilesView: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(uploadedFiles) { file in
                fileRow(file: file)
            }
        }
        .padding(.horizontal)
    }

    private func fileRow(file: SetUploadedFileItem) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 50, height: 50)
                Text(file.isPDF ? "PDF" : "IMG")
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

    private var submitButton: some View {
        Button(action: { submitFiles() }) {
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
        let item = SetUploadedFileItem(url: url, fileName: fileName, fileSize: fileSize, isPDF: isPDF)
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

    private func mergeCategoriesForApp(_ newCats: [MenuCategory]) {
        for cat in newCats {
            if let idx = scannedCategories.firstIndex(where: {
                $0.categoryName.caseInsensitiveCompare(cat.categoryName) == .orderedSame
            }) {
                var existing = scannedCategories[idx]
                var mergedProducts = existing.products
                var seen = Set(mergedProducts.map { "\($0.name)@@\($0.price)" })
                for p in cat.products {
                    let sig = "\(p.name)@@\(p.price)"
                    if !seen.contains(sig) {
                        mergedProducts.append(p)
                        seen.insert(sig)
                    }
                }
                scannedCategories[idx] = MenuCategory(
                    categoryName: existing.categoryName,
                    products: mergedProducts
                )
            } else {
                scannedCategories.append(cat)
            }
        }
    }

    // MARK: - Submit (upload -> scan per-batch 1 URL) → lanjut ke Confirm
    private func submitFiles() {
        submitState = .loading
        Task {
            do {
                var convertedUrls: [URL] = []
                for file in uploadedFiles {
                    if file.isPDF {
                        let images = viewModel.pdfToImages(pdfUrl: file.url)
                        for (index, image) in images.enumerated() {
                            let temp = FileManager.default.temporaryDirectory.appendingPathComponent("\(file.id)_page\(index).jpg")
                            if let data = image.jpegData(compressionQuality: 0.8) {
                                try? data.write(to: temp)
                                convertedUrls.append(temp)
                            }
                        }
                    } else {
                        convertedUrls.append(file.url)
                    }
                }

                scannedCategories = []
                for (i, localUrl) in convertedUrls.enumerated() {
                    let publicUrl = try await withCheckedThrowingContinuation { cont in
                        viewModel.uploadMenu(fileUrl: localUrl) { result in
                            switch result {
                            case .success(let url): cont.resume(returning: url)
                            case .failure(let err): cont.resume(throwing: err)
                            }
                        }
                    }

                    let scanJson = try await withCheckedThrowingContinuation { cont in
                        viewModel.menuScanBatch(imageUrls: [publicUrl]) { json in
                            if let json { cont.resume(returning: json) }
                            else {
                                cont.resume(throwing: NSError(
                                    domain: "scan",
                                    code: -1,
                                    userInfo: [NSLocalizedDescriptionKey: "Scan failed"]
                                ))
                            }
                        }
                    }

                    if let data = scanJson.data(using: .utf8),
                       let resp = try? JSONDecoder().decode(MenuScanResponse.self, from: data) {
                        mergeCategoriesForApp(resp.categories)
                    }

                    print("Progress \(i+1)/\(convertedUrls.count)")
                }

                submitState = .success
                navigateToConfirm = true
            } catch {
                submitState = .failure(error.localizedDescription)
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
}

// MARK: - UIImagePickerController wrapper (prefixed to avoid clashes)
struct SetImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    var completion: (URL?) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(completion: completion) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var completion: (URL?) -> Void
        init(completion: @escaping (URL?) -> Void) { self.completion = completion }

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
