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
    
    private let swipeThreshold: CGFloat = 40
    
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
            Button(action: previousSection) {
               Image(systemName: "chevron.left")
                   .font(.title3)
                   .foregroundStyle(.primaryButton)
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
            
            Button(action: nextSection) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundStyle(.primaryButton)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, isCollapsed ? 8 : 12)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 10, coordinateSpace: .local)
                .onEnded { value in
                    let horizontal = value.translation.width

                    if horizontal > swipeThreshold {
                        // swipe right → previous month
                        previousSection()
                    } else if horizontal < -swipeThreshold {
                        // swipe left → next month
                        nextSection()
                    }
                }
        )
    }
    
    private func previousSection() {
        if isCollapsed {
            if let newDate = calendar.date(byAdding: .day, value: -7, to: selectedDate) {
                selectedDate = newDate
                currentMonth = startOfMonth(for: selectedDate)
            }
        } else {
            previousMonth()
        }
    }

    private func nextSection() {
        if isCollapsed {
            if let newDate = calendar.date(byAdding: .day, value: 7, to: selectedDate) {
                selectedDate = newDate
                currentMonth = startOfMonth(for: selectedDate)
            }
        } else {
            nextMonth()
        }
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
    
    private func startOfMonth(for date: Date) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
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
