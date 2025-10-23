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
}

