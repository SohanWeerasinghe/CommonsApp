//
//  Models.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 21/9/2026.
//

import Foundation
struct Resident: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var unit: String
    var phone: String = ""
    var contactPreference: ContactPreference = .push
    var showUnitToNeighbors: Bool = true
    enum ContactPreference: String, Codable, CaseIterable {
        case push = "Push"
        case email = "Email"
        case text = "Text"
    }
}
enum OnboardingStage {
    case signIn, profileSetup, waitingRoom, pendingApproval, accessDeclined, active, admin, loading
}
struct Post: Identifiable, Codable, Equatable {
    var id = UUID()
    var authorName: String
    var authorUnit: String
    var timestamp: Date
    var category: Category
    var text: String
    var hasPhoto: Bool = false
    var likeCount: Int = 0
    var replyCount: Int = 0
    var isPinned: Bool = false
    var photoId: String? = nil
    enum Category: String, Codable, CaseIterable {
        case announcement = "Announcement"
        case askForHelp = "Ask for Help"
        case news = "News"
    }
}
struct SharedItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var detail: String
    var ownerName: String
    var ownerUnit: String
    var status: Status
    var ownerUID: String? = nil
    var availability: String = "Available now"
    var firestoreId: String? = nil
    var photoId: String? = nil
    enum Status: String, Codable {
        case lending = "Lending"
        case needed = "Needed"
    }
}
struct BorrowRequest: Identifiable, Equatable {
    var id: String
    var itemId: String
    var itemName: String
    var ownerUID: String
    var borrowerUID: String
    var requesterName: String
    var startDate: Date
    var endDate: Date
    var note: String
    var status: Status
    var createdAt: Date
    var listingStatus: String = "Lending"
    var isNeededOffer: Bool { listingStatus == "Needed" }
    enum Status: String {
        case pending, approved, collected, returned, declined, cancelled
        var label: String { rawValue.capitalized }
        var isHistory: Bool { [.returned, .declined, .cancelled].contains(self) }
    }
}
struct BuildingEvent: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var date: Date
    var location: String
    var allowsRSVP: Bool = true
    var attendeeCount: Int = 0
    var isGoing: Bool = false
    var description: String = ""
    var endDate: Date? = nil
    var status: Status = .active
    var createdBy: String = ""
    var firestoreId: String? = nil
    var coverId: String? = nil
    enum Status: String, Codable {
        case active, cancelled
    }
    var isCancelled: Bool { status == .cancelled }
    var isCompleted: Bool {
        if isCancelled { return false }
        return date <= Date()
    }
}
struct MaintenanceRequest: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var details: String
    var unit: String
    var submittedAt: Date
    var stage: Stage = .submitted
    var residentId: String = ""
    var photoPath: String? = nil
    enum Stage: Int, Codable, CaseIterable {
        case submitted, assigned, onTheWay, complete
        var label: String {
            switch self {
            case .submitted: return "Submitted"
            case .assigned: return "Assigned"
            case .onTheWay: return "On the Way"
            case .complete: return "Complete"
            }
        }
    }
}
struct Amenity: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var subtitle: String
}
struct BookingSlot: Identifiable, Codable, Equatable {
    var id = UUID()
    var amenityID: UUID
    var start: Date
    var isBooked: Bool = false
    var firestoreId: String? = nil
}
struct ChatMessage: Identifiable, Codable, Equatable {
    var id = UUID()
    var text: String
    var isMine: Bool
    var timestamp: Date
    var firestoreId: String? = nil
}
struct ChatThread: Identifiable, Codable, Equatable {
    var id = UUID()
    var neighborName: String
    var neighborUnit: String
    var contextNote: String?
    var messages: [ChatMessage]
    var firestoreId: String? = nil
    var neighborUID: String? = nil
    var lastMessage: ChatMessage? { messages.last }
}
struct PendingResident: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var unit: String
    var requestedAt: Date
}
struct OfflineCacheItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var label: String
    var isCached: Bool
    var lastSynced: Date?
}
