//
//  LoadingView.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 20/11/25.
//

import SwiftUI

struct LoadingView: View {
    @Bindable var model: InputMenuViewModel
    var context: String?

    private let showProgress: Bool
    
    init(model: InputMenuViewModel, context: String? = nil) {
        self._model = Bindable(wrappedValue: model)
        self.context = context
        self.showProgress = true
    }
    
    init(context: String? = nil) {
        self._model = Bindable(wrappedValue: InputMenuViewModel())
        self.context = context
        self.showProgress = false
    }
        
    @State private var animate = false
    @State private var currentTipIndex = 0

    let tips = [
        "Pastikan koneksi internet stabil.",
        "Jangan tutup aplikasi saat proses berjalan.",
        "AI kami sedang menganalisis data Anda.",
        "Proses biasanya selesai dalam beberapa detik.",
        "Terima kasih sudah menunggu!"
    ]

    var body: some View {
        VStack(spacing: 28) {
            
            Spacer()
            
            // MARK: – Animated Dots
            HStack(spacing: 10) {
                ForEach(0..<5) { i in
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.blue.opacity(animate ? 1 : 0.3))
                        .frame(width: 12, height: 12)
                        .offset(y: animate ? -6 : 6)
                        .animation(
                            .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(i) * 0.1),
                            value: animate
                        )
                }
            }
            .onAppear { animate = true }
            
            // MARK: – Main Text
            VStack(spacing: 6) {
                Text("AI sedang memproses \(context ?? "informasi") Anda…")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(tips[currentTipIndex])
                    .font(.footnote)
                    .foregroundColor(.secondary.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            if showProgress {
                VStack(spacing: 10) {
                    ProgressView(value: model.progress)
                        .progressViewStyle(.linear)
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                        .padding(.horizontal, 46)
                    
                    Text("\(Int(model.progress * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
        }
        .padding()
        .onAppear { startRotatingTips() }
        .navigationBarBackButtonHidden(true)
    }

    private func startRotatingTips() {
        Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { _ in
            withAnimation {
                currentTipIndex = (currentTipIndex + 1) % tips.count
            }
        }
    }

}
