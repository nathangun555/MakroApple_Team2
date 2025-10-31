//
//  MonthNavigation.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 27/10/25.
//

import SwiftUI
import Foundation

// MARK: - Month Navigation View
struct MonthNavigationView: View {
    @Binding var currentMonth: Date
    @Binding var selectedDate: Date
    let isCollapsed: Bool
    let calendar = Calendar.current
    var onMonthChanged: (() -> Void)? = nil
    var viewModel = AllOrdersViewModel()
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.dateFormat = "EEEE"
        return formatter
    }
    
    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
        
    var body: some View {
        HStack {
            Button(action: previousMonth) {
               Image(systemName: "chevron.left")
                   .font(.title3)
                   .foregroundStyle(.primary)
           }
            
            Spacer()
            
            if isCollapsed {
                VStack(spacing: 2) {
                    Text(dayFormatter.string(from: selectedDate))
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(monthYearFormatter.string(from: selectedDate))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .transition(.opacity)
            } else {
                Text(monthYearFormatter.string(from: currentMonth))
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .transition(.opacity)
            }
            
            Spacer()
            
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, isCollapsed ? 8 : 12)
    }
    
    private func previousMonth() {
        currentMonth = Calendar.current.date(
            byAdding: .month,
            value: -1,
            to: currentMonth
        ) ?? currentMonth
        onMonthChanged!()
    }
    
    private func nextMonth() {
        currentMonth = Calendar.current.date(
            byAdding: .month,
            value: 1,
            to: currentMonth
        ) ?? currentMonth
        onMonthChanged!()
    }
    
    private func snap(_ date: Date, into month: Date) -> Date {
      let day = calendar.component(.day, from: date)
      guard
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: month)),
        let range = calendar.range(of: .day, in: .month, for: start)
      else { return month }
      let clamped = min(max(day, range.lowerBound), range.upperBound - 0)
      return calendar.date(byAdding: .day, value: clamped - 1, to: start) ?? start
    }
}
