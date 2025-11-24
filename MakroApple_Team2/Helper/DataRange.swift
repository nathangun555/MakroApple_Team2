//
//  DataRange.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 21/11/25.
//

//import Foundation
//
//enum AnalyticTimeframe: String, CaseIterable { case hari, minggu, bulan, tahun }
//
//struct DateRange {
//    var start: Date
//    var end: Date
//    
//    static func today() -> DateRange {
//        let c = Calendar.current
//        let start = c.startOfDay(for: Date())
//        let end = c.date(byAdding: .day, value: 1, to: start)!
//        return DateRange(start: start, end: end)
//    }
//    
//    static func range(for tf: AnalyticTimeframe) -> DateRange {
//        let now = Date()
//        let c = Calendar.current
//        switch tf {
//        case .hari:    return today()
//        case .minggu:
//            let start = c.date(byAdding: .day, value: -6, to: today().start)!
//            return DateRange(start: start, end: today().end)
//        case .bulan:
//            let comps = c.dateComponents([.year, .month], from: now)
//            let start = c.date(from: comps)!
//            let end = c.date(byAdding: .month, value: 1, to: start)!
//            return DateRange(start: start, end: end)
//        case .tahun:
//            let comps = c.dateComponents([.year], from: now)
//            let start = c.date(from: comps)!
//            let end = c.date(byAdding: .year, value: 1, to: start)!
//            return DateRange(start: start, end: end)
//        }
//    }
//    
//    func previous(_ tf: AnalyticTimeframe) -> DateRange {
//        let c = Calendar.current
//        switch tf {
//        case .hari:
//            let prev = c.date(byAdding: .day, value: -1, to: start)!
//            return DateRange(start: prev, end: start)
//        case .minggu:
//            let prev = c.date(byAdding: .day, value: -7, to: start)!
//            return DateRange(start: prev, end: start)
//        case .bulan:
//            let prev = c.date(byAdding: .month, value: -1, to: start)!
//            return DateRange(start: prev, end: start)
//        case .tahun:
//            let prev = c.date(byAdding: .year, value: -1, to: start)!
//            return DateRange(start: prev, end: start)
//        }
//    }
//    
//    func next(_ tf: AnalyticTimeframe) -> DateRange {
//        let c = Calendar.current
//        switch tf {
//        case .hari:
//            let next = c.date(byAdding: .day, value: 1, to: end)!
//            return DateRange(start: end, end: next)
//        case .minggu:
//            let next = c.date(byAdding: .day, value: 7, to: end)!
//            return DateRange(start: end, end: next)
//        case .bulan:
//            let next = c.date(byAdding: .month, value: 1, to: end)!
//            return DateRange(start: end, end: next)
//        case .tahun:
//            let next = c.date(byAdding: .year, value: 1, to: end)!
//            return DateRange(start: end, end: next)
//        }
//    }
//    
//    var isFirst: Bool { false }
//    var isLatest: Bool { end >= Calendar.current.startOfDay(for: Date()).addingTimeInterval(86399) }
//    func displayName(_ tf: AnalyticTimeframe) -> String {
//        let df = DateFormatter()
//        df.locale = Locale(identifier: "id-ID")
//        switch tf {
//        case .hari:
//            df.dateStyle = .long
//            return df.string(from: start)
//        case .minggu:
//            df.dateStyle = .short
//            return "\(df.string(from: start)) – \(df.string(from: end.addingTimeInterval(-86400)))"
//        case .bulan:
//            df.dateFormat = "MMMM yyyy"
//            return df.string(from: start)
//        case .tahun:
//            df.dateFormat = "yyyy"
//            return df.string(from: start)
//        }
//    }
//}

// DataRange.swift

import Foundation

enum AnalyticTimeframe: String, CaseIterable {
    case hari = "Harian"      // ← Ubah dari "hari"
    case minggu = "Mingguan"  // ← Ubah dari "minggu"
    case bulan = "Bulanan"    // ← Ubah dari "bulan"
    case tahun = "Tahunan"    // ← Ubah dari "tahun"
}


struct DateRange {
    var start: Date
    var end: Date

    static func today() -> DateRange {
        let c = Calendar.current
        let start = c.startOfDay(for: Date())
        let end = c.date(byAdding: .day, value: 1, to: start)!
        return DateRange(start: start, end: end)
    }

