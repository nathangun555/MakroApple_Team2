//
//  Set_BusinessDetailsView.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 17/10/25.
//

import SwiftUI

struct Set_BusinessDetailsView: View {
  @EnvironmentObject var session: SessionManager
  @StateObject private var vm = Set_BusinessDetailsViewModel()
  @FocusState private var focusedField: Field?

  enum Field: Hashable {
    case businessName, businessPhone, businessAddress, businessLogoUrl, businessEmail, bankAccountNumber, bankAccountName, bankName
  }

  var body: some View {
    Form {
      Section(header: Text("Profil Bisnis")) {
        TextField("Nama Bisnis", text: $vm.businessName)
          .focused($focusedField, equals: .businessName)
          .textContentType(.organizationName)

        TextField("Nomor Telepon Bisnis", text: $vm.businessPhone)
          .keyboardType(.phonePad)
          .focused($focusedField, equals: .businessPhone)
          .textContentType(.telephoneNumber)

        TextField("Alamat Bisnis", text: $vm.businessAddress, axis: .vertical)
          .lineLimit(3...6)
          .focused($focusedField, equals: .businessAddress)

        TextField("Logo URL (opsional)", text: $vm.businessLogoUrl)
          .keyboardType(.URL)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
          .focused($focusedField, equals: .businessLogoUrl)

        TextField("Email Bisnis (opsional)", text: $vm.businessEmail)
          .keyboardType(.emailAddress)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
          .focused($focusedField, equals: .businessEmail)
      }

      Section(header: Text("Rekening Bank")) {
        TextField("Nomor Rekening", text: $vm.bankAccountNumber)
          .keyboardType(.numbersAndPunctuation)
          .focused($focusedField, equals: .bankAccountNumber)

        TextField("Nama Pemilik Rekening", text: $vm.bankAccountName)
          .focused($focusedField, equals: .bankAccountName)

        TextField("Nama Bank", text: $vm.bankName)
          .focused($focusedField, equals: .bankName)
      }

      if let error = vm.errorMessage, !error.isEmpty {
        Section { Text(error).foregroundStyle(.red) }
      }

      if vm.saveSuccess {
        Section { Text("Perubahan berhasil disimpan.").foregroundStyle(.green) }
      }
    }
    .navigationTitle("Rincian Bisnis")
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
      await vm.load()
      focusedField = .businessName
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
