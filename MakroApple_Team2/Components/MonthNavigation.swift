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
    
    var body: some View {
        HStack {
            Button {
              currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth)!
              selectedDate = snap(selectedDate, into: currentMonth)
              onMonthChanged?()
            } label: { Image(systemName: "chevron.left").font(.title3) }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text(viewModel.formattedMonthYear(for: currentMonth))
                    .font(isCollapsed ? .headline : .title2.bold())
            }
            
            Spacer()
            
            Button {
              currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth)!
              selectedDate = snap(selectedDate, into: currentMonth)
              onMonthChanged?()
            } label: { Image(systemName: "chevron.right").font(.title3) }
        }
        .padding(.horizontal)
        .padding(.vertical, isCollapsed ? 8 : 12)
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
