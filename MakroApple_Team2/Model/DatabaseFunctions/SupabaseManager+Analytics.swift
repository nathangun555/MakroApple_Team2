//
//  SupabaseManager+Analytics.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 21/11/25.
//
//
//import Foundation
//import Supabase
//
//// MARK: - Helper Structs
//
//struct OrderIdOnly: Decodable { let id: String }
//struct OrderItemRecordAna: Decodable { let quantity: Int? }
//struct OrderRecordAna: Decodable {
//    let id: String
//    let total_amount: Double?
//    let status: String
//    let order_dday_date: String
//}
//struct OrderCustomerPhone: Decodable { let customer_order_phone: String? }
//
//
//// MARK: - Analytic Result Model
//
//struct AnalyticResult: Equatable {
//    let revenue: Double
//    let total_order: Int
//    let produk_terjual: Int
//    let customer_baru: Int
//}
//
//// MARK: - Analytics Extension
//
//extension SupabaseManager {
//
//    func fetchAnalytics(for userId: UUID, range: DateRange) async throws -> AnalyticResult {
//        let userStr = userId.uuidString
//        let startStr = range.start.toSupabaseString()
//        let endStr = range.end.toSupabaseString()
//
//        // 1. Revenue & Orders — hanya status "Selesai"
//        let ordersResponse = try await client
//            .from("orders")
//            .select("id,total_amount,status,order_dday_date")
//            .eq("user_id", value: userStr)
//            .eq("status", value: "Selesai") // CASE SENSITIVE!!
//            .gte("order_dday_date", value: startStr)
//            .lt("order_dday_date", value: endStr)
//            .execute()
//
//        // Debug print
//        print("Orders Query:", String(data: ordersResponse.data, encoding: .utf8) ?? "nil")
//        let orderRecords = try JSONDecoder().decode([OrderRecordAna].self, from: ordersResponse.data)
//        let revenue = orderRecords.reduce(0) { $0 + ($1.total_amount ?? 0) }
//        let totalOrder = orderRecords.count
//        let orderIds = orderRecords.map { $0.id }
//
//        // 2. Produk Terjual — sum quantity di order_items
//        var produkTerjual = 0
//        if !orderIds.isEmpty {
//            let itemsResponse = try await client
//                .from("order_items")
//                .select("quantity, order_id")
//                .in("order_id", value: orderIds)
//                .execute()
//            let itemRecords = try JSONDecoder().decode([OrderItemRecordAna].self, from: itemsResponse.data)
//            produkTerjual = itemRecords.reduce(0) { $0 + ($1.quantity ?? 0) }
//        }
//        print("Tes1: ")
//        // 3. Customer Baru — unique phone dari orders status "Selesai"
//        let uniquePhones = "dummy"
//        do {
//            let customerResponse = try await client
//                .from("orders")
//                .select("customer_order_phone")
//                .eq("user_id", value: userStr)
//                .eq("status", value: "Selesai")
//                .gte("order_dday_date", value: startStr)
//                .lt("order_dday_date", value: endStr)
//                .execute()
//            let phoneRecords = try JSONDecoder().decode([OrderCustomerPhone].self, from: customerResponse.data)
//            let uniquePhones = Set(phoneRecords.compactMap {
//                let val = $0.customer_order_phone?.trimmingCharacters(in: .whitespaces)
//                return (val?.isEmpty == false) ? val : nil
//            })
//            print("Tes2: ")
//            // lanjut kode analytic berikutnya
//        } catch {
//            print("ERROR di bagian customerResponse: ", error)
//        }
//
//        let customerBaru = uniquePhones.count
//        print("Tes3: ")
//        print("Result: ", AnalyticResult(revenue: revenue, total_order: totalOrder, produk_terjual: produkTerjual, customer_baru: customerBaru))
//
//        print("Revenue: ", revenue)
//        print("Total Order: ", totalOrder)
//        print("Produk Terjual: ", produkTerjual)
//        print("Customer Baru : ", customerBaru)
//        return AnalyticResult(
//            revenue: revenue,
//            total_order: totalOrder,
//            produk_terjual: produkTerjual,
//            customer_baru: customerBaru
//        )
//        print("Tes4: ")
//
//    }
//}
//
//// MARK: - Date Extension (ISO8601 with offset for Supabase/Postgres)
//extension Date {
//    func toSupabaseString() -> String {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
//        formatter.timeZone = TimeZone(secondsFromGMT: 0) // gunakan UTC
//        return formatter.string(from: self)
//    }
//}

