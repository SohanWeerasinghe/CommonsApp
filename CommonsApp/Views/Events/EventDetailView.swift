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
    @State private var showEditEvent = false
    @State private var showCancelConfirmation = false
    @State private var adminError: String?

    private var currentEvent: BuildingEvent {
        guard let firestoreId = event.firestoreId else {
            return event
        }

        return store.events.first {
            $0.firestoreId == firestoreId
        } ?? event
    }

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
                    Text(currentEvent.location.uppercased())
                        .font(Theme.ui(10, weight: .bold))
                        .foregroundStyle(Theme.appMuted)
                        .padding(.top, 12)

                    // Event image placeholder
                    EventImagePlaceholder()
                        .frame(height: 210)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .padding(.top, 12)

                    // Event title
                    Text(currentEvent.title)
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

                            Text(currentEvent.location)
                                .font(Theme.ui(13, weight: .medium))
                                .foregroundStyle(Theme.appNavy)
                        }
                    }
                    .padding(.top, 16)

                    Divider()
                        .padding(.vertical, 22)

                    if !currentEvent.description.isEmpty {
                        Text(currentEvent.description)
                            .font(Theme.ui(14))
                            .foregroundStyle(Theme.appNavy)
                            .padding(.bottom, 18)
                    }

                    // Attendees
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(currentEvent.attendeeCount) GOING")
                                .font(Theme.ui(10, weight: .bold))
                                .foregroundStyle(Theme.appMuted)

                            Label(
                                "\(currentEvent.attendeeCount) resident\(currentEvent.attendeeCount == 1 ? "" : "s") attending",
                                systemImage: "person.2.fill"
                            )
                            .font(Theme.ui(13, weight: .medium))
                            .foregroundStyle(Theme.appPurple)
                        }

                        Spacer()
                    }

                    // RSVP button
                    if currentEvent.allowsRSVP &&
                       !currentEvent.isCancelled &&
                       currentEvent.date > Date() {
                        Button {
                            store.toggleRSVP(for: currentEvent)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: currentEvent.isGoing ? "checkmark" : "person.badge.plus")
                                    .font(.system(size: 14, weight: .bold))

                                if currentEvent.isGoing {
                                    Text("I'm Going · \(currentEvent.attendeeCount) attending")
                                } else {
                                    Text("RSVP · \(currentEvent.attendeeCount) attending")
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

                    if currentEvent.isCancelled {
                        Label("Event cancelled", systemImage: "xmark.circle.fill")
                            .foregroundStyle(.red)
                            .padding(.top, 20)
                    }
                    if store.onboardingStage == .admin && !currentEvent.isCancelled {
                        HStack(spacing: 16) {
                            Button("Edit Event") { showEditEvent = true }
                            Button("Cancel Event", role: .destructive) {
                                showCancelConfirmation = true
                            }
                        }
                        .padding(.top, 20)
                    }
                    if let adminError {
                        Text(adminError).foregroundStyle(.red)
                            .font(.footnote).padding(.top, 8)
                    }
                    if let eventsError = store.eventsError {
                        Text(eventsError).foregroundStyle(.red)
                            .font(.footnote).padding(.top, 8)
                    }

                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Event")
        .sheet(isPresented: $showEditEvent) {
            NavigationStack { CommunityEventEditor(existing: currentEvent) }
                .environmentObject(store)
        }
        .confirmationDialog("Cancel this event?", isPresented: $showCancelConfirmation) {
            Button("Cancel Event", role: .destructive) {
                Task { @MainActor in
                    do { try await store.cancelCommunityEvent(currentEvent) }
                    catch { adminError = error.localizedDescription }
                }
            }
        } message: {
            Text("Residents will see this event as cancelled. This cannot be undone.")
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    func dateAndTimeText() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d · h:mm a"
        return formatter.string(from: currentEvent.date)
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
