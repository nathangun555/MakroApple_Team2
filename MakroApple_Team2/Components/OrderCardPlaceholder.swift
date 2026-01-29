//
//  OrderCardPlaceholder.swift
//  MakroApple_Team2
//
//  Created by Assistant
//

import SwiftUI

struct OrderCardPlaceholder: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack {
            // Indikator placeholder
            RoundedRectangle(cornerRadius: 10)
                .frame(width: 6)
                .foregroundColor(Color.gray.opacity(0.3))
                .padding(.vertical, 3)
            
            // Card placeholder
            VStack(alignment: .leading, spacing: 8) {
                // Row 1 placeholder
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 120, height: 12)
                    
                    Spacer()
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 80, height: 12)
                    
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 8, height: 8)
                }
                .font(.subheadline)
                
                Spacer()
                
                // Row 2 placeholder
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 150, height: 16)
                    
                    Spacer()
                }
                
                // Row 3 placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 100, height: 10)
            }
            .padding()
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.white.opacity(0.15), Color.gray.opacity(0.1)]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(10)
        .frame(height: 85)
        .padding(.horizontal, 20)
        .shimmer(isAnimating: isAnimating)
        .onAppear {
            withAnimation(
                Animation.linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ) {
                isAnimating = true
            }
        }
    }
}

extension View {
    func shimmer(isAnimating: Bool) -> some View {
        self.modifier(ShimmerModifier(isAnimating: isAnimating))
    }
}

struct ShimmerModifier: ViewModifier {
    var isAnimating: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            Color.white.opacity(0.3),
                            Color.clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: isAnimating ? geometry.size.width : -geometry.size.width)
                }
            )
            .clipped()
    }
}
