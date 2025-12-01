//
//  AnalyticTabView.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 21/11/25.
//
// AnalyticTabView.swift

import SwiftUI
import Charts
import Combine

struct AnalyticTabView: View {
    @State private var timeframe: AnalyticTimeframe = .hari
    @EnvironmentObject var viewModel: AnalyticTabViewModel
    @EnvironmentObject var session: SessionManager
    
    @State private var logoViewModel = AllOrdersViewModel()
    @State var showProfile = false
    @State private var profileImage: UIImage? = nil
    @State var onChangeSettings = false
    
    // Tambahkan di dalam struct BarChartStatCard, sebelum body
    func detailedLabel(for entry: BarChartEntry, timeframe: AnalyticTimeframe) -> String {
        // Jika sudah format ringkas (misal "10-16"), parse dan convert ke lengkap
        // Untuk case minggu, kita perlu akses window start date
        // Solusi lebih simple: pass full info dari ViewModel
        return entry.label  // Sementara return label asli
    }


    var body: some View {
        
        NavigationStack{
            
            VStack{
                
                // header
                HStack {
                    Text("Analitik")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    Spacer()
                    Button {
                        showProfile = true
                    } label: {
                        if let logoImage = profileImage {
                            Image(uiImage: logoImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                                .shadow(color: Color(.systemGray4),
                                        radius: 4, x: 0, y: 1)
                        } else {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 40, height: 40)
                                    .shadow(color: Color(.systemGray4),
                                            radius: 4, x: 0, y: 1)
                                
                                Image(systemName: "person.fill")
                                    .font(.title3)
                                    .foregroundColor(.primaryButton)
                            }
                        }
                    }
                }
//                .padding(.horizontal)
                
                
                Picker("Timeframe", selection: $timeframe) {
                    ForEach(AnalyticTimeframe.allCases, id: \.self) { tf in
                        Text(tf.rawValue.capitalized).tag(tf)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: timeframe) { newTF in
                    guard let userIdStr = session.userId,
                          let userId = UUID(uuidString: userIdStr) else { return }
                    viewModel.resetOffset()
                    viewModel.loadHistory(userId: userId, tf: newTF)
                }
                
                ScrollView{
                    
                    // Window navigation row
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(timeframe.rawValue)")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.black)
                            Text(DateRange.displayWindowRange(for: timeframe, offset: viewModel.windowOffset))
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button {
                            if let userIdStr = session.userId,
                               let userId = UUID(uuidString: userIdStr) {
                                viewModel.previousWindow(userId: userId, tf: timeframe)
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(viewModel.canGoBack ? .primaryButton : Color.gray.opacity(0.3))
                        }
                        .padding(.horizontal, 6)
                        Button {
                            if let userIdStr = session.userId,
                               let userId = UUID(uuidString: userIdStr) {
                                viewModel.nextWindow(userId: userId, tf: timeframe)
                            }
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.title2)
                                .foregroundColor(viewModel.windowOffset > 0 ? .primaryButton : Color.gray.opacity(0.3))
                        }
//                        .padding(.horizontal, 6)
                    }
//                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                    
                    
                    
                    // Stat cards
                    VStack(spacing: 16) {
                        BarChartStatCard(
                            title: "Revenue",
                            barEntries: viewModel.revenueHistory,
                            selectedIndex: $viewModel.selectedRevenueIndex,
                            icon: "banknote"
                        )
                        
                        BarChartStatCard(
                            title: "Produk Terjual",
                            barEntries: viewModel.produkTerjualHistory,
                            selectedIndex: $viewModel.selectedProdukIndex,
                            icon: "cart.fill"
                        )
                    }
                    //                Spacer()
                }
            }
            .padding(.horizontal, 20)
            .task(id: logoViewModel.businessLogoUrl) {
                await logoViewModel.fetchBusinessName(for: UUID(uuidString: session.userId!))
                guard let urlString = logoViewModel.businessLogoUrl else {
                    profileImage = nil
                    return
                }
                profileImage = await logoViewModel.loadImage(from: urlString)
            }
            .onAppear {
                guard let userIdStr = session.userId,
                      let userId = UUID(uuidString: userIdStr) else { return }
                
                // ✅ Cek apakah data sudah ada di cache
                let key = viewModel.cacheKey(tf: timeframe, offset: 0)
                
                // Jika belum ada cache DAN tidak sedang prefetch, baru load
                Task {
                    while viewModel.isPrefetching {
                        try? await Task.sleep(nanoseconds: 50_000_000)
                    }
                    viewModel.loadHistory(userId: userId, tf: timeframe)
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ZStack {
                        Color.black.opacity(0.2)
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.primaryButton)
                    }
                    .ignoresSafeArea()
                }
            }
            .sheet(isPresented: $showProfile) {
                NavigationStack{
                    SettingsView(onChangeSettings: $onChangeSettings)
                    
                }
            }
        }
    }
}

