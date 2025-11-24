//
//  AnalyticTabViewModel.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 21/11/25.
//


//import Foundation
//import Combine
//
//@MainActor
//class AnalyticTabViewModel: ObservableObject {
//    @Published var analytics = AnalyticResult(revenue: 0, total_order: 0, produk_terjual: 0, customer_baru: 0)
//    @Published var previous = AnalyticResult(revenue: 0, total_order: 0, produk_terjual: 0, customer_baru: 0)
//
//    func loadAnalytics(userId: UUID, range: DateRange, timeframe: AnalyticTimeframe) {
//        Task {
//            let now = try await SupabaseManager.shared.fetchAnalytics(for: userId, range: range)
//            let prev = try await SupabaseManager.shared.fetchAnalytics(for: userId, range: range.previous(timeframe))
//            analytics = now
//            previous = prev
//            print("Analytics after assign:", analytics)
//
//            
//        }
//    }
//    
//    func percentChange(current: Double, prev: Double) -> String {
//        if prev == 0 { return prev == current ? "+0%" : "+∞%" }
//        let diff = ((current - prev) / abs(prev)) * 100
//        let formatted = String(format: "%+g", diff.rounded())
//        return "\(formatted)%"
//    }
//}

// AnalyticTabViewModel.swift

import Foundation
import Combine

@MainActor
class AnalyticTabViewModel: ObservableObject {
    @Published var revenueHistory: [BarChartEntry] = []
    @Published var produkTerjualHistory: [BarChartEntry] = []
    @Published var selectedRevenueIndex: Int = 6
    @Published var selectedProdukIndex: Int = 6
    @Published var windowOffset: Int = 0
    @Published var canGoBack: Bool = true  // ← BARU
    
    private var earliestOrderDate: Date?  // ← BARU: Cache earliest date
    
    func loadHistory(userId: UUID, tf: AnalyticTimeframe, offset: Int = 0) {
        Task {
            // Fetch earliest order date pertama kali
            if earliestOrderDate == nil {
                earliestOrderDate = try? await SupabaseManager.shared.fetchEarliestOrderDate(for: userId)
            }
            
            // Revenue batch
            if let bars = try? await SupabaseManager.shared.fetchRevenueHistory(for: userId, tf: tf, windowOffset: offset) {
                revenueHistory = bars
                selectedRevenueIndex = bars.count - 1
                
                // Check apakah bisa go back based on earliest order date
                checkCanGoBack(tf: tf, currentOffset: offset)
            }
            // Produk batch
            if let bars = try? await SupabaseManager.shared.fetchProdukTerjualHistory(for: userId, tf: tf, windowOffset: offset) {
                produkTerjualHistory = bars
                selectedProdukIndex = bars.count - 1
            }
        }
    }
    
    // ← BARU: Check apakah window sebelumnya masih dalam range earliest order
    func checkCanGoBack(tf: AnalyticTimeframe, currentOffset: Int) {
        guard let earliest = earliestOrderDate else {
            print("⚠️ No earliest order date found")
            canGoBack = false
            return
        }
        
        let nextOffset = currentOffset + 1
        let nextBatchRange = DateRange.batchStart(for: tf, offset: nextOffset)
        
        print("🔍 DEBUG:")
        print("  Earliest Order: \(earliest)")
        print("  Next Window Start: \(nextBatchRange.start)")
        print("  Current Offset: \(currentOffset)")
        print("  Next Offset: \(nextOffset)")
        
        // Cek apakah start date dari next window masih >= earliest order date
        canGoBack = nextBatchRange.end > earliest
        
        print("  Can Go Back: \(canGoBack)")
    }


    func nextWindow(userId: UUID, tf: AnalyticTimeframe) {
        windowOffset = max(windowOffset - 1, 0)
        loadHistory(userId: userId, tf: tf, offset: windowOffset)
    }
    
    func previousWindow(userId: UUID, tf: AnalyticTimeframe) {
        guard canGoBack else { return }  // ← BARU: Guard
        windowOffset += 1
        loadHistory(userId: userId, tf: tf, offset: windowOffset)
    }
    
    // ← BARU: Reset saat timeframe berubah
    func resetOffset() {
        windowOffset = 0
        earliestOrderDate = nil
    }
}
