//
//  EventValidation.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 23/10/2026.
//


import Foundation

struct EventValidation {

    static func validate(
        title: String,
        description: String,
        location: String,
        start: Date,
        end: Date,
        now: Date = Date()
    ) -> Bool {

        let cleanTitle = title.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let cleanDescription = description.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let cleanLocation = location.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if cleanTitle.isEmpty {
            return false
        }

        if cleanTitle.count > 100 {
            return false
        }

        if cleanDescription.count > 2000 {
            return false
        }

        if cleanLocation.isEmpty {
            return false
        }

        if cleanLocation.count > 200 {
            return false
        }

        if start <= now {
            return false
        }

        if end <= start {
            return false
        }

        return true
    }

    static func canRSVP(
        event: BuildingEvent,
        now: Date = Date()
    ) -> Bool {

        if event.firestoreId == nil || event.firestoreId == "" {
            return false
        }

        if !event.allowsRSVP {
            return false
        }

        if event.isCancelled {
            return false
        }

        if event.date <= now {
            return false
        }

        return true
    }

    static func canEdit(event: BuildingEvent) -> Bool {

        guard let id = event.firestoreId, !id.isEmpty else {
            return false
        }

        return !event.isCancelled
    }

    static func canCancel(event: BuildingEvent) -> Bool {

        guard let id = event.firestoreId, !id.isEmpty else {
            return false
        }

        return !event.isCancelled
    }

}
