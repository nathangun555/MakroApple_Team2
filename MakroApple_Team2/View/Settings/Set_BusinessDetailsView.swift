
import SwiftUI
import PhotosUI


//private struct PillTextField: View 

struct Set_BusinessDetailsView: View {
  @EnvironmentObject var session: SessionManager
  @StateObject private var vm = Set_BusinessDetailsViewModel()
  @FocusState private var focusedField: Field?
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject var unsavedBus: UnsavedOverlayBus 
  @State private var selectedPhotoItem: PhotosPickerItem?
  @State private var isUploadingLogo = false
  @State private var showUnsavedAlert = false
    
  @Binding var isDismissed: Bool

  enum Field: Hashable {
    case businessName, businessPhone, businessAddress, businessLogoUrl, businessEmail
    case bankAccountNumber, bankAccountName, bankName
  }

  private let pagePadding: CGFloat = 16
  private let labelWidth: CGFloat = 120

  var body: some View {
    ZStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 2) {

          // Informasi Bisnis
          Text("Informasi Bisnis")
            .font(.title3).bold()
            .padding(.top, 10)
            .padding(.bottom, 5)

          // Nama Bisnis dengan error
          VStack(alignment: .leading, spacing: 2) {
              LabeledRow(label: "Nama Bisnis :", labelWidth: labelWidth) {
                  AutoGrowingTextEditor(
                    text: $vm.businessName,
                    placeholder: "Silakan isi nama bisnis anda",
                    isEditing: true,
                    font: .system(size: 16),
                    lineHeight: 20,
                    verticalPadding: 4,
                    maxChars: 70,
                    cornerRadius: 12,
                    borderColor: Color(.secondaryLabel),
                    borderWidth: 0.8
                  )
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .focused($focusedField, equals: .businessName)
              }
            if let error = vm.fieldErrors["businessName"] {
                HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.system(size: 12, weight: .semibold))
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                        Spacer()
                    }
                    .padding(.leading, labelWidth + 12)
                    .padding(.top, 0)
                    .padding(.bottom, 5)
            }
          }
          RowDivider()

          // Alamat Bisnis dengan error
          VStack(alignment: .leading, spacing: 2) {
            LabeledRow(label: "Alamat Bisnis :", labelWidth: labelWidth) {
                AutoGrowingTextEditor(
                           text: $vm.businessAddress,
                           placeholder: "Silakan isi nama bisnis anda",
                           isEditing: true,
                           font: .system(size: 16),
                           lineHeight: 20,
                           verticalPadding: 4,
                           maxChars: 120,
                           cornerRadius: 12,
                           borderColor: Color(.secondaryLabel),
                           borderWidth: 0.8
                       )
                       .frame(maxWidth: .infinity, alignment: .leading)
                       .focused($focusedField, equals: .businessAddress)
            }
            if let error = vm.fieldErrors["businessAddress"] {
                HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.system(size: 12, weight: .semibold))
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                        Spacer()
                    }
                    .padding(.leading, labelWidth + 12)
                    .padding(.top, 0)
                    .padding(.bottom, 5)
            }
          }
          RowDivider()

          // No Telp Bisnis dengan error
          VStack(alignment: .leading, spacing: 2) {
            LabeledRow(label: "No Telp Bisnis :", labelWidth: labelWidth) {
                AutoGrowingTextEditor(
                           text: $vm.businessPhone,
                           placeholder: "Silakan isi no telp bisnis anda",
                           isEditing: true,
                           font: .system(size: 16),
                           lineHeight: 20,
                           verticalPadding: 4,
                           maxChars: 30,
                           cornerRadius: 12,
                           borderColor: Color(.secondaryLabel),
                           borderWidth: 0.8
                       )
                       .frame(maxWidth: .infinity, alignment: .leading)
                       .focused($focusedField, equals: .businessPhone)
                       .keyboardType(.numbersAndPunctuation)
            }
            if let error = vm.fieldErrors["businessPhone"] {
                HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.system(size: 12, weight: .semibold))
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                        Spacer()
                    }
                    .padding(.leading, labelWidth + 12) // selaraskan dengan label
                    .padding(.top, 0)
                    .padding(.bottom, 5)
            }
          }
          RowDivider()

          // Email Bisnis dengan error
          VStack(alignment: .leading, spacing: 2) {
            LabeledRow(label: "Email Bisnis :", labelWidth: labelWidth) {
                AutoGrowingTextEditor(
                            text: $vm.businessEmail,
                            placeholder: "Silakan isi alamat email bisnis anda",
                            isEditing: true,
                            font: .system(size: 16),
                            lineHeight: 20,
                            verticalPadding: 4,
                            maxChars: 80,
                            cornerRadius: 12,
                            borderColor: Color(.secondaryLabel),
                            borderWidth: 0.8
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .focused($focusedField, equals: .businessEmail)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .keyboardType(.emailAddress)

            }
            if let error = vm.fieldErrors["businessEmail"] {
                HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.system(size: 12, weight: .semibold))
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                        Spacer()
                    }
                    .padding(.leading, labelWidth + 12) // selaraskan dengan label
                    .padding(.top, 0)
                    .padding(.bottom, 5)
            }
          }
          RowDivider()

          LabeledRow(label: "Logo Bisnis :", labelWidth: labelWidth) {
            HStack(spacing: 8) {
              ZStack {
                if vm.businessLogoUrl.isEmpty {
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
                      
                      if !isUploadingLogo {
                        Image(systemName: "pencil.circle.fill")
                          .font(.system(size: 24))
                          .foregroundStyle(.white)
                          .background(Circle().fill(Color.primaryButton))
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

          // Nama Akun dengan error
          VStack(alignment: .leading, spacing: 2) {
            LabeledRow(label: "Nama Akun :", labelWidth: labelWidth) {
                AutoGrowingTextEditor(
                            text: $vm.bankAccountName,
                            placeholder: "Silakan isi nama akun anda",
                            isEditing: true,
                            font: .system(size: 16),
                            lineHeight: 20,
                            verticalPadding: 4,
                            maxChars: 70,
                            cornerRadius: 12,
                            borderColor: Color(.secondaryLabel),
                            borderWidth: 0.8
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .focused($focusedField, equals: .bankAccountName)
            }
            if let error = vm.fieldErrors["bankAccountName"] {
                HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.system(size: 12, weight: .semibold))
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                        Spacer()
                    }
                    .padding(.leading, labelWidth + 12) // selaraskan dengan label
                    .padding(.top, 0)
                    .padding(.bottom, 5)
            }
          }
          RowDivider()

          // Nomor Rekening dengan error
          VStack(alignment: .leading, spacing: 2) {
            LabeledRow(label: "No Rekening :", labelWidth: labelWidth) {
                AutoGrowingTextEditor(
                           text: $vm.bankAccountNumber,
                           placeholder: "Silakan isi no rekening anda",
                           isEditing: true,
                           font: .system(size: 16),
                           lineHeight: 20,
                           verticalPadding: 4,
                           maxChars: 30,
                           cornerRadius: 12,
                           borderColor: Color(.secondaryLabel),
                           borderWidth: 0.8
                       )
                       .frame(maxWidth: .infinity, alignment: .leading)
                       .focused($focusedField, equals: .bankAccountNumber)
                       .keyboardType(.numberPad)
                
                
            }
            if let error = vm.fieldErrors["bankAccountNumber"] {
                HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.system(size: 12, weight: .semibold))
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                        Spacer()
                    }
                    .padding(.leading, labelWidth + 12) // selaraskan dengan label
                    .padding(.top, 0)
                    .padding(.bottom, 5)
            }
          }
          RowDivider()

          // Nama Bank dengan error
          VStack(alignment: .leading, spacing: 2) {
            LabeledRow(label: "Nama Bank :", labelWidth: labelWidth) {
                AutoGrowingTextEditor(
                           text: $vm.bankName,
                           placeholder: "Silakan isi nama bank anda",
                           isEditing: true,
                           font: .system(size: 16),
                           lineHeight: 20,
                           verticalPadding: 4,
                           maxChars: 50,
                           cornerRadius: 12,
                           borderColor: Color(.secondaryLabel),
                           borderWidth: 0.8
                       )
                       .frame(maxWidth: .infinity, alignment: .leading)
                       .focused($focusedField, equals: .bankName)
            }
            if let error = vm.fieldErrors["bankName"] {
                HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.system(size: 12, weight: .semibold))
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                        Spacer()
                    }
                    .padding(.leading, labelWidth + 12) // selaraskan dengan label
                    .padding(.top, 0)
                    .padding(.bottom, 5)
            }
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
      .navigationBarTitleDisplayMode(.inline)
      .navigationBarBackButtonHidden(true)
      .interactiveDismissDisabled(vm.hasChanges)
      .toolbar(.hidden, for: .tabBar)
      .toolbar {
        ToolbarItem(placement: .principal) {
              Text("Rincian Bisnis")
                  .font(.title2.bold())
            
        }
          
        ToolbarItem(placement: .topBarLeading) {
          Button {
            if vm.hasChanges {
//              showUnsavedAlert = true
                unsavedBus.request(
                    onCancel: { },
                    onConfirm: { dismiss() })
            } else {
              dismiss()
            }
          } label: {
            Image(systemName: "chevron.left")
              .font(.system(size: 20, weight: .semibold))
              .foregroundColor(.primaryButton)
          }
        }
        
      
        
        ToolbarItem(placement: .topBarTrailing) {
            let button = Button {
              Task { await vm.save()
                  
                  if vm.saveSuccess {
                      isDismissed = true
                      dismiss()
                  }
              }
          } label: {
            if vm.isSaving {
              ProgressView()
                .tint(.white)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color.primaryButton))
            } else {
              Image(systemName: "checkmark")
                    .font(.title2)
                    .foregroundStyle(vm.hasChanges ? .white : Color(.systemGray4))
                .frame(width: 32, height: 32)
                
            }
          }
          .disabled(vm.isSaving || vm.isLoading || !vm.hasChanges)
         
            if vm.hasChanges {
                button.buttonStyle(BorderedProminentButtonStyle()).tint(.primaryButton)
            } else {
                button.buttonStyle(BorderlessButtonStyle())
            }
        }
      }
      .task {
        vm.configure(userId: session.userId)
        if let id = session.userId, UUID(uuidString: id) != nil {
          await vm.load()
          focusedField = .businessName
        }
      }
      .onChange(of: vm.businessName) { _ in
        vm.saveSuccess = false
        vm.fieldErrors.removeValue(forKey: "businessName")
        vm.checkForChanges()
      }
      .onChange(of: vm.businessPhone) { _ in
        vm.saveSuccess = false
        vm.fieldErrors.removeValue(forKey: "businessPhone")
        vm.checkForChanges()
      }
      .onChange(of: vm.businessAddress) { _ in
        vm.saveSuccess = false
        vm.fieldErrors.removeValue(forKey: "businessAddress")
        vm.checkForChanges()
      }
      .onChange(of: vm.businessLogoUrl) { _ in
        vm.saveSuccess = false
        vm.checkForChanges()
      }
      .onChange(of: vm.businessEmail) { _ in
        vm.saveSuccess = false
        vm.fieldErrors.removeValue(forKey: "businessEmail")
        vm.checkForChanges()
      }
      .onChange(of: vm.bankAccountNumber) { _ in
        vm.saveSuccess = false
        vm.fieldErrors.removeValue(forKey: "bankAccountNumber")
        vm.checkForChanges()
      }
      .onChange(of: vm.bankAccountName) { _ in
        vm.saveSuccess = false
        vm.fieldErrors.removeValue(forKey: "bankAccountName")
        vm.checkForChanges()
      }
      .onChange(of: vm.bankName) { _ in
        vm.saveSuccess = false
        vm.fieldErrors.removeValue(forKey: "bankName")
        vm.checkForChanges()
      }
      
      // ✅ Alert at top level - covers EVERYTHING including toolbar and tab bar
      if showUnsavedAlert {
        CustomUnsavedAlertComponent(
          title: "Perubahan Belum Disimpan",
          message: "Apakah Anda yakin ingin membatalkan perubahan yang telah dibuat?",
          cancelTitle: "Tidak",
          confirmTitle: "Ya"
        ) {
          showUnsavedAlert = false
        } onConfirm: {
          showUnsavedAlert = false
          dismiss()
        }
        .zIndex(999)
        .transition(.opacity.combined(with: .scale))
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showUnsavedAlert)
      }
    }
    .onTapGesture {
        hideKeyboard()
    }
  }
}

#Preview("Signed In") {
    let session = SessionManager()
    session.isAuthLoaded = true
    session.isSignedIn = true

    return MainTabView(
        selectedTab: .constant(0),
        sharedText: .constant("Test Text"),
        hasNewObject: .constant(false),
        sharedImages: .constant([])
    )
    .environmentObject(session)
    .environmentObject(DeleteOverlayBus())
    .environmentObject(UnsavedOverlayBus())
}


