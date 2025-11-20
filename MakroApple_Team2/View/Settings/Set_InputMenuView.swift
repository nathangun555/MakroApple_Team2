//
//  Set_InputMenuView.swift
//  MakroApple_Team2
//
//  Created for Settings flow
//

import SwiftUI
import UniformTypeIdentifiers
import UIKit
import Foundation
import PDFKit

struct Set_InputMenuView: View {
    @State private var uploadedFiles: [UploadedFileItem] = []
    @State private var isFileImporterPresented = false
    @State private var isPhotoPickerPresented = false
    @State private var showUploadOptions = false
    @State private var showConfirmMenu = false
    @State private var showManualInput = false
    @State private var submitState: SubmitState = .idle
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var scannedCategories: [MenuCategory] = []
    
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var deleteBus: DeleteOverlayBus
    @EnvironmentObject var unsavedBus: UnsavedOverlayBus
    @Environment(\.dismiss) private var dismiss
    
    @Binding var isDismissed: Bool
    
    @State private var viewModel = InputMenuViewModel()
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Rincian Menu / Katalog")
                            .font(.title2.bold())
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            if !uploadedFiles.isEmpty {
                                unsavedBus.request(
                                    title: "Batal Upload?",
                                    message: "File yang sudah dipilih akan hilang",
                                    cancelTitle: "Tidak",
                                    confirmTitle: "Ya",
                                    onCancel: { /* stay */ },
                                    onConfirm: { dismiss() }
                                )
                            } else {
                                dismiss()
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                                .foregroundColor(.primaryButton)
                        }
                    }
                }
                .task { viewModel.configure(userId: session.userId) }
                .fileImporter(
                    isPresented: $showUploadOptions,
                    allowedContentTypes: [.pdf],
                    allowsMultipleSelection: true
                ) { result in
                    handleFileImport(result)
                }
                .alert("Error", isPresented: $showErrorAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(errorMessage)
                }
                .fullScreenCover(isPresented: $showConfirmMenu) {
                    Set_ConfirmMenuView(isDismissed: $isDismissed, scannedCategories: scannedCategories)
                        .environmentObject(session)
                        .environmentObject(deleteBus)
                        .environmentObject(unsavedBus)
                }
                .fullScreenCover(isPresented: $showManualInput) {
                    Set_ManualInputView(isDismissed: $isDismissed)
                        .environmentObject(session)
                        .environmentObject(deleteBus)
                        .environmentObject(unsavedBus)
                }
        }
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                uploadSection
                
                // Manual Input Button
                Button {
                    showManualInput = true
                } label: {
                    HStack {
                        Image(systemName: "square.and.pencil")
                        Text("Buat Menu Manual")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .foregroundColor(.primaryButton)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer().frame(height: 20)
                submitButton
            }
            .padding(.vertical)
        }
        .scrollContentBackground(.hidden)
        .background(Color.white)
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Input List Harga")
                .font(.title2.bold())
                .padding(.horizontal)
            
            Text("Unggah katalog atau buat manual:")
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
            .foregroundColor(.gray)
            .frame(height: 200)
            .overlay(
                VStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.up.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.primaryButton)
                    Text("Unggah katalog bisnis anda di sini untuk\nmenyimpan daftar produk dan harga.")
                        .font(.body)
                        .foregroundColor(.primaryButton)
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
        .tint(.primaryButton)
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
        let item = UploadedFileItem(url: url, fileName: fileName, fileSize: fileSize, isPDF: isPDF)
        uploadedFiles.append(item)
    }
    
    private func getFileSize(url: URL) -> String {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? Int64 else {
            return "00 MB of 25 MB"
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
    
    // MARK: - Submit (upload -> scan per-batch 1 URL)
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
                            else { cont.resume(throwing: NSError(domain: "scan", code: -1, userInfo: [NSLocalizedDescriptionKey: "Scan failed"])) }
                        }
                    }

                    if let data = scanJson.data(using: .utf8),
                       let resp = try? JSONDecoder().decode(MenuScanResponse.self, from: data) {
                        mergeCategoriesForApp(resp.categories)
                    }

                    print("Progress \(i+1)/\(convertedUrls.count)")
                }

                submitState = .success
                showConfirmMenu = true
            } catch {
                submitState = .failure(error.localizedDescription)
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
}

#Preview {
    let session = SessionManager()
    session.isSignedIn = true
    session.userId = "083dc90d-ca03-4f45-a631-06fe21fe750f"
    
    return Set_InputMenuView(isDismissed: .constant(false))
        .environmentObject(session)
        .environmentObject(DeleteOverlayBus())
        .environmentObject(UnsavedOverlayBus())
}
