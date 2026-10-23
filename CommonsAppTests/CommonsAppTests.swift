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
}
