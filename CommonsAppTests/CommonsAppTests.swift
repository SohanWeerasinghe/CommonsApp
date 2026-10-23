//
//  CommonsAppTests.swift
//  CommonsAppTests
//
//  Created by Sohan Weerasinghe on 23/10/2026.
//

import Foundation
import Testing
@testable import CommonsApp

struct CommonsAppTests {

    // MARK: - Maintenance

    @Test func maintenanceStageLabels() {
        #expect(MaintenanceRequest.Stage.submitted.label == "Submitted")
        #expect(MaintenanceRequest.Stage.assigned.label == "Assigned")
        #expect(MaintenanceRequest.Stage.onTheWay.label == "On the Way")
        #expect(MaintenanceRequest.Stage.complete.label == "Complete")
    }

    @Test func maintenanceStagesHaveCorrectOrder() {
        #expect(MaintenanceRequest.Stage.submitted.rawValue == 0)
        #expect(MaintenanceRequest.Stage.assigned.rawValue == 1)
        #expect(MaintenanceRequest.Stage.onTheWay.rawValue == 2)
        #expect(MaintenanceRequest.Stage.complete.rawValue == 3)
    }

    // MARK: - Borrowing

    @Test func borrowingHistoryStatuses() {
        #expect(BorrowRequest.Status.returned.isHistory)
        #expect(BorrowRequest.Status.declined.isHistory)
        #expect(BorrowRequest.Status.cancelled.isHistory)

        #expect(!BorrowRequest.Status.pending.isHistory)
        #expect(!BorrowRequest.Status.approved.isHistory)
        #expect(!BorrowRequest.Status.collected.isHistory)
    }

    @Test func borrowingStatusLabels() {
        #expect(BorrowRequest.Status.pending.label == "Pending")
        #expect(BorrowRequest.Status.approved.label == "Approved")
        #expect(BorrowRequest.Status.collected.label == "Collected")
        #expect(BorrowRequest.Status.returned.label == "Returned")
    }

    @Test func neededOfferIdentification() {
        let request = BorrowRequest(
            id: "request-1",
            itemId: "item-1",
            itemName: "Drill",
            ownerUID: "owner-1",
            borrowerUID: "borrower-1",
            requesterName: "Resident",
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400),
            note: "",
            status: .pending,
            createdAt: Date(),
            listingStatus: "Needed"
        )

