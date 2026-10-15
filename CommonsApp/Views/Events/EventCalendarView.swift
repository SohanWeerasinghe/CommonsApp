//
//  EventCalendarView.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 21/9/2026.
//


import SwiftUI

struct EventCalendarView: View {

    @EnvironmentObject var store: AppStore

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.wallBackgroundTop, Theme.wallBackgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // Header
                    EventsHeader()

                    // Calendar
                    EventMonthCalendar()
                        .padding(.top, 20)

                    // Upcoming section
                    Text("UPCOMING")
                        .font(Theme.ui(10, weight: .bold))
                        .foregroundStyle(Theme.appMuted)
                        .padding(.top, 28)
                        .padding(.bottom, 12)

                    if store.events.isEmpty {
                        AppEmptyState(
                            icon: "calendar",
                            title: "No upcoming events",
                            message: "Check back soon for building events and socials."
                        )
                        .padding(.top, 30)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(store.events) { event in
                                NavigationLink {
                                    EventDetailView(event: event)
                                } label: {
                                    UpcomingEventCard(event: event)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 125)
            }
            .scrollIndicators(.hidden)
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct EventsHeader: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("EVENTS")
                .font(Theme.ui(10, weight: .bold))
                .foregroundStyle(Theme.appMuted)

            HStack {
                Text("24 Ashcroft Lane")
                    .font(Theme.display(28, weight: .bold))
                    .foregroundStyle(Theme.appNavy)

                Spacer()

                Button {
                    // Add Event screen can be connected later.
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))

                        Text("Add Event")
                            .font(Theme.ui(11, weight: .bold))
                    }
                    .foregroundStyle(Theme.appPurple)
                    .padding(.horizontal, 14)
                    .frame(height: 36)
                    .background(Theme.appPurpleSoft)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct EventMonthCalendar: View {

    private let calendar = Calendar.current
    private let displayDate = Date()

    private let weekdayNames = [
        "S", "M", "T", "W", "T", "F", "S"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            Text(monthYearText())
                .font(Theme.display(18, weight: .bold))
                .foregroundStyle(Theme.appNavy)

            HStack(spacing: 0) {
                ForEach(weekdayNames, id: \.self) { day in
                    Text(day)
                        .font(Theme.ui(10, weight: .bold))
                        .foregroundStyle(Theme.appMuted)
                        .frame(maxWidth: .infinity)
                }
            }

            let days = calendarCells()

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 7),
                spacing: 10
            ) {
                ForEach(0..<days.count, id: \.self) { index in
                    if let day = days[index] {
                        CalendarDay(day: day, isSelected: isToday(day))
                    } else {
                        Color.clear
                            .frame(height: 34)
                    }
                }
            }
        }
        .padding(18)
        .background(Theme.card.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(Theme.appBorder, lineWidth: 1)
        }
    }

    func monthYearText() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayDate)
    }

    func calendarCells() -> [Int?] {
        var cells: [Int?] = []

        let components = calendar.dateComponents([.year, .month], from: displayDate)

        guard let firstDay = calendar.date(from: components) else {
            return cells
        }

        let weekday = calendar.component(.weekday, from: firstDay)
        let emptyCells = weekday - 1

        if emptyCells > 0 {
            for _ in 0..<emptyCells {
                cells.append(nil)
            }
        }

        guard let range = calendar.range(of: .day, in: .month, for: displayDate) else {
            return cells
        }

        for day in range {
            cells.append(day)
        }

        return cells
    }

    func isToday(_ day: Int) -> Bool {
        let today = Date()

        let currentYear = calendar.component(.year, from: today)
        let currentMonth = calendar.component(.month, from: today)
        let currentDay = calendar.component(.day, from: today)

        let displayYear = calendar.component(.year, from: displayDate)
        let displayMonth = calendar.component(.month, from: displayDate)

        if currentYear == displayYear &&
            currentMonth == displayMonth &&
            currentDay == day {
            return true
        }

        return false
    }
}

private struct CalendarDay: View {

    let day: Int
    let isSelected: Bool

    var body: some View {
        Text("\(day)")
            .font(Theme.ui(12, weight: isSelected ? .bold : .regular))
            .foregroundStyle(isSelected ? .white : Theme.appNavy)
            .frame(width: 34, height: 34)
            .background(isSelected ? Theme.appPurple : Color.clear)
            .clipShape(Circle())
    }
}

private struct UpcomingEventCard: View {

    @EnvironmentObject var store: AppStore

    let event: BuildingEvent

    var body: some View {
        HStack(spacing: 14) {

            // Date block
            VStack(spacing: 2) {
                Text(monthText())
                    .font(Theme.ui(9, weight: .bold))
                    .foregroundStyle(Theme.appPurple)

                Text(dayText())
                    .font(Theme.display(22, weight: .bold))
                    .foregroundStyle(Theme.appNavy)
            }
            .frame(width: 54, height: 62)
            .background(Theme.appPurpleSoft)
            .clipShape(RoundedRectangle(cornerRadius: 15))

            // Event information
            VStack(alignment: .leading, spacing: 5) {
                Text(event.title)
                    .font(Theme.display(14, weight: .bold))
                    .foregroundStyle(Theme.appNavy)
                    .lineLimit(1)

                Text(eventInfoText())
                    .font(Theme.ui(10))
                    .foregroundStyle(Theme.appMuted)
                    .lineLimit(1)

                if event.attendeeCount > 0 {
                    Text("\(event.attendeeCount) going")
                        .font(Theme.ui(9, weight: .semibold))
                        .foregroundStyle(Theme.appMuted)
                }
            }

            Spacer(minLength: 4)

            // RSVP
            if event.allowsRSVP {
                Button {
                    store.toggleRSVP(for: event)
                } label: {
                    Text(event.isGoing ? "I'm Going" : "RSVP")
                        .font(Theme.ui(10, weight: .bold))
                        .foregroundStyle(event.isGoing ? Theme.appGreen : Theme.appPurple)
                        .padding(.horizontal, 12)
                        .frame(height: 30)
                        .background(
                            event.isGoing ? Theme.appGreenSoft : Theme.appPurpleSoft
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.borderless)
            } else {
                Text("Reminder")
                    .font(Theme.ui(10, weight: .bold))
                    .foregroundStyle(Theme.warning)
                    .padding(.horizontal, 12)
                    .frame(height: 30)
                    .background(Theme.warning.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Theme.card.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Theme.appBorder, lineWidth: 1)
        }
    }

    func monthText() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: event.date).uppercased()
    }

    func dayText() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: event.date)
    }

    func eventInfoText() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        let time = formatter.string(from: event.date)

        return "\(time) · \(event.location)"
    }
}

#Preview {
    NavigationStack {
        EventCalendarView()
            .environmentObject(AppStore())
    }
}
