//
//  DateFormatterHelper.swift
//  MakroApple_Team2
//
//  Created by Edward Suwandi on 23/10/25.
//

import Foundation

struct DateFormatterHelper {
    
//    static func formattedDate(_ dateString: String, showTime: Bool = false) -> String {
//        let inputFormatter = ISO8601DateFormatter()
//        inputFormatter.formatOptions = [.withInternetDateTime]
//        
//        guard let date = inputFormatter.date(from: dateString) else {
//            print("❌ Gagal parse tanggal ke formattedDate:", dateString)
//            return dateString
//        }
//        
//        let outputFormatter = DateFormatter()
//        outputFormatter.locale = Locale(identifier: "id_ID")
//        
//        if showTime {
//            outputFormatter.dateFormat = "d MMMM YYYY, HH.mm"
//        } else {
//            outputFormatter.dateFormat = "d MMMM YYYY"
//        }
//        
//        return outputFormatter.string(from: date)
//    }
    static func formattedDate(_ dateString: String, showTime: Bool = false) -> String {
        // Try ISO8601 with fractional seconds first, then without.
        let isoWithFrac = ISO8601DateFormatter()
        isoWithFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let isoNoFrac = ISO8601DateFormatter()
        isoNoFrac.formatOptions = [.withInternetDateTime]
        
        let date: Date?
        if let d = isoWithFrac.date(from: dateString) {
            date = d
        } else if let d = isoNoFrac.date(from: dateString) {
            date = d
        } else {
            print("❌ Gagal parse tanggal ke formattedDate:", dateString)
            return dateString
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.locale = Locale(identifier: "id_ID")
        outputFormatter.timeZone = .current // or specify UTC if you prefer
        
        if showTime {
            // you used dot as time separator before (HH.mm) — you can keep it or use "HH:mm"
            outputFormatter.dateFormat = "d MMMM yyyy, HH.mm"
        } else {
            outputFormatter.dateFormat = "d MMMM yyyy"
        }
        
        return outputFormatter.string(from: date!)
    }

    
    static func formattedTime(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        var date: Date? = isoFormatter.date(from: dateString)
        
        if date == nil {
            // fallback tanpa fractional seconds
            let fallbackFormatter = ISO8601DateFormatter()
            fallbackFormatter.formatOptions = [.withInternetDateTime]
            date = fallbackFormatter.date(from: dateString)
        }
        
        guard let validDate = date else {
            print("❌ Gagal parse tanggal ke formattedTime:", dateString)
            return "-"
        }
        
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "id_ID")
        timeFormatter.dateFormat = "HH:mm"
        
        return timeFormatter.string(from: validDate)
    }

    
    static func toDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: dateString) {
            return date
        }
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return isoFormatter.date(from: dateString)
    }
    
    static func dateToISO(_ dateString: String) -> String? {
        let locale = Locale(identifier: "id_ID")
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "dd MMMM yyyy"
        if let date = formatter.date(from: dateString) {
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
            return isoFormatter.string(from: date)
        }
        return nil
    }
    
    static func dateTimeToISO(dateString: String, timeString: String) -> String? {
        let locale = Locale(identifier: "id_ID")
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "dd MMMM yyyy HH:mm"
        let combined = dateString.trimmingCharacters(in: .whitespaces) + " " + timeString.trimmingCharacters(in: .whitespaces)
        if let date = formatter.date(from: combined) {
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
            return isoFormatter.string(from: date)
        }
        return nil
    }
    
    static func orderNumberString(from date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd/HHmmss"
        return df.string(from: date)
    }
    
    static func orderYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: date)
    }
    
    static func generateInvoiceNumber(orderDate: Date, orderCount: Int) -> String {
        let yearString = DateFormatterHelper.orderYearString(from: orderDate)
        let counterString = String(format: "%05d", orderCount + 1)
        return "INV/\(yearString)/\(counterString)"
    }
    
    static func isoDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }
    
//    static func indonesianDateAndTime(from isoString: String) -> (tanggal: String, jam: String) {
//        let isoFormatter = ISO8601DateFormatter()
//        isoFormatter.formatOptions = [.withInternetDateTime]
//        guard let date = isoFormatter.date(from: isoString) else {
//            return (isoString, "")
//        }
//        let dateFormatter = DateFormatter()
//        dateFormatter.locale = Locale(identifier: "id_ID")
//        dateFormatter.dateFormat = "d MMMM yyyy"
//        let timeFormatter = DateFormatter()
//        timeFormatter.locale = Locale(identifier: "id_ID")
//        timeFormatter.dateFormat = "HH:mm"
//        return (dateFormatter.string(from: date), timeFormatter.string(from: date))
//    }
    
    // For Date and Time Picker
    func parseIndonesianDate(_ text: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.dateFormat = "dd MMMM yyyy"
        return formatter.date(from: text)
    }

    func formatIndonesianDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.dateFormat = "dd MMMM yyyy"
        return formatter.string(from: date)
    }

    func parseTime(_ text: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: text)
    }

    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

}

