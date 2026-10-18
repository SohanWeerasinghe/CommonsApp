import SwiftUI

private enum EventStyle {
    static let purple = Color(red: 0.46, green: 0.40, blue: 0.96)
    static let navy = Color(red: 0.12, green: 0.17, blue: 0.28)
    static let muted = Color(red: 0.47, green: 0.51, blue: 0.60)
    static let bg = Color(red: 0.965, green: 0.965, blue: 0.985)
    static let lavender = Color(red: 0.93, green: 0.91, blue: 1.0)
}

struct EventCalendarView: View {
    @EnvironmentObject private var store: AppStore
    @State private var displayedMonth = Calendar.current.startOfDay(for: Date())
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var showCreateEvent = false
    private let calendar = Calendar.current

    private var selectedEvents: [BuildingEvent] {
        store.events.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
            .sorted { $0.date < $1.date }
    }
    private var upcomingEvents: [BuildingEvent] {
        store.events.filter { !$0.isCancelled && $0.date >= calendar.startOfDay(for: Date()) }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        ZStack {
            EventStyle.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    introduction
                    calendarCard
                    daySection
                    upcomingSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 130)
            }
            .scrollIndicators(.hidden)
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showCreateEvent) {
            NavigationStack { CommunityEventEditor(existing: nil) }
                .environmentObject(store)
        }
        .preferredColorScheme(.light)
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 7) {
                Text("24 ASHCROFT LANE")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.5).foregroundStyle(EventStyle.muted)
                Text("Community events")
                    .font(.system(size: 29, weight: .bold, design: .rounded))
                    .foregroundStyle(EventStyle.navy)
            }
            Spacer(minLength: 6)
            if store.onboardingStage == .admin {
                Button { showCreateEvent = true } label: {
                    Label("Create", systemImage: "plus.circle.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(EventStyle.purple)
                }
                .accessibilityLabel("Create event")
            }
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(EventStyle.purple)
                .frame(width: 52, height: 52)
                .background(EventStyle.lavender, in: RoundedRectangle(cornerRadius: 17))
                .accessibilityLabel("Community calendar")
        }
    }

    private var introduction: some View {
        HStack(spacing: 14) {
            Image(systemName: "sparkles")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(EventStyle.purple)
                .frame(width: 48, height: 48)
                .background(.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 15))
            VStack(alignment: .leading, spacing: 4) {
                Text("Good things happen together")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(EventStyle.navy)
                Text("Discover what's happening in your building.")
                    .font(.system(size: 12))
                    .foregroundStyle(EventStyle.muted)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(EventStyle.lavender.opacity(0.75), in: RoundedRectangle(cornerRadius: 22))
    }

    private var calendarCard: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("EXPLORE DATES")
                        .font(.system(size: 10, weight: .bold)).tracking(1.4)
                        .foregroundStyle(EventStyle.muted)
                    Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                        .font(.system(size: 21, weight: .bold, design: .rounded))
                        .foregroundStyle(EventStyle.navy)
                }
                Spacer()
                monthButton("chevron.left", offset: -1)
                monthButton("chevron.right", offset: 1)
            }
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { index in
                    Text(["S", "M", "T", "W", "T", "F", "S"][index])
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(EventStyle.muted)
                        .frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 7), spacing: 8) {
                ForEach(Array(monthCells.enumerated()), id: \.offset) { _, date in
                    if let date {
                        dayButton(date)
                    } else {
                        Color.clear.frame(height: 47)
                    }
                }
            }
            HStack(spacing: 7) {
                Circle().fill(EventStyle.purple).frame(width: 7, height: 7)
                Text("Event scheduled")
                Spacer()
                Button("Today") {
                    let today = calendar.startOfDay(for: Date())
                    displayedMonth = today
                    selectedDate = today
                }
                .fontWeight(.semibold)
                .foregroundStyle(EventStyle.purple)
            }
            .font(.system(size: 11))
            .foregroundStyle(EventStyle.muted)
        }
        .padding(19)
        .background(.white, in: RoundedRectangle(cornerRadius: 26))
        .overlay(RoundedRectangle(cornerRadius: 26).stroke(EventStyle.navy.opacity(0.07)))
    }

    private func monthButton(_ icon: String, offset: Int) -> some View {
        Button {
            guard let newMonth = calendar.date(byAdding: .month, value: offset, to: displayedMonth) else { return }
            displayedMonth = newMonth
        } label: {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(EventStyle.navy)
                .frame(width: 34, height: 34)
                .background(EventStyle.bg, in: RoundedRectangle(cornerRadius: 11))
        }
        .buttonStyle(.plain)
    }

    private var monthCells: [Date?] {
        let parts = calendar.dateComponents([.year, .month], from: displayedMonth)
        guard let first = calendar.date(from: parts),
              let days = calendar.range(of: .day, in: .month, for: first) else { return [] }
        let offset = (calendar.component(.weekday, from: first) - calendar.firstWeekday + 7) % 7
        let leading = Array<Date?>(repeating: nil, count: offset)
        let dates = days.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: first) }
        return leading + dates.map { Optional($0) }
    }

    private func dayButton(_ date: Date) -> some View {
        let selected = calendar.isDate(date, inSameDayAs: selectedDate)
        let hasEvent = store.events.contains { !$0.isCancelled && calendar.isDate($0.date, inSameDayAs: date) }
        let today = calendar.isDateInToday(date)
        return Button { selectedDate = date } label: {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 13, weight: selected || today ? .bold : .medium))
                Circle().fill(selected ? Color.white : EventStyle.purple)
                    .frame(width: 5, height: 5)
                    .opacity(hasEvent ? 1 : 0)
            }
            .foregroundStyle(selected ? .white : EventStyle.navy)
            .frame(maxWidth: .infinity)
            .frame(height: 47)
            .background(selected ? EventStyle.purple : (today ? EventStyle.lavender : Color.clear),
                        in: RoundedRectangle(cornerRadius: 13))
        }
        .buttonStyle(.plain)
    }

    private var daySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SELECTED DAY")
                        .font(.system(size: 10, weight: .bold)).tracking(1.3)
                        .foregroundStyle(EventStyle.muted)
                    Text(selectedDate.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(EventStyle.navy)
                }
                Spacer()
                Text("\(selectedEvents.count) event\(selectedEvents.count == 1 ? "" : "s")")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(EventStyle.purple)
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(EventStyle.lavender, in: Capsule())
            }
            if selectedEvents.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .font(.title3).foregroundStyle(EventStyle.purple)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Nothing planned for this day")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(EventStyle.navy)
                        Text("Select another date or browse upcoming events.")
                            .font(.system(size: 12)).foregroundStyle(EventStyle.muted)
                    }
                    Spacer(minLength: 0)
                }
                .padding(18)
                .background(.white, in: RoundedRectangle(cornerRadius: 20))
            } else {
                ForEach(selectedEvents) { event in
                    NavigationLink { EventDetailView(event: event) } label: {
                        EventRedesignedCard(event: event)
                    }.buttonStyle(.plain)
                }
            }
        }
    }

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Coming up")
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundStyle(EventStyle.navy)
                Spacer()
                Text("\(upcomingEvents.count) total")
                    .font(.system(size: 12)).foregroundStyle(EventStyle.muted)
            }
            if upcomingEvents.isEmpty {
                Text("No upcoming events yet.")
                    .font(.subheadline).foregroundStyle(EventStyle.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(.white, in: RoundedRectangle(cornerRadius: 20))
            } else {
                ForEach(upcomingEvents) { event in
                    NavigationLink { EventDetailView(event: event) } label: {
                        EventRedesignedCard(event: event)
                    }.buttonStyle(.plain)
                }
            }
        }
    }
}