struct BarChartStatCard: View {
    var title: String
    var barEntries: [BarChartEntry]
    @Binding var selectedIndex: Int
    var icon: String
    
    // Helper function untuk calculate perubahan dari bar sebelumnya
    func calculateChange(currentIndex: Int) -> (percentage: Double, color: Color, text: String) {
        guard currentIndex > 0, currentIndex < barEntries.count else {
            return (0, .gray, "Data pertama")
        }
        
        let currentValue = barEntries[currentIndex].value
        let previousValue = barEntries[currentIndex - 1].value
        
        // Hindari division by zero
        guard previousValue != 0 else {
            if currentValue > 0 {
                return (100, .green, "+100% dari sebelumnya")
            } else {
                return (0, .gray, "+0% dari sebelumnya")
            }
        }
        
        let change = ((currentValue - previousValue) / previousValue) * 100
        let percentage = abs(change)
        
        if change > 0 {
            return (percentage, .green, "+\(String(format: "%.1f", percentage))% dari sebelumnya")
        } else if change < 0 {
            return (percentage, .red, "-\(String(format: "%.1f", percentage))% dari sebelumnya")
        } else {
            return (0, .gray, "+0% dari sebelumnya")
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            // Header (icon + title) - POIN 4: Judul warna primaryButton
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.primaryButton)
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.primaryButton)  // ← UBAH: Judul jadi primaryButton
                Spacer()
            }
            
            // NILAI & PERIODE DI ATAS CHART
            if !barEntries.isEmpty, let selected = barEntries[safe: selectedIndex] {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selected.detailLabel)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    // Format nilai
                    if title == "Revenue" {
                        Text(selected.value, format: .currency(code: "IDR"))
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primaryButton)
                    } else {
                        Text("\(Int(selected.value))")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primaryButton)
                    }
                    
                    // Perubahan dinamis dari bar sebelumnya
                    let change = calculateChange(currentIndex: selectedIndex)
                    Text(change.text)
                        .font(.caption)
                        .foregroundColor(change.color)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
            }
            
            if !barEntries.isEmpty {
                // ✅ Calculate maxValue untuk determine format
                let maxValue = barEntries.map { $0.value }.max() ?? 1
                
                // ✅ Determine format & divisor based on maxValue
                let (divisor, suffix): (Double, String) = {
                    if maxValue >= 1_000_000 {
                        return (1_000_000, "Jt")  // Juta
                    } else if maxValue >= 1_000 {
                        return (1_000, "Rb")      // Ribu
                    } else {
                        return (1, "")            // Satuan (< 1000)
                    }
                }()
                
                Chart(barEntries) { entry in
                    BarMark(
                        x: .value("Label", entry.label),
                        y: .value("Value", entry.value)
                    )
                    .cornerRadius(8)
                    .foregroundStyle(
                        selectedIndex == barEntries.firstIndex(of: entry)
                        ? Color.primaryButton
                        : Color.primaryButton.opacity(0.3)
                    )
                }
                .chartXAxis {
                    AxisMarks(position: .bottom) { value in
                        if let label = value.as(String.self) {
                            AxisValueLabel {
                                Text(label)
                                    .font(.caption)
                                    .foregroundColor(
                                        barEntries.firstIndex(where: { $0.label == label }) == selectedIndex
                                        ? Color.primaryButton
                                        : Color.secondary
                                    )
                                    .fontWeight(
                                        barEntries.firstIndex(where: { $0.label == label }) == selectedIndex
                                        ? .bold
                                        : .regular
                                    )
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        if let numValue = value.as(Double.self) {
                            AxisValueLabel {
                                if title == "Revenue" {
                                    // ✅ Dynamic format: Rb, Jt, atau M
                                    let formatted = Int(numValue / divisor)
                                    Text("\(formatted)\(suffix)")
                                        .font(.caption2)
                                } else {
                                    // Produk Terjual tetap normal
                                    Text("\(Int(numValue))")
                                        .font(.caption2)
                                }
                            }
                            AxisGridLine()
                        }
                    }
                }
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onEnded { value in
                                        let xPos = value.location.x
                                        let chartWidth = geo.size.width
                                        let barWidth = chartWidth / CGFloat(barEntries.count)
                                        let tappedIndex = Int(xPos / barWidth)
                                        
                                        if tappedIndex >= 0 && tappedIndex < barEntries.count {
                                            selectedIndex = tappedIndex
                                        }
                                    }
                            )
                    }
                }
                .frame(height: 110)
                .padding(.horizontal, 8)
            }

        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(.black).opacity(0.05), radius: 8, x: 0, y: 4)
    }
}



// Helper safe accessor
extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
