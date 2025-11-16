//
//  ShareContentView.swift
//  MakroApple_Team2
//
//  Created by Edward Suwandi on 05/11/25.
//


import SwiftUI

struct ShareContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Shared to MyApp")
                .font(.title2)
                .bold()

            Text("You can customize this screen for your extension.")
                .multilineTextAlignment(.center)
                .padding()

            Button("Done") {
                NotificationCenter.default.post(name: NSNotification.Name("CloseShareExtension"), object: nil)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