//
//  SupabaseManager+Analytics.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 21/11/25.
//

import Foundation
import Supabase

// MARK: - Helper Structs

struct OrderIdOnly: Decodable { let id: String }
struct OrderItemRecordAna: Decodable { let quantity: Int? }
struct OrderRecordAna: Decodable {
    let id: String
    let total_amount: Double?
    let status: String
    let created_at: String
}
struct OrderCustomerPhone: Decodable { let customer_order_phone: String? }

// MARK: - Analytic Result Model

struct AnalyticResult: Equatable {
    let revenue: Double
    let total_order: Int
    let produk_terjual: Int
    let customer_baru: Int
}

// MARK: - BarChartEntry (import jika di file terpisah)
struct BarChartEntry: Identifiable, Equatable {
    let id: UUID = UUID()
    let label: String        // Label ringkas untuk chart: "10-16"
    let detailLabel: String
    // Label lengkap untuk display: "10 Nov - 16 Nov"
    let value: Double
}


// MARK: - Analytics Extension

extension SupabaseManager {

    // Utama: fetch analytics summary single range
    func fetchAnalytics(for userId: UUID, range: DateRange) async throws -> AnalyticResult {
        let userStr = userId.uuidString
        let startStr = range.start.toSupabaseString()
        let endStr = range.end.toSupabaseString()

        let ordersResponse = try await client
            .from("orders")
            .select("id,total_amount,status,created_at")
            .eq("user_id", value: userStr)
            .eq("status", value: "Selesai")
            .gte("created_at", value: startStr)
            .lt("created_at", value: endStr)
            .execute()
        let orderRecords = try JSONDecoder().decode([OrderRecordAna].self, from: ordersResponse.data)
        let revenue = orderRecords.reduce(0) { $0 + ($1.total_amount ?? 0) }
        let totalOrder = orderRecords.count
        let orderIds = orderRecords.map { $0.id }

        var produkTerjual = 0
        if !orderIds.isEmpty {
            let itemsResponse = try await client
                .from("order_items")
                .select("quantity, order_id")
                .in("order_id", value: orderIds)
                .execute()
            let itemRecords = try JSONDecoder().decode([OrderItemRecordAna].self, from: itemsResponse.data)
            produkTerjual = itemRecords.reduce(0) { $0 + ($1.quantity ?? 0) }
        }
        var uniquePhones: Set<String> = []
        do {
            let customerResponse = try await client
                .from("orders")
                .select("customer_order_phone")
                .eq("user_id", value: userStr)
                .eq("status", value: "Selesai")
                .gte("created_at", value: startStr)
                .lt("created_at", value: endStr)
                .execute()
            let phoneRecords = try JSONDecoder().decode([OrderCustomerPhone].self, from: customerResponse.data)
            uniquePhones = Set(phoneRecords.compactMap {
                let val = $0.customer_order_phone?.trimmingCharacters(in: .whitespaces)
                return (val?.isEmpty == false) ? val : nil
            })
        } catch {
            print("ERROR di bagian customerResponse: ", error)
        }
        let customerBaru = uniquePhones.count

        return AnalyticResult(
            revenue: revenue,
            total_order: totalOrder,
            produk_terjual: produkTerjual,
            customer_baru: customerBaru
        )
    }

