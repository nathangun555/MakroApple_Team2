//
//  CustomTabBar.swift
//  MakroApple_Team2
//
//  Created by Edward Suwandi on 21/10/25.
//

import SwiftUI

enum TabModel: String, CaseIterable {
    case belumBayar = "Belum Bayar"
    case diproses = "Diproses"
    case terkirim = "Terkirim"
    case selesai = "Selesai"
    case dibatalkan = "Dibatalkan"
    
    var dbValue: String {
        switch self {
        case .belumBayar: return "Belum Terbayar"
        case .diproses: return "Diproses"
        case .terkirim: return "Terkirim"
        case .selesai: return "Selesai"
        case .dibatalkan: return "Dibatalkan"
        }
    }
    
    var icon: String {
        switch self {
        case .belumBayar:
            "creditcard.trianglebadge.exclamationmark.fill"
            
        case .diproses:
            "basket.fill"
            
        case .terkirim:
            "truck.box.fill"
            
        case .selesai:
            "checkmark.rectangle.stack.fill"
            
        case .dibatalkan:
            "xmark.bin.fill"
        }
    }
    var color: Color {
        switch self {
        case .belumBayar:
            return .orange
            
        case .diproses:
            return .blue
            
        case .terkirim:
            return .purple
            
        case .selesai:
            return .green
            
        case .dibatalkan:
            return .red
        }
    }
}


struct CustomTabBar: View {
    
    @Binding var activeTab: TabModel
    @State private var showEkor = false
    
    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 8) {
                
                ZStack {
                    HStack() {
                        ForEach(TabModel.allCases, id: \.rawValue) { tab in
                            resizableTabButton(tab)
                        }
                    }
                }
            }
            .padding(.horizontal, 15)
        }
        .frame(height: 45)
    }
    
    // Tab Button
    @ViewBuilder
    func resizableTabButton(_ tab: TabModel) -> some View {
        HStack(spacing: 8) {
            Image(systemName: tab.icon)
                .font(.caption)
            
            if activeTab == tab {
                Text(tab.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, activeTab == tab ? 5 : 20)
        .foregroundStyle(activeTab == tab ? .white : .black)
        .frame(maxWidth: activeTab == tab ? .infinity : nil, maxHeight: .infinity)
        .background(activeTab == tab ? tab.color : .clear)
        .cornerRadius(30)
        .shadow(
            color: Color.black.opacity(0.2),
            radius: 4,
            x: 0,
            y: 3
        )
        .onTapGesture {
            withAnimation(.bouncy) {
                activeTab = tab
            }
        }
        .glassEffect()
    }
}

#Preview {
    StatefulPreviewWrapper(TabModel.belumBayar) { activeTab in
        CustomTabBar(activeTab: activeTab)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}

// Helper to enable interactive bindings in Preview
struct StatefulPreviewWrapper<Value: Equatable, Content: View>: View {
    @State private var value: Value
    var content: (Binding<Value>) -> Content

    init(_ initialValue: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        self._value = State(initialValue: initialValue)
        self.content = content
    }

    var body: some View {
        content($value)
    }
}


