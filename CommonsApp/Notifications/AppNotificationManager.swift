//
//  AppNotificationManager.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 23/10/2026.
//

import Foundation
import UserNotifications

@MainActor
final class AppNotificationManager {

    static let shared = AppNotificationManager()

    private let center = UNUserNotificationCenter.current()

    private init() {}

    func send(
        id: String,
        title: String,
        body: String
    ) async {
        let settings = await center.notificationSettings()
        print("NOTIFICATION DEBUG: Authorization = \(settings.authorizationStatus.rawValue)")
        print("NOTIFICATION DEBUG: Alerts = \(settings.alertSetting.rawValue)")
        print("NOTIFICATION DEBUG: Sounds = \(settings.soundSetting.rawValue)")

        guard settings.authorizationStatus == .authorized ||
              settings.authorizationStatus == .provisional ||
              settings.authorizationStatus == .ephemeral else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 10,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            print("NOTIFICATION DEBUG: Scheduled = \(id)")

            let pending = await center.pendingNotificationRequests()
            print("NOTIFICATION DEBUG: Pending count = \(pending.count)")
        } catch {
            print("Notification failed: \(error.localizedDescription)")
        }
    }

    func scheduleReminder(
        id: String,
        title: String,
        body: String,
        date: Date
    ) async throws {
        guard date > Date() else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let interval = date.timeIntervalSinceNow

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: interval,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }

    func cancel(id: String) {
        center.removePendingNotificationRequests(
            withIdentifiers: [id]
        )
    }
}