    // Batch fetch window untuk bar chart Revenue
    func fetchRevenueHistory(for userId: UUID, tf: AnalyticTimeframe, windowOffset: Int = 0) async throws -> [BarChartEntry] {
        let c = Calendar.current
        let batchRange = DateRange.batchStart(for: tf, offset: windowOffset)
        let barLabels = DateRange.generateLabels(for: tf, batchStart: batchRange.start)
        var bars:[BarChartEntry] = []
        
        let df = DateFormatter()
        df.locale = Locale(identifier: "id-ID")
        
        switch tf {
        case .hari:
            df.dateFormat = "d MMM"  // Label bar chart ringkas
            let dfDetail = DateFormatter()
            dfDetail.locale = Locale(identifier: "id-ID")
            dfDetail.dateFormat = "d MMMM yyyy"  // Detail lengkap: "17 November 2025"
            
            for i in 0..<7 {
                let start = c.date(byAdding: .day, value: i, to: batchRange.start)!
                let end = c.date(byAdding: .day, value: 1, to: start)!
                let analytic = try await fetchAnalytics(for: userId, range: DateRange(start: start, end: end))
                bars.append(BarChartEntry(
                    label: barLabels[i],              // "17 Nov"
                    detailLabel: dfDetail.string(from: start),  // "17 November 2025"
                    value: analytic.revenue
                ))
            }
            
        case .minggu:
            df.dateFormat = "d"  // Label bar chart ringkas: "10-16"
            let dfDetail = DateFormatter()
            dfDetail.locale = Locale(identifier: "id-ID")
            dfDetail.dateFormat = "d MMM yyyy"  // Detail lengkap dengan tahun
            
            for i in 0..<4 {
                let start = c.date(byAdding: .day, value: i*7, to: batchRange.start)!
                let end = c.date(byAdding: .day, value: 7, to: start)!
                let weekEnd = c.date(byAdding: .day, value: 6, to: start)!
                let detailLabel = "\(dfDetail.string(from: start)) - \(dfDetail.string(from: weekEnd))"
                let analytic = try await fetchAnalytics(for: userId, range: DateRange(start: start, end: end))
                bars.append(BarChartEntry(
                    label: barLabels[i],              // "10-16"
                    detailLabel: detailLabel,         // "10 Nov 2025 - 16 Nov 2025"
                    value: analytic.revenue
                ))
            }

            
        case .bulan:
            df.dateFormat = "MMMM yyyy"
            let dfDetail = DateFormatter()
            for i in 0..<6 {
                let start = c.date(byAdding: .month, value: i, to: batchRange.start)!
                let end = c.date(byAdding: .month, value: 1, to: start)!
                let analytic = try await fetchAnalytics(for: userId, range: DateRange(start: start, end: end))
                bars.append(BarChartEntry(
                    label: barLabels[i],
                    detailLabel: df.string(from: start),  // "Nov 2025"
                    value: analytic.revenue
                ))
            }
            
        case .tahun:
            df.dateFormat = "yyyy"
            for i in 0..<5 {
                let start = c.date(byAdding: .year, value: i, to: batchRange.start)!
                let end = c.date(byAdding: .year, value: 1, to: start)!
                let analytic = try await fetchAnalytics(for: userId, range: DateRange(start: start, end: end))
                bars.append(BarChartEntry(
                    label: barLabels[i],
                    detailLabel: df.string(from: start),  // "2021"
                    value: analytic.revenue
                ))
            }
        }
        return bars
    }

