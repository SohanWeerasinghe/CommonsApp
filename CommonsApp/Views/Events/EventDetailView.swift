//
//  EventDetailView.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 26/9/2026.
//

import SwiftUI

struct EventDetailView: View {

    @EnvironmentObject var store: AppStore
    let event: BuildingEvent

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

                    // Location label
                    Text(event.location.uppercased())
                        .font(Theme.ui(10, weight: .bold))
                        .foregroundStyle(Theme.appMuted)
                        .padding(.top, 12)

                    // Event image placeholder
                    EventImagePlaceholder()
                        .frame(height: 210)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .padding(.top, 12)

                    // Event title
                    Text(event.title)
                        .font(Theme.display(28, weight: .bold))
                        .foregroundStyle(Theme.appNavy)
                        .padding(.top, 22)

                    // Date and location
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 9) {
                            Image(systemName: "calendar")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Theme.appPurple)

                            Text(dateAndTimeText())
                                .font(Theme.ui(13, weight: .medium))
                                .foregroundStyle(Theme.appNavy)
                        }

                        HStack(spacing: 9) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Theme.appPurple)

                            Text(event.location)
                                .font(Theme.ui(13, weight: .medium))
                                .foregroundStyle(Theme.appNavy)
                        }
                    }
                    .padding(.top, 16)

                    Divider()
                        .padding(.vertical, 22)

                    // Attendees
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(event.attendeeCount) GOING")
                                .font(Theme.ui(10, weight: .bold))
                                .foregroundStyle(Theme.appMuted)

                            AttendeeAvatars(count: event.attendeeCount)
                        }

                        Spacer()
                    }

                    // RSVP button
                    if event.allowsRSVP {
                        Button {
                            store.toggleRSVP(for: event)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: event.isGoing ? "checkmark" : "person.badge.plus")
                                    .font(.system(size: 14, weight: .bold))

                                if event.isGoing {
                                    Text("I'm Going · \(event.attendeeCount) attending")
                                } else {
                                    Text("RSVP · \(event.attendeeCount) attending")
                                }
                            }
                            .font(Theme.ui(14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Theme.appPurple)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 24)
                    }

                    // Add to Calendar
                    Button {
                        // Calendar export can be connected later.
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Theme.appPurpleSoft)
                                    .frame(width: 42, height: 42)

                                Image(systemName: "calendar.badge.plus")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Theme.appPurple)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text("Add to Calendar")
                                    .font(Theme.ui(14, weight: .bold))
                                    .foregroundStyle(Theme.appNavy)

                                Text("Export to iOS Calendar")
                                    .font(Theme.ui(11))
                                    .foregroundStyle(Theme.appMuted)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Theme.appMuted)
                        }
                        .padding(.horizontal, 14)
                        .frame(height: 70)
                        .background(Theme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Theme.appBorder, lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 14)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Event")
        .navigationBarTitleDisplayMode(.inline)
    }

    func dateAndTimeText() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d · h:mm a"
        return formatter.string(from: event.date)
    }
}

private struct EventImagePlaceholder: View {

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Theme.appPurple.opacity(0.18),
                    Theme.info.opacity(0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 10) {
                Image(systemName: "sun.horizon.fill")
                    .font(.system(size: 46, weight: .medium))
                    .foregroundStyle(Theme.appPurple)

                Text("EVENT")
                    .font(Theme.ui(9, weight: .bold))
                    .foregroundStyle(Theme.appMuted)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct AttendeeAvatars: View {

    let count: Int

    var body: some View {
        HStack(spacing: -8) {
            UnitBadge(unit: "6C", size: 34)
            UnitBadge(unit: "2A", size: 34)
            UnitBadge(unit: "9F", size: 34)

            if count > 3 {
                Text("+\(count - 3)")
                    .font(Theme.ui(10, weight: .bold))
                    .foregroundStyle(Theme.appNavy)
                    .frame(width: 34, height: 34)
                    .background(Theme.appPurpleSoft)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(Theme.card, lineWidth: 2)
                    }
            }
        }
    }
}

#Preview {
    NavigationStack {
        EventDetailView(
            event: BuildingEvent(
                title: "Rooftop Sunset Social",
                date: Date(),
                location: "Rooftop Terrace",
                attendeeCount: 18,
                isGoing: true
            )
        )
        .environmentObject(AppStore())
    }
}
