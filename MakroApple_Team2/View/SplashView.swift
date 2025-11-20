//
//  SplashView.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 20/11/25.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 16) {
                if let appIcon = Bundle.main.icon {
                    Image(uiImage: appIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 96, height: 96)
                        .cornerRadius(20)
                        .shadow(radius: 10)
                }

            }
        }
    }
}