private struct EventRedesignedCard: View {
    @EnvironmentObject private var store: AppStore
    let event: BuildingEvent

    var body: some View {
        HStack(spacing: 13) {
            VStack(spacing: 2) {
                Text(event.date.formatted(.dateTime.month(.abbreviated)).uppercased())
                    .font(.system(size: 10, weight: .bold)).foregroundStyle(EventStyle.purple)
                Text(event.date.formatted(.dateTime.day()))
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .foregroundStyle(EventStyle.navy)
            }
            .frame(width: 62, height: 72)
            .background(EventStyle.lavender, in: RoundedRectangle(cornerRadius: 17))
            VStack(alignment: .leading, spacing: 6) {
                Text(event.title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(EventStyle.navy)
                    .lineLimit(2)
                Label(event.date.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                Label(event.location, systemImage: "mappin")
                if event.attendeeCount > 0 {
                    Label("\(event.attendeeCount) attending", systemImage: "person.2")
                }
            }
            .font(.system(size: 11))
            .foregroundStyle(EventStyle.muted)
            Spacer(minLength: 0)
            VStack(spacing: 10) {
                if event.isCancelled {
                    Text("CANCELLED")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.red)
                        .padding(.horizontal, 10).padding(.vertical, 7)
                        .background(Color.red.opacity(0.09), in: Capsule())
                }
                if event.allowsRSVP &&
                   !event.isCancelled &&
                   event.date > Date() {
                    Button { store.toggleRSVP(for: event) } label: {
                        Text(event.isGoing ? "Going" : "RSVP")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(event.isGoing ? Color(red: 0.13, green: 0.55, blue: 0.42) : EventStyle.purple)
                            .padding(.horizontal, 12).padding(.vertical, 9)
                            .background(event.isGoing ? Color(red: 0.87, green: 0.97, blue: 0.93) : EventStyle.lavender, in: Capsule())
                    }.buttonStyle(.borderless)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(EventStyle.muted)
            }
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(EventStyle.navy.opacity(0.07)))
    }
}

#Preview {
    NavigationStack { EventCalendarView().environmentObject(AppStore()) }
}


// Administrator event creation and editing.
