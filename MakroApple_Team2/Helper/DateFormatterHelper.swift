//
//  DateFormatterHelper.swift
//  MakroApple_Team2
//
//  Created by Edward Suwandi on 23/10/25.
//

import Foundation

struct DateFormatterHelper {
    
    static func formattedDate(_ dateString: String, showTime: Bool = false) -> String {
        let inputFormatter = ISO8601DateFormatter()
        inputFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = inputFormatter.date(from: dateString) else {
            print("❌ Gagal parse tanggal:", dateString)
            return dateString
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.locale = Locale(identifier: "id_ID")
        
        if showTime {
            outputFormatter.dateFormat = "d MMMM YY, HH.mm"
        } else {
            outputFormatter.dateFormat = "d MMMM YY"
        }
        
        return outputFormatter.string(from: date)
    }
    
    static func formattedTime(_ dateString: String) -> String {
        let inputFormatter = ISO8601DateFormatter()
        inputFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = inputFormatter.date(from: dateString) else {
            print("❌ Gagal parse tanggal:", dateString)
            return dateString
        }
        
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "id_ID")
        timeFormatter.dateFormat = "HH:mm" // pakai format 24 jam
        
        return timeFormatter.string(from: date)
    }
    
    static func toDate(_ dateString: String) -> Date? {
        let isoFormatter = ISO8601DateFormatter()
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
    
    static func isoDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }
    
    static func indonesianDateAndTime(from isoString: String) -> (tanggal: String, jam: String) {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        guard let date = isoFormatter.date(from: isoString) else {
            return (isoString, "")
        }
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "id_ID")
        dateFormatter.dateFormat = "d MMMM yyyy"
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "id_ID")
        timeFormatter.dateFormat = "HH:mm"
        return (dateFormatter.string(from: date), timeFormatter.string(from: date))
    }
}