        #expect(request.isNeededOffer)
    }

    // MARK: - Events

    @Test func cancelledEventIsNotCompleted() {
        let event = BuildingEvent(
            title: "Community Meeting",
            date: Date().addingTimeInterval(-86400),
            location: "Lobby",
            status: .cancelled
        )

        #expect(event.isCancelled)
        #expect(!event.isCompleted)
    }

    @Test func pastActiveEventIsCompleted() {
        let event = BuildingEvent(
            title: "Community Meeting",
            date: Date().addingTimeInterval(-86400),
            location: "Lobby"
        )

        #expect(!event.isCancelled)
        #expect(event.isCompleted)
    }

    @Test func futureEventIsNotCompleted() {
        let event = BuildingEvent(
            title: "Community Meeting",
            date: Date().addingTimeInterval(86400),
            location: "Lobby"
        )

        #expect(!event.isCompleted)
    }

    // MARK: - Residents

    @Test func residentDefaultPreferences() {
        let resident = Resident(
            name: "Test Resident",
            unit: "A101"
        )

        #expect(resident.contactPreference == .push)
        #expect(resident.showUnitToNeighbors)
        #expect(resident.phone.isEmpty)
    }

    // MARK: - Chat

    @Test func chatThreadReturnsLastMessage() {
        let first = ChatMessage(
            text: "Hello",
            isMine: true,
            timestamp: Date()
        )

        let second = ChatMessage(
            text: "Hi there",
            isMine: false,
            timestamp: Date()
        )

        let thread = ChatThread(
            neighborName: "Neighbor",
            neighborUnit: "B202",
            contextNote: nil,
            messages: [first, second]
        )

        #expect(thread.lastMessage?.id == second.id)
        #expect(thread.lastMessage?.text == "Hi there")
    }

    @Test func emptyChatHasNoLastMessage() {
        let thread = ChatThread(
            neighborName: "Neighbor",
            neighborUnit: "B202",
            contextNote: nil,
            messages: []
        )

        #expect(thread.lastMessage == nil)
    }

    // MARK: - Maintenance Validation

    @Test func validMaintenanceRequest() {
        #expect(MaintenanceValidation.validate(
            title: "Water leak",
            details: "Water leaking under the kitchen sink."
        ))
    }

    @Test func emptyMaintenanceTitle() {
        #expect(!MaintenanceValidation.validate(
            title: "",
            details: "Water leaking."
        ))
    }

    @Test func whitespaceOnlyMaintenanceTitle() {
        #expect(!MaintenanceValidation.validate(
            title: "   ",
            details: "Water leaking."
        ))
    }

    @Test func emptyMaintenanceDetails() {
        #expect(!MaintenanceValidation.validate(
            title: "Water leak",
            details: ""
        ))
    }

    @Test func whitespaceOnlyMaintenanceDetails() {
        #expect(!MaintenanceValidation.validate(
            title: "Water leak",
            details: "   "
        ))
    }

    @Test func maintenanceTitleAtMaximumLength() {
        #expect(MaintenanceValidation.validate(
            title: String(repeating: "A", count: 120),
            details: "Valid description"
        ))
    }

    @Test func maintenanceTitleExceedsMaximumLength() {
        #expect(!MaintenanceValidation.validate(
            title: String(repeating: "A", count: 121),
            details: "Valid description"
        ))
    }

    // MARK: - Maintenance Stage Transitions

    @Test func submittedRequestAdvancesToAssigned() {
        let next = MaintenanceValidation.nextStage(after: .submitted)

        #expect(next == .assigned)
    }

    @Test func assignedRequestAdvancesToOnTheWay() {
        let next = MaintenanceValidation.nextStage(after: .assigned)

        #expect(next == .onTheWay)
    }

    @Test func onTheWayRequestAdvancesToComplete() {
        let next = MaintenanceValidation.nextStage(after: .onTheWay)

        #expect(next == .complete)
    }

    @Test func completedRequestCannotAdvance() {
        let next = MaintenanceValidation.nextStage(after: .complete)

        #expect(next == nil)
    }

    @Test func maintenanceDetailsAtMaximumLength() {
        #expect(MaintenanceValidation.validate(
            title: "Water leak",
            details: String(repeating: "A", count: 2000)
        ))
    }

    @Test func maintenanceDetailsExceedMaximumLength() {
        #expect(!MaintenanceValidation.validate(
            title: "Water leak",
            details: String(repeating: "A", count: 2001)
        ))
    }


    // MARK: - Gym Booking Validation

    @Test func validGymBooking() {
        let result = GymBookingValidation.validate(
            members: ["resident1"],
            userID: "resident2",
            capacity: 5,
            cancel: false
        )

        #expect(result == nil)
    }

    @Test func duplicateGymBookingRejected() {
        let result = GymBookingValidation.validate(
            members: ["resident1"],
            userID: "resident1",
            capacity: 5,
            cancel: false
        )

        #expect(result == "You already booked this slot.")
    }

    @Test func fullGymSlotRejected() {
        let result = GymBookingValidation.validate(
            members: ["resident1", "resident2"],
            userID: "resident3",
            capacity: 2,
            cancel: false
        )

        #expect(result == "This Gym slot is full.")
    }

    @Test func gymBookingBelowCapacityAllowed() {
        let result = GymBookingValidation.validate(
            members: ["resident1", "resident2"],
            userID: "resident3",
            capacity: 3,
            cancel: false
        )

        #expect(result == nil)
    }

    @Test func validGymCancellation() {
        let result = GymBookingValidation.validate(
            members: ["resident1", "resident2"],
            userID: "resident1",
            capacity: 2,
            cancel: true
        )

        #expect(result == nil)
    }

    @Test func gymCancellationWithoutReservationRejected() {
        let result = GymBookingValidation.validate(
            members: ["resident1"],
            userID: "resident2",
            capacity: 5,
            cancel: true
        )

        #expect(result == "No reservation to cancel.")
    }

    @Test func gymBookingWithZeroCapacityRejected() {
        let result = GymBookingValidation.validate(
            members: [],
            userID: "resident1",
            capacity: 0,
            cancel: false
        )

        #expect(result == "This Gym slot is full.")
    }


    // MARK: - Event Validation

    @Test func validEventDetails() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)

        let result = EventValidation.validate(
            title: "Community Meeting",
            description: "Monthly meeting",
            location: "Lobby",
            start: now.addingTimeInterval(3600),
            end: now.addingTimeInterval(7200),
            now: now
        )

        #expect(result)
    }

    @Test func emptyEventTitleRejected() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)

        #expect(!EventValidation.validate(
            title: "   ",
            description: "",
            location: "Lobby",
            start: now.addingTimeInterval(3600),
            end: now.addingTimeInterval(7200),
            now: now
        ))
    }

    @Test func eventTitleLengthBoundary() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)

        let valid = EventValidation.validate(
            title: String(repeating: "A", count: 100),
            description: "",
            location: "Lobby",
            start: now.addingTimeInterval(3600),
            end: now.addingTimeInterval(7200),
            now: now
        )

        let invalid = EventValidation.validate(
            title: String(repeating: "A", count: 101),
            description: "",
            location: "Lobby",
            start: now.addingTimeInterval(3600),
            end: now.addingTimeInterval(7200),
            now: now
        )

        #expect(valid)
        #expect(!invalid)
    }

    @Test func emptyEventLocationRejected() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)

        #expect(!EventValidation.validate(
            title: "Community Meeting",
            description: "",
            location: "   ",
            start: now.addingTimeInterval(3600),
            end: now.addingTimeInterval(7200),
            now: now
        ))
    }

    @Test func eventLocationLengthBoundary() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)

        let valid = EventValidation.validate(
            title: "Meeting",
            description: "",
            location: String(repeating: "L", count: 200),
            start: now.addingTimeInterval(3600),
            end: now.addingTimeInterval(7200),
            now: now
        )

        let invalid = EventValidation.validate(
            title: "Meeting",
            description: "",
            location: String(repeating: "L", count: 201),
            start: now.addingTimeInterval(3600),
            end: now.addingTimeInterval(7200),
            now: now
        )

        #expect(valid)
        #expect(!invalid)
    }

    @Test func eventDescriptionLengthBoundary() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)

        let valid = EventValidation.validate(
            title: "Meeting",
            description: String(repeating: "D", count: 2000),
            location: "Lobby",
            start: now.addingTimeInterval(3600),
            end: now.addingTimeInterval(7200),
            now: now
        )

        let invalid = EventValidation.validate(
            title: "Meeting",
            description: String(repeating: "D", count: 2001),
            location: "Lobby",
            start: now.addingTimeInterval(3600),
            end: now.addingTimeInterval(7200),
            now: now
        )

        #expect(valid)
        #expect(!invalid)
    }

    @Test func pastEventStartRejected() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)

        #expect(!EventValidation.validate(
            title: "Meeting",
            description: "",
            location: "Lobby",
            start: now.addingTimeInterval(-3600),
            end: now.addingTimeInterval(7200),
            now: now
        ))
    }

    @Test func eventEndBeforeStartRejected() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)

        #expect(!EventValidation.validate(
            title: "Meeting",
            description: "",
            location: "Lobby",
            start: now.addingTimeInterval(7200),
            end: now.addingTimeInterval(3600),
            now: now
        ))
    }

    @Test func eventEndEqualToStartRejected() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)

        #expect(!EventValidation.validate(
            title: "Meeting",
            description: "",
            location: "Lobby",
            start: now.addingTimeInterval(3600),
            end: now.addingTimeInterval(3600),
            now: now
        ))
    }

    @Test func eventStartEqualToNowRejected() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)

        let result = EventValidation.validate(
            title: "Community Meeting",
            description: "",
            location: "Lobby",
            start: now,
            end: now.addingTimeInterval(3600),
            now: now
        )

        #expect(!result)
    }


}
