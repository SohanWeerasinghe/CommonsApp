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
}
