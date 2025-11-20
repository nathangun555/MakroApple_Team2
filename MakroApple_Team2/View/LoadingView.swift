//
//  LoadingView.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 20/11/25.
//

import SwiftUI

struct LoadingView: View {
    @State private var animate = false
    @State private var currentTipIndex = 0
    
    let tips = [
        "Pastikan koneksi internet stabil.",
        "Jangan tutup aplikasi saat proses berjalan.",
        "AI kami sedang menganalisis data Anda.",
        "Proses biasanya selesai dalam beberapa menit.",
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
            .onAppear {
                animate = true
            }
            
            // MARK: – Main Text
            VStack(spacing: 6) {
                Text("AI sedang memproses informasi Anda...")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(tips[currentTipIndex])
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                    .animation(.easeInOut, value: currentTipIndex)
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            startRotatingTips()
        }
    }
    
    private func startRotatingTips() {
        Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { _ in
            withAnimation {
                currentTipIndex = (currentTipIndex + 1) % tips.count
            }
        }
    }
}

#Preview {
    LoadingView()
        .preferredColorScheme(.light)   // remove or duplicate for dark mode preview
}
