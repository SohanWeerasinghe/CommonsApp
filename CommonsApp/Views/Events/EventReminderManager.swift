//
//  EventReminderManager.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 22/10/2026.
//


import Foundation
import Combine
import UserNotifications

@MainActor
final class EventReminderManager: ObservableObject {

    static let shared = EventReminderManager()

    @Published private(set) var reminderEventIds: Set<String> = []

    private let storageKey = "commonsEventReminderIds"
    private let notificationCenter = UNUserNotificationCenter.current()

    private init() {
        let savedIds = UserDefaults.standard.stringArray(forKey: storageKey) ?? []
        reminderEventIds = Set(savedIds)
    }

    func hasReminder(for event: BuildingEvent) -> Bool {
        guard let eventId = event.firestoreId else {
            return false
        }

        return reminderEventIds.contains(eventId)
    }

    func enableReminder(for event: BuildingEvent) async throws {
        guard let eventId = event.firestoreId,
              !eventId.isEmpty,
              !event.isCancelled else {
            throw ReminderError.invalidEvent
        }

        let reminderDate = event.date.addingTimeInterval(-30 * 60)

        guard reminderDate > Date() else {
            throw ReminderError.tooLate
        }

        let settings = await notificationCenter.notificationSettings()

        if settings.authorizationStatus == .notDetermined {
            let allowed = try await notificationCenter.requestAuthorization(
                options: [.alert, .badge, .sound]
            )

            if !allowed {
                throw ReminderError.permissionDenied
            }
        } else if settings.authorizationStatus != .authorized &&
                  settings.authorizationStatus != .provisional &&
                  settings.authorizationStatus != .ephemeral {
            throw ReminderError.permissionDenied
        }

        let content = UNMutableNotificationContent()
        content.title = "Upcoming Community Event"
        content.body = "\(event.title) starts in 30 minutes at \(event.location)."
        content.sound = .default
        content.userInfo = ["eventId": eventId]

        let interval = reminderDate.timeIntervalSinceNow

        guard interval > 0 else {
            throw ReminderError.tooLate
        }

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: interval,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: notificationId(for: eventId),
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)

        reminderEventIds.insert(eventId)
        saveReminders()
    }

    func disableReminder(for event: BuildingEvent) {
        guard let eventId = event.firestoreId else {
            return
        }

        removeReminder(eventId: eventId)
    }

    func synchronize(with events: [BuildingEvent]) async {
        let eventLookup = Dictionary(
            uniqueKeysWithValues: events.compactMap { event -> (String, BuildingEvent)? in
                guard let id = event.firestoreId else {
                    return nil
                }
                return (id, event)
            }
        )

        let savedIds = reminderEventIds

        for eventId in savedIds {
            guard let event = eventLookup[eventId],
                  !event.isCancelled,
                  event.date.addingTimeInterval(-30 * 60) > Date() else {
                removeReminder(eventId: eventId)
                continue
            }

            do {
                try await enableReminder(for: event)
            } catch {
                // Keep the saved preference if notification permissions
                // or scheduling temporarily fail.
                print("Could not update event reminder: \(error.localizedDescription)")
            }
        }
    }

    private func removeReminder(eventId: String) {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [notificationId(for: eventId)]
        )

        reminderEventIds.remove(eventId)
        saveReminders()
    }

    private func notificationId(for eventId: String) -> String {
        "commons-event-\(eventId)"
    }

    private func saveReminders() {
        UserDefaults.standard.set(
            Array(reminderEventIds),
            forKey: storageKey
        )
    }
}

enum ReminderError: LocalizedError {
    case invalidEvent
    case tooLate
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .invalidEvent:
            return "This event is unavailable."

        case .tooLate:
            return "Reminders must be enabled at least 30 minutes before the event."

        case .permissionDenied:
            return "Enable notifications in iPhone Settings to receive reminders."
        }
    }
}
