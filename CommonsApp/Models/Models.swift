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
    case waitingRoom
    case profileSetup
    case active
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
    var name : String
    var detail: String
    var ownerName: String
    var ownerUnit: String
    var status: Status

    enum Status: String, Codable {
        case lending = "Lending"
        case needed  = "Needed"
    }
}

//Event structure

struct BuildingEvent: Identifiable, Codable, Equatable {
    var id           = UUID()
    var title: String
    var date: Date
    var location: String
    var allowsRSVP: Bool  = true
    var attendeeCount: Int = 0
    var isGoing: Bool = false
}

struct MaintenanceRequest: Identifiable, Codable, Equatable {
    var id = UUID()
    var title : String
    var details : String
    var unit : String
    var submittedAt : Date
    var stage: Stage = .submitted

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
}

//Chat Structure

struct ChatMessage: Identifiable, Codable, Equatable {
    var id        = UUID()
    var text: String
    var isMine: Bool
    var timestamp: Date
}

struct ChatThread: Identifiable, Codable, Equatable {
    var id            = UUID()
    var neighborName: String
    var neighborUnit: String
    var contextNote: String?
    var messages: [ChatMessage]

    var lastMessage: ChatMessage? { messages.last }
}

//Admin Structure

struct PendingResident: Identifiable, Codable, Equatable {
    var id          = UUID()
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
    




