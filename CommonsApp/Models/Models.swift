//
//  Models.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 21/9/2026.
//

import Foundation

//Residents data struct

struct Resident: Identifiable, Codable, Equatable {
    var id = UUID()
    var name : String
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

//Onboarding of residents

enum OnboardingStage {
    case signIn
    case profileSetup
    case waitingRoom
    case pendingApproval
    case accessDeclined
    case active
    case admin
    case loading
}

//Post in the building wall

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
    
    enum Category: String, Codable, CaseIterable {
        case announcement = "Announcement"
        case askForHelp   = "Ask for Help"
        case news         = "News"
    }
}

//Lend & Borrow

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
    // Backwards-compatible: old borrowing documents omit listingStatus.
    var listingStatus: String = "Lending"
    var isNeededOffer: Bool { listingStatus == "Needed" }
    enum Status: String {
        case pending, approved, collected, returned, declined, cancelled
        var label: String { rawValue.capitalized }
        var isHistory: Bool { [.returned, .declined, .cancelled].contains(self) }
    }
}

//Event structure


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

    enum Status: String, Codable {
        case active
        case cancelled
    }

    var isCancelled: Bool {
        status == .cancelled
    }
    
    var isCompleted: Bool {
        if isCancelled {
            return false
        }

        return date <= Date()
    }
}


struct MaintenanceRequest: Identifiable, Codable, Equatable {
    var id = UUID()
    var title : String
    var details : String
    var unit : String
    var submittedAt : Date
    var stage: Stage = .submitted
    var residentId: String = ""
    var photoPath: String? = nil

    enum Stage: Int, Codable, CaseIterable {
        case submitted, assigned, onTheWay, complete

        var label: String {
            switch self {
            case .submitted: return "Submitted"
            case .assigned:  return "Assigned"
            case .onTheWay:  return "On the Way"
            case .complete:  return "Complete"
            }
        }
    }
}
struct Amenity: Identifiable, Codable, Equatable {
    var id       = UUID()
    var name: String
    var subtitle: String
}

struct BookingSlot: Identifiable, Codable, Equatable {
    var id        = UUID()
    var amenityID: UUID
    var start: Date
    var isBooked: Bool = false
    var firestoreId: String? = nil
}

//Chat Structure

struct ChatMessage: Identifiable, Codable, Equatable {
    var id = UUID()
    var text: String
    var isMine: Bool
    var timestamp: Date

    // Firestore message document identifier
    var firestoreId: String? = nil
}

struct ChatThread: Identifiable, Codable, Equatable {
    var id = UUID()
    var neighborName: String
    var neighborUnit: String
    var contextNote: String?
    var messages: [ChatMessage]

    // Firestore conversation document identifier
    var firestoreId: String? = nil

    // Firebase UID of the other participant
    var neighborUID: String? = nil

    var lastMessage: ChatMessage? { messages.last }
}
//Admin Structure

struct PendingResident: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var unit: String
    var requestedAt: Date
}

//Settings Structure

struct OfflineCacheItem: Identifiable, Codable, Equatable {
    var id        = UUID()
    var label: String
    var isCached: Bool
    var lastSynced: Date?
}
    




