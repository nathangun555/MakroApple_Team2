//
//  OnboardingView.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 14/10/25.
//

import SwiftUI

struct OnboardingView: View {
  @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
  @State private var page: Int = 0
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

  var body: some View {
    ZStack {
      LinearGradient(colors: [
      ], startPoint: .topLeading, endPoint: .bottomTrailing)
      .ignoresSafeArea()

      VStack(spacing: 0) {
        // Top bar
        HStack {
          Spacer()
          Button("Skip") { finishOnboarding() }
            .font(.callout.weight(.semibold))
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(reduceTransparency ? AnyShapeStyle(.bar) : AnyShapeStyle(.regularMaterial), in: Capsule())
        }
        .padding(.top, 12)
        .padding(.horizontal, 16)

        // Pages
        TabView(selection: $page) {
          page1Problem.tag(0)
          page2Capture.tag(1)
          page3Invoice.tag(2)
            page4Calendar.tag(3)
          page5Analytics.tag(4)
        }
        .tabViewStyle(.page)

        // Bottom controls
        Group {
          if page < 4 {
            HStack(alignment: .center) {
              // Left arrow (previous)
              Button {
                withAnimation { page = max(page, 0) }
              } label: {
                Image(systemName: "chevron.left")
                  .font(.title3.weight(.semibold))
                  .padding(10)
                  .background(reduceTransparency ? AnyShapeStyle(.bar) : AnyShapeStyle(.regularMaterial), in: Circle())
              }
              .opacity(page == 0 ? 0 : 1)
              .accessibilityLabel("Previous")

              Spacer(minLength: 12)

              // Dots indicator (pure SwiftUI)
              PageIndicator(count: 5, current: page,
                            activeColor: .primary,
                            inactiveColor: .secondary.opacity(0.3),
                            size: 8, spacing: 6)

              Spacer(minLength: 12)

              // Right arrow (next)
              Button {
                withAnimation { page = min(page + 1, 4) }
              } label: {
                Image(systemName: "chevron.right")
                  .font(.title3.weight(.semibold))
                  .padding(10)
                  .background(reduceTransparency ? AnyShapeStyle(.bar) : AnyShapeStyle(.ultraThickMaterial), in: Circle())
              }
              .accessibilityLabel("Next")
            }
          } else {
            VStack(spacing: 10) {
              Button {
                finishOnboarding()
              } label: {
                Text("Start")
                  .font(.headline.weight(.semibold))
                  .padding(.horizontal, 18)
                  .padding(.vertical, 12)
                  .background(reduceTransparency ? AnyShapeStyle(.bar) : AnyShapeStyle(.ultraThickMaterial), in: Capsule())
              }
              .accessibilityLabel("Start")

              PageIndicator(count: 5, current: page,
                            activeColor: .primary,
                            inactiveColor: .secondary.opacity(0.3),
                            size: 8, spacing: 6)
            }
          }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
      }
    }
  }

  private func finishOnboarding() {
    hasSeenOnboarding = true
    // TODO: navigate to your root ContentView or dismiss
  }

  // MARK: - Single-file page views

  private var page1Problem: some View {
    VStack(spacing: 20) {
      iconBubble("tray.and.arrow.down.fill")
      Text("Stop copying orders from DMs.")
        .font(.title2.weight(.bold))
        .multilineTextAlignment(.center)
      Text("Turn messages into clean, trackable orders—no spreadsheets, no manual work.")
        .font(.callout).foregroundStyle(.secondary)
        .multilineTextAlignment(.center)

      VStack(spacing: 12) {
        glassTile {
          HStack {
            Image(systemName: "text.bubble")
            Text("DM text")
            Spacer()
          }
        }
        Image(systemName: "arrow.down.circle.fill")
          .font(.system(size: 28, weight: .semibold))
          .foregroundStyle(.secondary)
        glassTile {
          HStack {
            Image(systemName: "list.bullet.rectangle.portrait")
            Text("Order card")
            Spacer()
          }
        }
      }
    }
    .padding(.horizontal, 20).padding(.vertical, 16)
  }

  private var page2Capture: some View {
    VStack(spacing: 20) {
      iconBubble("square.and.pencil.circle.fill")
      Text("Capture once. Reuse everywhere.")
        .font(.title2.weight(.bold))
        .multilineTextAlignment(.center)
      Text("Paste a message or fill a quick form. Your order, customer, and details are ready across the app.")
        .font(.callout).foregroundStyle(.secondary)
        .multilineTextAlignment(.center)

      HStack(spacing: 8) { chip("Order"); chip("Invoice"); chip("Calendar"); chip("Recap") }
      glassTile {
        VStack(alignment: .leading, spacing: 10) {
          labeledRow("Customer", "Aisyah / 0812‑xxxx‑xxxx")
          labeledRow("Item", "Cake • Choco • 1 pc")
          labeledRow("Delivery", "Today, 16:00")
        }
      }
    }
    .padding(.horizontal, 20).padding(.vertical, 16)
  }

  private var page3Invoice: some View {
    VStack(spacing: 20) {
      iconBubble("doc.richtext.fill")
      Text("Instant invoices your customers trust.")
        .font(.title2.weight(.bold))
        .multilineTextAlignment(.center)
      Text("Auto‑generate branded invoices and share via WhatsApp in one tap.")
        .font(.callout).foregroundStyle(.secondary)
        .multilineTextAlignment(.center)

      glassTile {
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Circle().fill(.secondary).frame(width: 22, height: 22)
            Text("Your Brand").font(.headline)
            Spacer()
            Text("#INV‑2025‑001").foregroundStyle(.secondary).font(.subheadline)
          }
          Divider()
          HStack { Text("Chocolate Cake x1"); Spacer(); Text("Rp 220.000") }
          HStack { Text("Shipping (Grab)"); Spacer(); Text("Rp 25.000") }
          Divider()
          HStack { Text("Total").font(.headline); Spacer(); Text("Rp 245.000").font(.headline) }
        }
      }

      HStack(spacing: 10) {
        Image(systemName: "paperplane.circle.fill").font(.title3)
        Text("Share via WhatsApp / PDF").foregroundStyle(.secondary)
      }
    }
    .padding(.horizontal, 20).padding(.vertical, 16)
  }

  private var page4Calendar: some View {
    VStack(spacing: 20) {
      iconBubble("calendar")
      Text("Never miss a prep or delivery.")
        .font(.title2.weight(.bold))
        .multilineTextAlignment(.center)
      Text("Your active orders on a calendar with smart filters.")
        .font(.callout).foregroundStyle(.secondary)
        .multilineTextAlignment(.center)

      glassTile {
        VStack(alignment: .leading, spacing: 12) {
          HStack { Text("October 2025").font(.headline); Spacer(); Image(systemName: "calendar.badge.clock") }
          RoundedRectangle(cornerRadius: 8).fill(.secondary.opacity(0.25)).frame(height: 80)
          HStack {
            Image(systemName: "clock").foregroundStyle(.secondary)
            Text("Today 16:00 • Chocolate Cake • Unpaid").font(.subheadline)
            Spacer()
            Circle().fill(.orange).frame(width: 10, height: 10)
          }
        }
      }

      HStack(spacing: 8) { chip("Paid", tint: .green); chip("Unpaid", tint: .orange); chip("Today", outline: true) }
    }
    .padding(.horizontal, 20).padding(.vertical, 16)
  }

  private var page5Analytics: some View {
    VStack(spacing: 20) {
      iconBubble("chart.bar.doc.horizontal.fill")
      Text("See revenue and top products.")
        .font(.title2.weight(.bold))
        .multilineTextAlignment(.center)
      Text("Simple dashboards that spotlight what’s working.")
        .font(.callout).foregroundStyle(.secondary)
        .multilineTextAlignment(.center)

      glassTile {
        VStack(alignment: .leading, spacing: 12) {
          HStack {
            kpi("Revenue (MoM)", "Rp 32.5M", "+12%")
            kpi("Paid rate", "86%", "+5%")
          }
          RoundedRectangle(cornerRadius: 10).fill(.secondary.opacity(0.25)).frame(height: 110)
        }
      }
    }
    .padding(.horizontal, 20).padding(.vertical, 16)
  }

  // MARK: - Small helpers (inline for single-file)

  @ViewBuilder private func iconBubble(_ name: String) -> some View {
    Image(systemName: name)
      .font(.system(size: 44, weight: .semibold))
      .padding(16)
      .background(reduceTransparency ? AnyShapeStyle(.bar) : AnyShapeStyle(.ultraThickMaterial), in: Circle())
      .overlay(Circle().stroke(.white.opacity(0.15)))
      .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
  }

  @ViewBuilder private func glassTile<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
    VStack { content() }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(16)
      .background(reduceTransparency ? AnyShapeStyle(.bar) : AnyShapeStyle(.regularMaterial), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
  }

  @ViewBuilder private func labeledRow(_ label: String, _ value: String) -> some View {
    HStack {
      Text(label).font(.caption).foregroundStyle(.secondary)
      Spacer()
      Text(value).font(.callout.weight(.semibold))
    }
  }

  @ViewBuilder private func chip(_ text: String, tint: Color? = nil, outline: Bool = false) -> some View {
    Text(text)
      .font(.caption.weight(.semibold))
      .padding(.horizontal, 10).padding(.vertical, 6)
      .background(
        outline
          ? AnyShapeStyle(.clear)
          : (tint != nil
              ? AnyShapeStyle((reduceTransparency ? tint!.opacity(0.25) : tint!.opacity(0.35)))
              : (reduceTransparency ? AnyShapeStyle(.bar) : AnyShapeStyle(.regularMaterial))
            ),
        in: Capsule()
      )
      .overlay(Capsule().stroke(.white.opacity(0.15)))
  }

  @ViewBuilder private func kpi(_ title: String, _ value: String, _ delta: String) -> some View {
    VStack(alignment: .leading) {
      Text(title).font(.caption).foregroundStyle(.secondary)
      Text(value).font(.title3.weight(.semibold))
      Text(delta).font(.footnote).foregroundStyle(delta.hasPrefix("-") ? .red : .green)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct PageIndicator: View {
  let count: Int
  let current: Int
  var activeColor: Color = .primary
  var inactiveColor: Color = .secondary.opacity(0.3)
  var size: CGFloat = 8
  var spacing: CGFloat = 6

  var body: some View {
    HStack(spacing: spacing) {
      ForEach(0..<count, id: \.self) { i in
        Circle()
          .fill(i == current ? activeColor : inactiveColor)
          .frame(width: size, height: size)
          .animation(.easeInOut(duration: 0.2), value: current)
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Page")
    .accessibilityValue("\(current + 1) of \(count)")
  }
}

#Preview {
  OnboardingView()
}
