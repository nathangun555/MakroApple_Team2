//
//  CalendarHeader.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 27/10/25.
//

import SwiftUI
import Foundation

// MARK: - Calendar Header View
struct CalendarHeaderView: View {
  @Binding var selectedDate: Date
  @Binding var currentMonth: Date
  @Binding var isCollapsed: Bool
  var viewModel = AllOrdersViewModel()
  private let daysOfWeek = ["MIN","SEN","SEL","RAB","KAM","JUM","SAB"]
    private let weekHeight: CGFloat = 72
    private let monthHeight: CGFloat = 312
    
  var body: some View {
    VStack(spacing: 0) {
        MonthNavigationView(
          currentMonth: $currentMonth,
          selectedDate: $selectedDate,
          isCollapsed: isCollapsed,
          onMonthChanged: {
            withAnimation(.easeInOut(duration: 0.18)) {
              isCollapsed = false
            }
          },
          viewModel: viewModel
        )

      DayLabelsView(daysOfWeek: daysOfWeek)

      CombinedCalendarView(
        selectedDate: $selectedDate,
        currentMonth: $currentMonth,
        isCollapsed: $isCollapsed,
        viewModel: viewModel
      )
      .frame(height: isCollapsed ? weekHeight : monthHeight)
      .clipped()
      .animation(.easeInOut(duration: 0.18), value: isCollapsed)
    }
//    .background(.ultraThinMaterial)
  }
}

// MARK: - Day Labels View
struct DayLabelsView: View {
    let daysOfWeek: [String]
    
    var body: some View {
        HStack {
            ForEach(daysOfWeek, id: \.self) { day in
                Text(day)
                    .font(.caption2)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
