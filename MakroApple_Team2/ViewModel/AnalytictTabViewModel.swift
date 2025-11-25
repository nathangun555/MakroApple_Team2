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
    @Published var canGoBack: Bool = true
    @Published var isLoading: Bool = false  // ← BARU: Loading state
    @Published var isPrefetching: Bool = false
    
    private var earliestOrderDate: Date?
    
    // ← BARU: Cache untuk setiap timeframe & offset
    private var revenueCache: [String: [BarChartEntry]] = [:]
    private var produkCache: [String: [BarChartEntry]] = [:]
    
    func cacheKey(tf: AnalyticTimeframe, offset: Int) -> String {
        return "\(tf.rawValue)_\(offset)"
    }
    
    func loadHistory(userId: UUID, tf: AnalyticTimeframe, offset: Int = 0) {
        print("📍 loadHistory called - tf: \(tf.rawValue), offset: \(offset)")
            
            // ✅ Wait jika sedang prefetch
            guard !isPrefetching else {
                print("⏳ Waiting for prefetch to complete... (isPrefetching = \(isPrefetching))")
                Task {
                    // Wait sampai prefetch selesai
                    while isPrefetching {
                        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 detik
                    }
                    print("✅ Prefetch completed, retrying loadHistory...")
                    loadHistory(userId: userId, tf: tf, offset: offset)
                }
                return
            }
            
        let key = cacheKey(tf: tf, offset: offset)
        print("🔍 Checking cache for key: \(key)")
        print("🔍 Cache contains: \(revenueCache.keys.sorted())")
            
            // ✅ Cek cache dulu - INSTANT jika ada
            if let cachedRevenue = revenueCache[key],
               let cachedProduk = produkCache[key] {
                print("✅ Using cached data for \(key)")
                revenueHistory = cachedRevenue
                produkTerjualHistory = cachedProduk
                selectedRevenueIndex = cachedRevenue.count - 1
                selectedProdukIndex = cachedProduk.count - 1
                checkCanGoBack(tf: tf, currentOffset: offset)
                
                Task.detached(priority: .background) { [weak self] in
                    await self?.prefetchAdjacentWindows(userId: userId, tf: tf, currentOffset: offset)
                }
                
                return
            }
            
            // ✅ Fetch jika belum ada di cache
            print("🔄 Fetching from database... (cache miss for \(key))")
            isLoading = true
        
        Task {
            // Fetch earliest order date pertama kali
            if earliestOrderDate == nil {
                earliestOrderDate = try? await SupabaseManager.shared.fetchEarliestOrderDate(for: userId)
            }
            
            // ✅ PARALLEL FETCH
            async let revenueTask = SupabaseManager.shared.fetchRevenueHistory(for: userId, tf: tf, windowOffset: offset)
            async let produkTask = SupabaseManager.shared.fetchProdukTerjualHistory(for: userId, tf: tf, windowOffset: offset)
            
            do {
                let (revenueBars, produkBars) = try await (revenueTask, produkTask)
                
                // ✅ Simpan ke cache
                revenueCache[key] = revenueBars
                produkCache[key] = produkBars
                
                revenueHistory = revenueBars
                selectedRevenueIndex = revenueBars.count - 1
                
                produkTerjualHistory = produkBars
                selectedProdukIndex = produkBars.count - 1
                
                checkCanGoBack(tf: tf, currentOffset: offset)
                
                isLoading = false
                
                // ✅ PREFETCH adjacent windows (2 kiri-kanan)
                Task.detached(priority: .background) { [weak self] in
                    await self?.prefetchAdjacentWindows(userId: userId, tf: tf, currentOffset: offset)
                }
                
                // ✅ BARU: Prefetch all timeframes di background (first load only)
//                if offset == 0 {
//                    prefetchAllTimeframes(userId: userId)
//                }
                
            } catch {
                print("❌ Error fetching history: \(error)")
                isLoading = false
            }
        }
    }


    
    // ✅ PREFETCH 2 window di kiri-kanan
    private func prefetchAdjacentWindows(userId: UUID, tf: AnalyticTimeframe, currentOffset: Int) async {
        // Prefetch 2 previous windows (offset + 1, offset + 2)
        for i in 1...2 {
            let prevOffset = currentOffset + i
            let prevKey = cacheKey(tf: tf, offset: prevOffset)
            
            guard revenueCache[prevKey] == nil else { continue }
            
            let nextBatchRange = DateRange.batchStart(for: tf, offset: prevOffset)
            guard let earliest = earliestOrderDate, nextBatchRange.end > earliest else { break }
            
            do {
                async let prevRevenue = SupabaseManager.shared.fetchRevenueHistory(for: userId, tf: tf, windowOffset: prevOffset)
                async let prevProduk = SupabaseManager.shared.fetchProdukTerjualHistory(for: userId, tf: tf, windowOffset: prevOffset)
                
                let (revBars, prodBars) = try await (prevRevenue, prevProduk)
                
                await MainActor.run {
                    revenueCache[prevKey] = revBars
                    produkCache[prevKey] = prodBars
                    print("✅ Prefetched previous window \(i): \(prevKey)")
                }
            } catch {
                print("❌ Error prefetching previous window \(i): \(error)")
                break
            }
        }
        
        // Prefetch 2 next windows (offset - 1, offset - 2)
        for i in 1...2 {
            let nextOffset = currentOffset - i
            guard nextOffset >= 0 else { break }
            
            let nextKey = cacheKey(tf: tf, offset: nextOffset)
            guard revenueCache[nextKey] == nil else { continue }
            
            do {
                async let nextRevenue = SupabaseManager.shared.fetchRevenueHistory(for: userId, tf: tf, windowOffset: nextOffset)
                async let nextProduk = SupabaseManager.shared.fetchProdukTerjualHistory(for: userId, tf: tf, windowOffset: nextOffset)
                
                let (revBars, prodBars) = try await (nextRevenue, nextProduk)
                
                await MainActor.run {
                    revenueCache[nextKey] = revBars
                    produkCache[nextKey] = prodBars
                    print("✅ Prefetched next window \(i): \(nextKey)")
                }
            } catch {
                print("❌ Error prefetching next window \(i): \(error)")
                break
            }
        }
    }
    
    func checkCanGoBack(tf: AnalyticTimeframe, currentOffset: Int) {
        guard let earliest = earliestOrderDate else {
            canGoBack = false
            return
        }
        
        let nextOffset = currentOffset + 1
        let nextBatchRange = DateRange.batchStart(for: tf, offset: nextOffset)
        
        canGoBack = nextBatchRange.end > earliest
    }

    func nextWindow(userId: UUID, tf: AnalyticTimeframe) {
        windowOffset = max(windowOffset - 1, 0)
        loadHistory(userId: userId, tf: tf, offset: windowOffset)
    }
    
    func previousWindow(userId: UUID, tf: AnalyticTimeframe) {
        guard canGoBack else { return }
        windowOffset += 1
        loadHistory(userId: userId, tf: tf, offset: windowOffset)
    }
    
    // ✅ BARU: Prefetch first window untuk semua timeframe
    // ✅ BARU: Prefetch first window untuk semua timeframe
    func prefetchAllTimeframes(userId: UUID) {
        Task.detached(priority: .background) {
            for tf in AnalyticTimeframe.allCases {
                // ✅ FIX: Akses MainActor property dalam await MainActor.run
                let key = "\(tf.rawValue)_0"  // Hardcode key untuk offset 0
                
                // Check cache di MainActor context
                let hasCached = await MainActor.run { [weak self] in
                    guard let self = self else { return true }
                    return self.revenueCache[key] != nil && self.produkCache[key] != nil
                }
                
                guard !hasCached else {
                    print("⏭️ Skipping \(tf.rawValue) - already cached")
                    continue
                }
                
                do {
                    print("🔄 Prefetching \(tf.rawValue) offset 0...")
                    async let revenueTask = SupabaseManager.shared.fetchRevenueHistory(for: userId, tf: tf, windowOffset: 0)
                    async let produkTask = SupabaseManager.shared.fetchProdukTerjualHistory(for: userId, tf: tf, windowOffset: 0)
                    
                    let (revBars, prodBars) = try await (revenueTask, produkTask)
                    
                    await MainActor.run { [weak self] in
                        guard let self = self else { return }
                        self.revenueCache[key] = revBars
                        self.produkCache[key] = prodBars
                        print("✅ Prefetched \(tf.rawValue) offset 0")
                    }
                } catch {
                    print("❌ Error prefetching \(tf.rawValue): \(error)")
                }
            }
        }
    }
    
    // ✅ BARU: Prefetch initial data (Harian offset 0)
    // ✅ BARU: Prefetch initial data (Harian offset 0)
    func prefetchInitialData(userId: UUID) {
        let key = "Harian_0"
        
        guard revenueCache[key] == nil || produkCache[key] == nil else {
            print("⏭️ Initial data already cached")
            return
        }
        
        isPrefetching = true
        print("🔒 isPrefetching set to TRUE")
        
        Task.detached(priority: .utility) { [weak self] in
            // ✅ TAMBAH: Fetch earliest date dulu
            let earliest = try? await SupabaseManager.shared.fetchEarliestOrderDate(for: userId)
            
            do {
                print("🔄 Prefetching initial analytics data...")
                async let revenueTask = SupabaseManager.shared.fetchRevenueHistory(for: userId, tf: .hari, windowOffset: 0)
                async let produkTask = SupabaseManager.shared.fetchProdukTerjualHistory(for: userId, tf: .hari, windowOffset: 0)
                
                let (revBars, prodBars) = try await (revenueTask, produkTask)
                
                await MainActor.run {
                    guard let self = self else { return }
                    self.earliestOrderDate = earliest  // ✅ Set earliest date
                    self.revenueCache[key] = revBars
                    self.produkCache[key] = prodBars
                    self.isPrefetching = false
                    print("🔓 isPrefetching set to FALSE")
                    print("✅ Initial analytics data prefetched! (key: \(key))")
                    
                    self.prefetchAllTimeframes(userId: userId)
                }
            } catch {
                await MainActor.run {
                    self?.isPrefetching = false
                }
                print("❌ Error prefetching initial data: \(error)")
            }
        }
    }



    
    func resetOffset() {
        windowOffset = 0
//        earliestOrderDate = nil
        // ✅ Clear cache saat ganti timeframe
//        revenueCache.removeAll()
//        produkCache.removeAll()
    }
}
