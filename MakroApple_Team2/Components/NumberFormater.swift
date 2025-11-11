//
//  NumberFormater.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 11/11/25.
//

import Foundation

public enum IDRFormat {
    // Formatter grouping ribuan, tanpa simbol Rp
    public static let grouping: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "id_ID")
        f.numberStyle = .decimal
        f.groupingSeparator = "."
        f.decimalSeparator = ","
        f.maximumFractionDigits = 0
        return f
    }()

    // Format Int/Decimal ke string ber-titik
    public static func string(from int: Int) -> String {
        grouping.string(from: NSNumber(value: int)) ?? "\(int)"
    }

    public static func string(from decimal: Decimal) -> String {
        let ns = NSDecimalNumber(decimal: decimal)
        return grouping.string(from: ns) ?? ns.stringValue
    }

    // Parse string “1.000.000” -> Decimal(1000000)
    public static func decimal(from grouped: String) -> Decimal? {
        let digits = grouped.filter { $0.isNumber }
        return Decimal(string: digits)
    }
}
