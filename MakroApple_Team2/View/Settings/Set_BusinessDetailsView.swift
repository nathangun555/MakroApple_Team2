//
//  Set_BusinessDetailsView.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 17/10/25.
//

import SwiftUI
import PhotosUI

private struct RowDivider: View {
  var body: some View { Rectangle().fill(Color(.separator)).frame(height: 0.5) }
}

private struct PillTextField: View {
  let placeholder: String
  @Binding var text: String
  var keyboard: UIKeyboardType = .default
  var contentType: UITextContentType? = nil
  var autocap: TextInputAutocapitalization? = .sentences
  var autocorrect: Bool = true

  var body: some View {
    TextField(placeholder, text: $text)
      .textInputAutocapitalization(autocap)
      .autocorrectionDisabled(!autocorrect)
      .keyboardType(keyboard)
      .textContentType(contentType)
      .padding(.horizontal, 12)
      .frame(height: 36)
      .background(
        RoundedRectangle(cornerRadius: 12, style: .continuous)
          .fill(Color(.secondarySystemBackground))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 12, style: .continuous)
          .stroke(Color(.separator), lineWidth: 0.8)
      )
  }
}

private struct LabeledRow<Content: View>: View {
  let label: String
  let labelWidth: CGFloat
  @ViewBuilder var field: () -> Content

  var body: some View {
    HStack(alignment: .center, spacing: 12) {
      Text(label)
        .font(.body)
        .frame(width: labelWidth, alignment: .leading)
      field()
    }
    .padding(.vertical, 6)
  }
}

struct Set_BusinessDetailsView: View {
  @EnvironmentObject var session: SessionManager
  @StateObject private var vm = Set_BusinessDetailsViewModel()
  @FocusState private var focusedField: Field?
  
  @State private var selectedPhotoItem: PhotosPickerItem?
  @State private var isUploadingLogo = false

  enum Field: Hashable {
    case businessName, businessPhone, businessAddress, businessLogoUrl, businessEmail
    case bankAccountNumber, bankAccountName, bankName
  }

