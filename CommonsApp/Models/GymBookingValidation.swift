//
//  GymBookingValidation.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 23/10/2026.
//


import Foundation

struct GymBookingValidation {

    static func validate(
        members: [String],
        userID: String,
        capacity: Int,
        cancel: Bool
    ) -> String? {

        if cancel {
            if !members.contains(userID) {
                return "No reservation to cancel."
            }

            return nil
        }

        if members.contains(userID) {
            return "You already booked this slot."
        }

        if members.count >= capacity {
            return "This Gym slot is full."
        }

        return nil
    }
}
