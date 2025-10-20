//
//  ActiveOrdersView.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 10/10/25.
//

import SwiftUI

struct ActiveOrdersView: View {
    @State private var viewModel = ActiveOrdersViewModel()
    @State private var selectedDate: Date = Date()
    @State private var currentMonth: Date = Date()
    @State private var isCollapsed: Bool = false

    @State private var lastListMinY: CGFloat = 0
    private let collapseThreshold: CGFloat = 8
    private let expandThreshold: CGFloat = 12
    private let expandNearTop: CGFloat = 16
    private let minDeltaToConsider: CGFloat = 0.5

    var body: some View {
        NavigationStack {
          VStack(spacing: 0) {
            CalendarHeaderView(
              selectedDate: $selectedDate,
              currentMonth: $currentMonth,
              isCollapsed: $isCollapsed,
              viewModel: viewModel
            )

            Divider()

            ScrollView {
              LazyVStack(spacing: 0) {
                OrderListView(
                  selectedDate: selectedDate,
                  viewModel: viewModel
                )
                .background(
                  GeometryReader { geo in
                    let minY = geo.frame(in: .named("ordersSpace")).minY
                    Color.clear
                      .onChange(of: minY, initial: true) { oldY, newY in
                        let rawDelta = newY - oldY
                          
                        // Ignore jitter
                        guard abs(rawDelta) > 15 else { return }

                        // Velocity bias: quick flicks count more, but capped
                        let bias = min(max(abs(rawDelta) / 18, 1), 2.0)
                        let delta = rawDelta * bias

                          withAnimation(.easeInOut(duration: 0)) {
                          // Scrolling up (content moves up) => delta negative => collapse
                          if delta < -6, !isCollapsed, newY < -20 {
                            isCollapsed = true
                          }
                          // Scrolling down (content moves down) => delta positive => expand if near top
                          else if delta > 6, isCollapsed, newY > 20 {
                            isCollapsed = false
                          }
                        }
                      }
                  }
                )
              }
            }
            .coordinateSpace(name: "ordersSpace")
          }
          .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Month Navigation View
struct MonthNavigationView: View {
    @Binding var currentMonth: Date
    @Binding var selectedDate: Date
    let isCollapsed: Bool
    let calendar = Calendar.current
    var onMonthChanged: (() -> Void)? = nil
    var viewModel = ActiveOrdersViewModel()
    
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

// MARK: - Calendar Header View
struct CalendarHeaderView: View {
  @Binding var selectedDate: Date
  @Binding var currentMonth: Date
  @Binding var isCollapsed: Bool
  var viewModel = ActiveOrdersViewModel()
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
    .background(.ultraThinMaterial)
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

// MARK: - Combined Calendar View (Month + Week)
struct CombinedCalendarView: View {
    @Binding var selectedDate: Date
    @Binding var currentMonth: Date
    @Binding var isCollapsed: Bool
    var viewModel: ActiveOrdersViewModel

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
    var viewModel: ActiveOrdersViewModel
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
    var viewModel: ActiveOrdersViewModel
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

    // MARK: Date cell (shared)
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
              ? Color.blue
              : (isToday ? Color.blue.opacity(0.15) : .clear)
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

// MARK: - Order List View
struct OrderListView: View {
    let selectedDate: Date
    let calendar = Calendar.current
    var viewModel = ActiveOrdersViewModel()
    
    var body: some View {
        let ordersForSelectedDate = viewModel.ordersForDate(for: selectedDate)
        
        if ordersForSelectedDate.isEmpty {
            Text("Tidak ada pesanan")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 500)  // Give enough height to scroll
        } else {
            LazyVStack(spacing: 8) {
                ForEach(ordersForSelectedDate) { order in
                    NavigationLink {
                        OrderDetailView(order: order)
                    } label: {
                        OrderrCardView(order: order)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)
        }
    }
}

// MARK: - Order Card View
struct OrderrCardView: View {
    let order: Order
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Nama Pemesan")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Jam")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(order.customer_order_name)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.secondary.opacity(0.07))
        .cornerRadius(10)
    }
}

// MARK: - Scroll Offset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    ActiveOrdersView()
}