  private let pagePadding: CGFloat = 16
  private let labelWidth: CGFloat = 120

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 2) {

        Text("Rincian Bisnis")
          .font(.largeTitle.bold())
          .frame(maxWidth: .infinity, alignment: .center)

        // Informasi Bisnis
        Text("Informasi Bisnis")
          .font(.title3).bold()
          .padding(.top, 30)
          .padding(.bottom, 5)

        LabeledRow(label: "Nama Bisnis :", labelWidth: labelWidth) {
          PillTextField(placeholder: "Silakan isi nama bisnis anda",
                        text: $vm.businessName,
                        contentType: .organizationName)
            .focused($focusedField, equals: .businessName)
        }
        RowDivider()

        LabeledRow(label: "Alamat Bisnis :", labelWidth: labelWidth) {
          PillTextField(placeholder: "Silakan isi alamat bisnis anda",
                        text: $vm.businessAddress)
            .focused($focusedField, equals: .businessAddress)
        }
        RowDivider()

        LabeledRow(label: "No Telp Bisnis :", labelWidth: labelWidth) {
          PillTextField(placeholder: "Silakan isi no telp bisnis anda",
                        text: $vm.businessPhone,
                        keyboard: .phonePad,
                        contentType: .telephoneNumber)
            .focused($focusedField, equals: .businessPhone)
        }
        RowDivider()

        LabeledRow(label: "Email Bisnis :", labelWidth: labelWidth) {
          PillTextField(placeholder: "Silakan isi alamat email bisnis anda",
                        text: $vm.businessEmail,
                        keyboard: .emailAddress,
                        contentType: .emailAddress,
                        autocap: .never,
                        autocorrect: false)
            .focused($focusedField, equals: .businessEmail)
        }
        RowDivider()

        LabeledRow(label: "Logo Bisnis :", labelWidth: labelWidth) {
          HStack(spacing: 8) {
            ZStack {
              if vm.businessLogoUrl.isEmpty {
                // Placeholder - bisa di-tap untuk upload
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                  ZStack {
                    RoundedRectangle(cornerRadius: 10)
                      .stroke(style: StrokeStyle(lineWidth: 1, dash: [4]))
                      .foregroundStyle(Color(.tertiaryLabel))
                      .frame(width: 112, height: 112)
                    
                    if isUploadingLogo {
                      ProgressView()
                    } else {
                      VStack(spacing: 4) {
                        Image(systemName: "photo.on.rectangle.angled")
                          .font(.system(size: 24))
                          .foregroundStyle(Color(.secondaryLabel))
                        Text("Upload")
                          .font(.caption)
                          .foregroundStyle(Color(.secondaryLabel))
                      }
                    }
                  }
                }
                .disabled(isUploadingLogo)
              } else {
                // Sudah ada gambar - bisa di-tap untuk ganti
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                  ZStack(alignment: .bottomTrailing) {
                    AsyncImage(url: URL(string: vm.businessLogoUrl)) { phase in
                      switch phase {
                      case .empty:
                        ProgressView()
                          .frame(width: 112, height: 112)
                      case .success(let image):
                        image
                          .resizable()
                          .scaledToFill()
                          .frame(width: 112, height: 112)
                          .clipShape(RoundedRectangle(cornerRadius: 10))
                      case .failure:
                        ZStack {
                          RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.red, lineWidth: 1)
                            .frame(width: 112, height: 112)
                          Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 24))
                            .foregroundStyle(.red)
                        }
                      @unknown default:
                        EmptyView()
                      }
                    }
                    
                    // Icon edit di pojok kanan bawah
                    if !isUploadingLogo {
                      Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.white)
                        .background(Circle().fill(Color.blue))
                        .offset(x: -4, y: -4)
                    } else {
                      ProgressView()
                        .offset(x: -4, y: -4)
                    }
                  }
                }
                .disabled(isUploadingLogo)
              }
            }
            Spacer(minLength: 0)
          }
        }
        .onChange(of: selectedPhotoItem) { newItem in
          Task {
            await vm.uploadLogo(from: newItem, setUploadingFlag: { isUploadingLogo = $0 })
            selectedPhotoItem = nil
          }
        }

        // Informasi Pembayaran
        Text("Informasi Pembayaran")
          .font(.title3).bold()
          .padding(.top, 8)
          .padding(.bottom, 3)

        LabeledRow(label: "Nama Akun :", labelWidth: labelWidth) {
          PillTextField(placeholder: "Silakan isi nama akun anda",
                        text: $vm.bankAccountName)
            .focused($focusedField, equals: .bankAccountName)
        }
        RowDivider()

        LabeledRow(label: "Nomor Rekening :", labelWidth: labelWidth) {
          PillTextField(placeholder: "Silakan isi no rekening anda",
                        text: $vm.bankAccountNumber,
                        keyboard: .numbersAndPunctuation)
            .focused($focusedField, equals: .bankAccountNumber)
        }
        RowDivider()

        LabeledRow(label: "Nama Bank :", labelWidth: labelWidth) {
          PillTextField(placeholder: "Silakan isi nama bank anda",
                        text: $vm.bankName)
            .focused($focusedField, equals: .bankName)
        }

        if let error = vm.errorMessage, !error.isEmpty {
          Text(error).foregroundStyle(.red).padding(.top, 8)
        }
        if vm.saveSuccess {
          Text("Perubahan berhasil disimpan.").foregroundStyle(.green).padding(.top, 2)
        }

        Spacer(minLength: 16)
      }
      .padding(.horizontal, pagePadding)
      .padding(.vertical, 12)
    }
    .navigationTitle("")
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          Task { await vm.save() }
        } label: {
          if vm.isSaving { ProgressView() } else { Text("Save") }
        }
        .disabled(vm.isSaving || vm.isLoading || vm.businessName.trimmingCharacters(in: .whitespaces).isEmpty)
      }
    }
    .task {
      vm.configure(userId: session.userId)
      if let id = session.userId, UUID(uuidString: id) != nil {
        await vm.load()
        focusedField = .businessName
      }
    }
    .onChange(of: vm.businessName) { _ in vm.saveSuccess = false }
    .onChange(of: vm.businessPhone) { _ in vm.saveSuccess = false }
    .onChange(of: vm.businessAddress) { _ in vm.saveSuccess = false }
    .onChange(of: vm.businessLogoUrl) { _ in vm.saveSuccess = false }
    .onChange(of: vm.businessEmail) { _ in vm.saveSuccess = false }
    .onChange(of: vm.bankAccountNumber) { _ in vm.saveSuccess = false }
    .onChange(of: vm.bankAccountName) { _ in vm.saveSuccess = false }
    .onChange(of: vm.bankName) { _ in vm.saveSuccess = false }
  }
}

#Preview {
  let session = SessionManager()
  session.isSignedIn = true
  session.userId = "083dc90d-ca03-4f45-a631-06fe21fe750f"
  return NavigationStack { Set_BusinessDetailsView() }
    .environmentObject(session)
}
