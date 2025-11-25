//
//  CombinedCalendar.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 27/10/25.
//

import SwiftUI
import Foundation

// MARK: - Combined Calendar View (Month + Week)
struct CombinedCalendarView: View {
    @Binding var selectedDate: Date
    @Binding var currentMonth: Date
    @Binding var isCollapsed: Bool
    var viewModel: AllOrdersViewModel

    private let calendar = Calendar.current

    var body: some View {
    ZStack {
      MonthGrid(
        selectedDate: $selectedDate,
        currentMonth: currentMonth,
        viewModel: viewModel
      )
      .opacity(isCollapsed ? 0 : 1)
      .allowsHitTesting(!isCollapsed)

      WeekStrip(
        selectedDate: $selectedDate,
        viewModel: viewModel
      )
      .frame(height: 56)
      .opacity(isCollapsed ? 1 : 0)
      .allowsHitTesting(isCollapsed)
    }
    .animation(.easeInOut(duration: 0.18), value: isCollapsed)
    .padding(.bottom, isCollapsed ? 0 : 8)
    }

    // MARK: Month grid
    private struct MonthGrid: View {
    @Binding var selectedDate: Date
    let currentMonth: Date
    var viewModel: AllOrdersViewModel
    private let calendar = Calendar.current

    var body: some View {
      LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 0) {
        ForEach(viewModel.generateDays(for: currentMonth), id: \.self) { day in
          let inMonth = calendar.isDate(day, equalTo: currentMonth, toGranularity: .month)
          DateCell(
            date: day,
            selectedDate: selectedDate,
            inCurrentMonth: inMonth,
            hasOrders: viewModel.hasOrders(for: day),
            onTap: { selectedDate = day }
          )
        }
      }
      .padding(.horizontal)
    }
    }

    // MARK: Week strip
    private struct WeekStrip: View {
    @Binding var selectedDate: Date
    var viewModel: AllOrdersViewModel
    private let calendar = Calendar.current

    var body: some View {
      HStack(spacing: 18) {
        ForEach(weekDates, id: \.self) { day in
          DateCell(
            date: day,
            selectedDate: selectedDate,
            inCurrentMonth: true,
            hasOrders: viewModel.hasOrders(for: day),
            onTap: { selectedDate = day }
          )
        }
      }
      .padding(.horizontal)
    }

    private var weekDates: [Date] {
      guard let interval = calendar.dateInterval(of: .weekOfMonth, for: selectedDate) else { return [] }
      return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: interval.start) }
    }
    }

    // MARK: Date cell
    private struct DateCell: View {
    let date: Date
    let selectedDate: Date
    let inCurrentMonth: Bool
    let hasOrders: Bool
    let onTap: () -> Void

    private let calendar = Calendar.current

    var body: some View {
      Button(action: onTap) {
        VStack(spacing: 0) {
          Text("\(calendar.component(.day, from: date))")
            .font(.body)
            .fontWeight(isToday || isSelected ? .bold : .regular)
            .frame(width: 36, height: 42)
            .background(
              isSelected
              ? Color.primaryButton
              : (isToday ? Color.primaryButton.opacity(0.15) : .clear)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .foregroundColor(
              isSelected
              ? .white
              : (inCurrentMonth ? .primary : .gray.opacity(0.4))
            )

          Circle()
            .fill(Color.gray.opacity(0.9))
            .frame(width: 7, height: 7)
            .overlay(Circle().stroke(.white, lineWidth: 1.5))
            .opacity(hasOrders ? 1 : 0)
        }
      }
      .buttonStyle(.plain)
    }

    private var isSelected: Bool { calendar.isDate(date, inSameDayAs: selectedDate) }
    private var isToday: Bool { calendar.isDateInToday(date) }
    }
}

#Preview("Signed In") {
    let session = SessionManager()
    session.isAuthLoaded = true
    session.isSignedIn = true

    return MainTabView(
        selectedTab: .constant(0),
        sharedText: .constant("Test Text"),
        hasNewObject: .constant(false),
        sharedImages: .constant([])
    )
    .environmentObject(session)
    .environmentObject(DeleteOverlayBus())
    .environmentObject(UnsavedOverlayBus())
}