    // Batch fetch window untuk bar chart produk terjual
    func fetchProdukTerjualHistory(for userId: UUID, tf: AnalyticTimeframe, windowOffset: Int = 0) async throws -> [BarChartEntry] {
        let c = Calendar.current
        let batchRange = DateRange.batchStart(for: tf, offset: windowOffset)
        let barLabels =
        DateRange.generateLabels(for: tf, batchStart: batchRange.start)
        var bars:[BarChartEntry] = []
        
        let df = DateFormatter()
        df.locale = Locale(identifier: "id-ID")
        
        switch tf {
        case .hari:
            df.dateFormat = "d MMM"  // Label bar chart ringkas
            let dfDetail = DateFormatter()
            dfDetail.locale = Locale(identifier: "id-ID")
            dfDetail.dateFormat = "d MMMM yyyy"  // Detail lengkap: "17 November 2025"
            
            for i in 0..<7 {
                let start = c.date(byAdding: .day, value: i, to: batchRange.start)!
                let end = c.date(byAdding: .day, value: 1, to: start)!
                let analytic = try await fetchAnalytics(for: userId, range: DateRange(start: start, end: end))
                bars.append(BarChartEntry(
                    label: barLabels[i],              // "17 Nov"
                    detailLabel: dfDetail.string(from: start),  // "17 November 2025"
                    value: Double(analytic.produk_terjual)
                ))
            }
            
        case .minggu:
            df.dateFormat = "d"  // Label bar chart ringkas: "10-16"
            let dfDetail = DateFormatter()
            dfDetail.locale = Locale(identifier: "id-ID")
            dfDetail.dateFormat = "d MMM yyyy"  // Detail lengkap dengan tahun
            
            for i in 0..<4 {
                let start = c.date(byAdding: .day, value: i*7, to: batchRange.start)!
                let end = c.date(byAdding: .day, value: 7, to: start)!
                let weekEnd = c.date(byAdding: .day, value: 6, to: start)!
                let detailLabel = "\(dfDetail.string(from: start)) - \(dfDetail.string(from: weekEnd))"
                let analytic = try await fetchAnalytics(for: userId, range: DateRange(start: start, end: end))
                bars.append(BarChartEntry(
                    label: barLabels[i],              // "10-16"
                    detailLabel: detailLabel,         // "10 Nov 2025 - 16 Nov 2025"
                    value: Double(analytic.produk_terjual)
                ))
            }

            
        case .bulan:
            df.dateFormat = "MMMM yyyy"
            for i in 0..<6 {
                let start = c.date(byAdding: .month, value: i, to: batchRange.start)!
                let end = c.date(byAdding: .month, value: 1, to: start)!
                let analytic = try await fetchAnalytics(for: userId, range: DateRange(start: start, end: end))
                bars.append(BarChartEntry(
                    label: barLabels[i],
                    detailLabel: df.string(from: start),
                    value: Double(analytic.produk_terjual)
                ))
            }
            
        case .tahun:
            df.dateFormat = "yyyy"
            for i in 0..<5 {
                let start = c.date(byAdding: .year, value: i, to: batchRange.start)!
                let end = c.date(byAdding: .year, value: 1, to: start)!
                let analytic = try await fetchAnalytics(for: userId, range: DateRange(start: start, end: end))
                bars.append(BarChartEntry(
                    label: barLabels[i],
                    detailLabel: df.string(from: start),
                    value: Double(analytic.produk_terjual)
                ))
            }
        }
        return bars
    }
    
    // Fetch tanggal order pertama user
    func fetchEarliestOrderDate(for userId: UUID) async throws -> Date? {
        let userStr = userId.uuidString
        
        let response = try await client
            .from("orders")
            .select("created_at")
            .eq("user_id", value: userStr)
            .eq("status", value: "Selesai")
            .order("created_at", ascending: true)
            .limit(1)
            .execute()
        
        struct OrderDate: Decodable {
            let created_at: String
        }
        
        let records = try JSONDecoder().decode([OrderDate].self, from: response.data)
        
        guard let firstDateStr = records.first?.created_at else {
            print("⚠️ No order records found")
            return nil
        }
        
        print("First Order Date String: \(firstDateStr)")
        
        // Parse ISO8601 dengan microseconds
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX"  // ← UBAH: Tambah .SSSSSS untuk microseconds
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")  // ← TAMBAH: Untuk konsistensi parsing
        
        if let date = formatter.date(from: firstDateStr) {
            print("✅ Parsed Earliest Order Date: \(date)")
            return date
        } else {
            print("❌ Failed to parse date: \(firstDateStr)")
            return nil
        }
    }
}

// MARK: - Date Extension (ISO8601 with offset for Supabase/Postgres)
extension Date {
    func toSupabaseString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: self)
    }
}
