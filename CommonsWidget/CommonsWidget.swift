//
//  CommonsWidget.swift
//  CommonsWidget
//
//  Created by Sohan Weerasinghe on 26/9/2026.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry
// This is one snapshot of data the widget displays

struct CommonsEntry: TimelineEntry {
    // WidgetKit requires a date for each entry
    let date: Date
    let announcement: String
    let nextEventTitle: String
    let nextEventLocation: String
}

// MARK: - Timeline Provider
// This tells WidgetKit what data to show and when to refresh

struct CommonsProvider: TimelineProvider {

    // Placeholder shown while widget loads
    func placeholder(in context: Context) -> CommonsEntry {
        CommonsEntry(
            date: Date(),
            announcement: "Water shut off Tuesday 10am",
            nextEventTitle: "Rooftop Social",
            nextEventLocation: "Rooftop Terrace"
        )
    }

    // Snapshot shown in widget gallery preview
    func getSnapshot(in context: Context,
                     completion: @escaping (CommonsEntry) -> Void) {
        completion(placeholder(in: context))
    }

    // Real timeline — called when widget needs to refresh
    func getTimeline(in context: Context,
                     completion: @escaping (Timeline<CommonsEntry>) -> Void) {

        // Read data saved by the main app
        let defaults = UserDefaults(suiteName: "group.com.yourname.commonsapp")

        let announcement = defaults?.string(forKey: "pinnedAnnouncement")
            ?? "No announcements"

        let eventTitle = defaults?.string(forKey: "nextEventTitle")
            ?? "No upcoming events"

        let eventLocation = defaults?.string(forKey: "nextEventLocation")
            ?? ""

        // Create one entry with the current data
        let entry = CommonsEntry(
            date: Date(),
            announcement: announcement,
            nextEventTitle: eventTitle,
            nextEventLocation: eventLocation
        )

        // Refresh the widget every 30 minutes
        let refreshDate = Calendar.current.date(
            byAdding: .minute,
            value: 30,
            to: Date()
        )!

        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }
}

// MARK: - Small Widget View

struct CommonsWidgetSmallView: View {

    let entry: CommonsEntry

    var body: some View {
        ZStack {
            // Dark navy background
            Color(red: 0.11, green: 0.14, blue: 0.20)

            VStack(alignment: .leading, spacing: 8) {

                // App name
                Text("Commons")
                    .font(.system(size: 13, weight: .semibold, design: .serif))
                    .foregroundStyle(Color(red: 0.74, green: 0.60, blue: 0.31))

                Spacer()

                // Announcement text
                Text(entry.announcement)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color(red: 0.95, green: 0.94, blue: 0.90))
                    .lineLimit(3)
            }
            .padding(14)
        }
    }
}

// MARK: - Medium Widget View

struct CommonsWidgetMediumView: View {

    let entry: CommonsEntry

    var body: some View {
        ZStack {
            Color(red: 0.11, green: 0.14, blue: 0.20)

            HStack(spacing: 0) {

                // Left side — announcement
                VStack(alignment: .leading, spacing: 6) {
                    Text("PINNED")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Color(red: 0.74, green: 0.60, blue: 0.31))

                    Text(entry.announcement)
                        .font(.system(size: 13))
                        .foregroundStyle(Color(red: 0.95, green: 0.94, blue: 0.90))
                        .lineLimit(3)

                    Spacer()

                    Text("Commons")
                        .font(.system(size: 11, weight: .semibold, design: .serif))
                        .foregroundStyle(Color(red: 0.74, green: 0.60, blue: 0.31))
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)

                // Divider
                Rectangle()
                    .fill(Color(red: 0.23, green: 0.27, blue: 0.37))
                    .frame(width: 1)

                // Right side — next event
                VStack(alignment: .leading, spacing: 6) {
                    Text("NEXT EVENT")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Color(red: 0.74, green: 0.60, blue: 0.31))

                    Text(entry.nextEventTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(red: 0.95, green: 0.94, blue: 0.90))
                        .lineLimit(2)

                    Text(entry.nextEventLocation)
                        .font(.system(size: 11))
                        .foregroundStyle(Color(red: 0.58, green: 0.64, blue: 0.71))
                        .lineLimit(1)

                    Spacer()
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - Widget Configuration

struct CommonsAppWidget: Widget {

    // This identifier must be unique
    let kind: String = "CommonsAppWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CommonsProvider()) { entry in
            // Show different layouts based on widget size
            GeometryReader { geo in
                if geo.size.width < 170 {
                    CommonsWidgetSmallView(entry: entry)
                } else {
                    CommonsWidgetMediumView(entry: entry)
                }
            }
        }
        .configurationDisplayName("Commons")
        .description("Building announcements and upcoming events")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    CommonsAppWidget()
} timeline: {
    CommonsEntry(
        date: Date(),
        announcement: "Water shut off Tuesday 10am–2pm",
        nextEventTitle: "Rooftop Social",
        nextEventLocation: "Rooftop Terrace"
    )
}
