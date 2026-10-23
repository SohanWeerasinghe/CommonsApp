//
//  MaintenanceValidation.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 23/10/2026.
//

import Foundation

struct MaintenanceValidation {

    static func validate(title: String, details: String) -> Bool {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanDetails = details.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanTitle.isEmpty {
            return false
        }

        if cleanTitle.count > 120 {
            return false
        }

        if cleanDetails.isEmpty {
            return false
        }

        if cleanDetails.count > 2000 {
            return false
        }

        return true
    }
}