    // Window batch start - hitung start berdasarkan timeframe dan offset
    static func batchStart(for tf: AnalyticTimeframe, offset: Int) -> DateRange {
        let c = Calendar.current
        let now = Date()
        switch tf {
        case .hari:
            let start = c.date(byAdding: .day, value: -6 - (offset*7), to: c.startOfDay(for: now))!
            let end = c.date(byAdding: .day, value: 1 - (offset*7), to: c.startOfDay(for: now))!
            return DateRange(start: start, end: end)
        case .minggu:
            let start = c.date(byAdding: .day, value: -(4*7-1) - (offset*4*7), to: c.startOfDay(for: now))!
            let end = c.date(byAdding: .day, value: 1 - (offset*4*7), to: c.startOfDay(for: now))!
            return DateRange(start: start, end: end)
        case .bulan:
            let comps = c.dateComponents([.year, .month], from: now)
            let refStart = c.date(from: comps)!
            let start = c.date(byAdding: .month, value: -5 - (offset*6), to: refStart)!
            let end = c.date(byAdding: .month, value: 1 - (offset*6), to: refStart)!
            return DateRange(start: start, end: end)
        case .tahun:
            let comps = c.dateComponents([.year], from: now)
            let refStart = c.date(from: comps)!
            let start = c.date(byAdding: .year, value: -4 - (offset*5), to: refStart)!
            let end = c.date(byAdding: .year, value: 1 - (offset*5), to: refStart)!
            return DateRange(start: start, end: end)
        }
    }

    static func generateLabels(for tf: AnalyticTimeframe, batchStart: Date) -> [String] {
        let c = Calendar.current
        let df = DateFormatter()
        df.locale = Locale(identifier: "id-ID")
        var labels: [String] = []
        switch tf {
        case .hari:
            df.dateFormat = "d"
            for i in 0..<7 {
                let date = c.date(byAdding: .day, value: i, to: batchStart)!
                labels.append(df.string(from: date))
            }
        case .minggu:
            df.dateFormat = "d"  // Ringkas: "10-16"
            for i in 0..<4 {
                let weekStart = c.date(byAdding: .day, value: i*7, to: batchStart)!
                let weekEnd = c.date(byAdding: .day, value: 6, to: weekStart)!
                let startStr = df.string(from: weekStart)
                let endStr = df.string(from: weekEnd)
                labels.append("\(startStr)-\(endStr)")
            }
        case .bulan:
            df.dateFormat = "MMM"
            for i in 0..<6 {
                let date = c.date(byAdding: .month, value: i, to: batchStart)!
                labels.append(df.string(from: date))
            }
        case .tahun:
            df.dateFormat = "yyyy"
            for i in 0..<5 {
                let date = c.date(byAdding: .year, value: i, to: batchStart)!
                labels.append(df.string(from: date))
            }
        }
        return labels
    }
    
    static func displayWindowRange(for tf: AnalyticTimeframe, offset: Int) -> String {
        let batch = batchStart(for: tf, offset: offset)
        let df = DateFormatter()
        df.locale = Locale(identifier: "id-ID")
        
        switch tf {
        case .hari:
            df.dateFormat = "d MMM yyyy"
            let startStr = df.string(from: batch.start)
            let endStr = df.string(from: batch.end.addingTimeInterval(-86400)) // -1 hari
            return "\(startStr) - \(endStr)"
            
        case .minggu:
            df.dateFormat = "d MMM yyyy"
            let startStr = df.string(from: batch.start)
            let endStr = df.string(from: batch.end.addingTimeInterval(-86400))
            return "\(startStr) - \(endStr)"
            
        case .bulan:
            df.dateFormat = "MMM yyyy"
            let startStr = df.string(from: batch.start)
            let endDate = Calendar.current.date(byAdding: .month, value: 6, to: batch.start)!
            let endStr = df.string(from: endDate.addingTimeInterval(-86400))
            return "\(startStr) - \(endStr)"
            
        case .tahun:
            let startYear = Calendar.current.component(.year, from: batch.start)
            let endDate = Calendar.current.date(byAdding: .year, value: 5, to: batch.start)!
            let endYear = Calendar.current.component(.year, from: endDate.addingTimeInterval(-86400))
            return "\(startYear) - \(endYear)"
        }
    }
}
