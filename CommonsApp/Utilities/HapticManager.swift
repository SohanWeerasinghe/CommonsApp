//
//  HapticManager.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 23/10/2026.
//
import UIKit

@MainActor
enum HapticManager {

    static func success() {
        UINotificationFeedbackGenerator()
            .notificationOccurred(.success)
    }

    static func error() {
        UINotificationFeedbackGenerator()
            .notificationOccurred(.error)
    }
}
