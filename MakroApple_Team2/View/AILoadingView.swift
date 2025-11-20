//
//  AILoadingView.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 20/11/25.
//

import SwiftUI

struct AILoadingScreenView: View {
    @State private var isAnimating = false
    @State private var currentTipIndex = 0
    @State private var progress: CGFloat = 0.0
    @State private var particleOffsets: [CGFloat] = Array(repeating: 0, count: 8)
    
    let tips = [
        "💡 Tip: Use menu scanning to auto-import dishes",
        "🗺️ Tip: Map view shows all your locations at once",
        "⚡ Tip: AI processes orders 10x faster",
        "📊 Tip: Real-time analytics on your dashboard",
        "🔄 Tip: Sync works offline too",
        "🎯 Tip: Custom alerts for peak hours",
        "💬 Tip: Multi-language support included",
        "🚀 Tip: Bulk operations save 80% time"
    ]
    
    var body: some View {
        ZStack {
            // Animated Gradient Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.08, blue: 0.15),
                    Color(red: 0.1, green: 0.12, blue: 0.25)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated Background Particles
            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.4, green: 0.8, blue: 1.0, opacity: 0.3),
                                Color(red: 0.2, green: 0.4, blue: 0.8, opacity: 0.0)
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)
                    .offset(y: particleOffsets[index])
                    .opacity(0.3)
                    .position(
                        x: CGFloat(index % 2) * 300 + 50,
                        y: CGFloat(index / 2) * 200 + 100
                    )
            }
            
            VStack(spacing: 0) {
                Spacer()
                
                // Main AI Logo/Icon with Animation
                VStack(spacing: 16) {
                    ZStack {
                        // Outer rotating ring
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.4, green: 0.8, blue: 1.0),
                                        Color(red: 0.2, green: 0.6, blue: 0.9),
                                        Color(red: 0.4, green: 0.8, blue: 1.0)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        
                        // Inner pulsing circle
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.4, green: 0.8, blue: 1.0, opacity: 0.3),
                                        Color(red: 0.2, green: 0.4, blue: 0.8, opacity: 0.0)
                                    ]),
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 50
                                )
                            )
                            .frame(width: 80, height: 80)
                            .scaleEffect(isAnimating ? 1.1 : 0.9)
                            .opacity(isAnimating ? 0.8 : 0.5)
                        
                        // Center icon (AI chip/brain)
                        Image(systemName: "sparkles")
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    // Loading text with pulse
                    VStack(spacing: 4) {
                        Text("Processing...")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text(tips[currentTipIndex])
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color(red: 0.7, green: 0.8, blue: 0.9))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 280)
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer()
                    .frame(height: 60)
                
                // Animated Progress Bar
                VStack(spacing: 12) {
                    // Custom animated progress bar
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(red: 0.15, green: 0.2, blue: 0.35))
                            .frame(height: 4)
                        
                        // Progress fill with gradient
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.4, green: 0.8, blue: 1.0),
                                        Color(red: 0.2, green: 0.6, blue: 0.9)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: progress, height: 4)
                            .shadow(color: Color(red: 0.4, green: 0.8, blue: 1.0, opacity: 0.5), radius: 2)
                    }
                    .frame(height: 4)
                    .padding(.horizontal, 30)
                    
                    // Percentage text
                    Text(String(format: "%.0f%%", progress / 3)) // Scale for 0-100
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 0.7, green: 0.8, blue: 0.9))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.horizontal, 30)
                }
                
                Spacer()
                    .frame(height: 40)
                
                // Status indicators (what's processing)
                VStack(spacing: 8) {
                    StatusIndicatorRow(label: "Scanning menu", isActive: progress > 100)
                    StatusIndicatorRow(label: "Processing data", isActive: progress > 150)
                    StatusIndicatorRow(label: "Syncing", isActive: progress > 200)
                    StatusIndicatorRow(label: "Finalizing", isActive: progress > 250)
                }
                .padding(.horizontal, 30)
                
                Spacer()
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Main rotation animation
        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
            isAnimating = true
        }
        
        // Progress animation
        withAnimation(.easeInOut(duration: 45)) {
            progress = 320 // Simulates 100% over 45 seconds (max load time)
        }
        
        // Tip rotation every 5 seconds
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentTipIndex = (currentTipIndex + 1) % tips.count
            }
        }
        
        // Particle floating animation
        for index in 0..<8 {
            withAnimation(.easeInOut(duration: Double(3 + index)).repeatForever(autoreverses: true)) {
                particleOffsets[index] = CGFloat(Int.random(in: -40...40))
            }
        }
    }
}

struct StatusIndicatorRow: View {
    let label: String
    let isActive: Bool
    @State private var dotIndex = 0
    
    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(
                            isActive ?
                            Color(red: 0.4, green: 0.8, blue: 1.0) :
                            Color(red: 0.2, green: 0.3, blue: 0.5)
                        )
                        .frame(width: 4, height: 4)
                        .opacity(isActive && index == dotIndex ? 1.0 : 0.3)
                }
            }
            
            Text(label)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Color(red: 0.7, green: 0.8, blue: 0.9))
            
            Spacer()
        }
        .frame(height: 20)
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                dotIndex = (dotIndex + 1) % 3
            }
        }
    }
}

// Preview
#Preview {
    AILoadingScreenView()
}
