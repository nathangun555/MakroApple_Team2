//
//  Set_MenuDetailsView.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 17/10/25.
//

import SwiftUI

struct Set_MenuDetailsView: View {
  @EnvironmentObject var session: SessionManager
  @StateObject private var vm = Set_MenuDetailsViewModel()

  var body: some View {
    List {
      if let err = vm.errorMessage {
        Text(err).foregroundStyle(.red)
      }

      ForEach(vm.products) { p in
        VStack(alignment: .leading, spacing: 4) {
          Text(p.name)
            .font(.headline)
          HStack(spacing: 8) {
            Text(formatPrice(p.price))
            if let t = p.productType { Text("• \(t)") }
          }
          .font(.subheadline)
          .foregroundStyle(.secondary)

          if let notes = p.notes, !notes.isEmpty {
            Text(notes)
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
        }
        .padding(.vertical, 6)
      }
    }
    .navigationTitle("Rincian Menu")
    .task {
      vm.configure(userId: session.userId)
      await vm.load()
    }
  }

  private func formatPrice(_ value: Decimal) -> String {
    let n = NSDecimalNumber(decimal: value)
    let f = NumberFormatter()
    f.numberStyle = .currency
    f.currencyCode = "IDR"
    f.maximumFractionDigits = 0
    return f.string(from: n) ?? "Rp\(n)"
  }
}

#Preview {
  let session = SessionManager()
  session.isSignedIn = true
  session.userId = "083dc90d-ca03-4f45-a631-06fe21fe750f"

  return NavigationStack {
    Set_MenuDetailsView()
      .environmentObject(session)
  }
}
