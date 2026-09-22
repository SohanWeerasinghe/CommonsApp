//
//  AppStore.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 21/9/2026.
//

import Foundation
import SwiftUI
import Combine

final class AppStore: ObservableObject {
    //Onboarding
    @Published var onboardingStage: OnboardingStage = .signIn
    @Published var pendingEmail: String = ""
    @Published var currentResident = Resident(name: "", unit: "")
    
    //Feed
    @Published var posts: [Post] = []
    
    //Lend & Borrow
    @Published var items: [SharedItem] = []
    
    //Events
    @Published var events: [BuildingEvent] = []
    
    //Service Hub
    @Published var maintenanceRequests: [MaintenanceRequest] = []
    @Published var amenities: [Amenity] = []
    @Published var bookingSlots: [BookingSlot] = []
    
    //Chat
    @Published var chatThreads: [ChatThread] = []
    
    //Admin
    @Published var pendingResidents: [PendingResident] = []
    @Published var pinnedAnnouncementText: String = ""
    
    //Settings
    @Published var offlineCache: [OfflineCacheItem] = []
    @Published var appLockEnabled: Bool = false
    @Published var isLocked: Bool = false
    
    //Demo
    @Published var isManagerMode: Bool = false
    
    //Sample data loading
    
    init() {
        seedSampleData()
    }
    
    //Onboarding Actions
    
    func sendMagicLink() {
        onboardingStage = .waitingRoom
    }
    
    func simulateVerification() {
        onboardingStage = .profileSetup
    }
    
    func completeProfileSetup(name: String, unit: String, phone: String, preference: Resident.ContactPreference, showUnit: Bool) {
        // Create the resident with provided details
        currentResident = Resident(
            name: name,
            unit: unit,
            phone: phone,
            contactPreference: preference,
            showUnitToNeighbors: showUnit
        )
        
        // Move to active stage
        onboardingStage = .active
    }
    
    //Feed Actions
    
    func addPost(text: String, category: Post.Category, hasPhoto: Bool) {
        // Figure out the name to use (default to "You" if empty)
        var authorName = currentResident.name
        if authorName.isEmpty {
            authorName = "You"
        }
        
        let post = Post(
            authorName: authorName,
            authorUnit: currentResident.unit,
            timestamp: Date(),
            category: category,
            text: text,
            hasPhoto: hasPhoto
        )
        
        // Add the new post to the top of the list
        posts.insert(post, at: 0)
    }
    
    func toggleLike(post: Post) {
        // Find the matching post and add 1 like
        for index in 0..<posts.count {
            if posts[index].id == post.id {
                posts[index].likeCount += 1
                break
            }
        }
    }
    
    //Lend & Borrow
    
    func requestItem(item: SharedItem) -> ChatThread {
        // Check if we already have a chat with this neighbor
        for thread in chatThreads {
            if thread.neighborUnit == item.ownerUnit {
                return thread
            }
        }
        
        // If no existing chat, create a new one
        let thread = ChatThread(
            neighborName: item.ownerName,
            neighborUnit: item.ownerUnit,
            contextNote: "You requested \(item.name) from \(item.ownerName)",
            messages: []
        )
        
        chatThreads.insert(thread, at: 0)
        return thread
    }
    
    //Events
    
    func toggleRSVP(for event: BuildingEvent) {
        // Find the event in the list
        for index in 0..<events.count {
            if events[index].id == event.id {
                // Flip the going status (true becomes false, false becomes true)
                events[index].isGoing.toggle()
                
                // Adjust attendee count based on new status
                if events[index].isGoing {
                    events[index].attendeeCount += 1
                } else {
                    events[index].attendeeCount -= 1
                }
                break
            }
        }
    }
    
    //Service Hub Actions
    
    func submitMaintenanceRequest(title: String, details: String) {
        let request = MaintenanceRequest(
            title: title,
            details: details,
            unit: currentResident.unit,
            submittedAt: Date()
        )
        
        maintenanceRequests.insert(request, at: 0)
    }
    
    func advanceStage(of request: MaintenanceRequest) {
        
        // Find which position this request is in the array
        guard let index = maintenanceRequests.firstIndex(where: { $0.id == request.id }) else { return }
        
        // Move to the next stage using the correct stage names
        if maintenanceRequests[index].stage == .submitted {
            maintenanceRequests[index].stage = .assigned
        } else if maintenanceRequests[index].stage == .assigned {
            maintenanceRequests[index].stage = .onTheWay
        } else if maintenanceRequests[index].stage == .onTheWay {
            maintenanceRequests[index].stage = .complete
        }
        // If already complete we do nothing
    }
    
    func book(_ slot: BookingSlot) {
        // Find slot and mark as booked
        for index in 0..<bookingSlots.count {
            if bookingSlots[index].id == slot.id {
                bookingSlots[index].isBooked = true
                break
            }
        }
    }
    
    //Chat
    
    func send(text: String, in thread: ChatThread) {
        for index in 0..<chatThreads.count {
            if chatThreads[index].id == thread.id {
                let newMessage = ChatMessage(text: text, isMine: true, timestamp: Date())
                chatThreads[index].messages.append(newMessage)
                break
            }
        }
    }
    
    //Sample Data Setup
    
    private func seedSampleData() {
        let now = Date()
        
        //Create sample posts
        posts = [
            Post(
                authorName: "Management",
                authorUnit: "—",
                timestamp: now,
                category: .announcement,
                text: "Water shut off Tuesday 10am–2pm. Building-wide maintenance on the 3rd floor line.",
                isPinned: true
            ),
            Post(
                authorName: "Marcus Webb",
                authorUnit: "6C",
                timestamp: now,
                category: .askForHelp,
                text: "Anyone have a stud finder I could borrow this weekend? Hanging shelves in the nursery.",
                hasPhoto: true,
                likeCount: 4,
                replyCount: 12
            ),
            Post(
                authorName: "Jae Park",
                authorUnit: "2A",
                timestamp: now,
                category: .news,
                text: "Rooftop was gorgeous at sunset tonight. Highly recommend a visit!",
                hasPhoto: true,
                likeCount: 11,
                replyCount: 3
            )
        ]
        
        //Create sample items
        items = [
            SharedItem(name: "Power Drill", detail: "Cordless, with bits", ownerName: "Marcus Webb", ownerUnit: "6C", status: .lending),
            SharedItem(name: "Step Ladder", detail: "6 ft, aluminum", ownerName: "Jae Park", ownerUnit: "2A", status: .lending),
            SharedItem(name: "Stand Mixer", detail: "Need for weekend baking", ownerName: "Priya Nair", ownerUnit: "4B", status: .needed)
        ]
        
        //Create sample events
        events = [
            BuildingEvent(title: "Rooftop Sunset Social", date: now, location: "Rooftop Terrace", attendeeCount: 18, isGoing: true),
            BuildingEvent(title: "HOA Monthly Meeting", date: now, location: "Community Room", attendeeCount: 9)
        ]
        
        //Create sample maintenance request
        maintenanceRequests = [
            MaintenanceRequest(title: "Kitchen faucet leak", details: "Slow drip under the handle.", unit: "4B", submittedAt: now, stage: .onTheWay)
        ]
        
        //Create sample amenities
        amenities = [
            Amenity(name: "Gym", subtitle: "Open now"),
            Amenity(name: "Community Room", subtitle: "3 slots today"),
            Amenity(name: "Guest Suite", subtitle: "Book ahead")
        ]
        
        seedBookingSlots()
        
        //Create sample chat thread
        chatThreads = [
            ChatThread(
                neighborName: "Marcus Webb",
                neighborUnit: "6C",
                contextNote: "You requested Power Drill from Marcus",
                messages: [
                    ChatMessage(text: "Hey! Happy to lend it over.", isMine: false, timestamp: now),
                    ChatMessage(text: "Amazing, could I grab it this evening?", isMine: true, timestamp: now),
                    ChatMessage(text: "Sure — I'm around after 6. Knock on 6C.", isMine: false, timestamp: now)
                ]
            )
        ]
        
        //Create sample pending residents
        pendingResidents = [
            PendingResident(name: "Priya Nair", unit: "4B", requestedAt: now),
            PendingResident(name: "Tom Alcott", unit: "11D", requestedAt: now)
        ]
        
        pinnedAnnouncementText = "Water shut off Tuesday, 10am–2pm."
        
        //Create offline cache items
        offlineCache = [
            OfflineCacheItem(label: "Door entry codes", isCached: true, lastSynced: now),
            OfflineCacheItem(label: "Emergency contacts", isCached: true, lastSynced: now),
            OfflineCacheItem(label: "Building Wall feed", isCached: true, lastSynced: now),
            OfflineCacheItem(label: "Photos & attachments", isCached: false, lastSynced: nil)
        ]
    }
    
    private func seedBookingSlots() {
        // Check if we have amenities available
        if amenities.isEmpty { return }
        
        let communityRoom = amenities[0]
        let now = Date()
        
        // Create 10 sample booking slots using a loop
        bookingSlots = []
        for index in 0..<10 {
            // Mark slot as booked if it's index 2, 5, or 8
            let isSlotBooked = (index == 2 || index == 5 || index == 8)
            
            let slot = BookingSlot(
                amenityID: communityRoom.id,
                start: now,
                isBooked: isSlotBooked
            )
            bookingSlots.append(slot)
        }
    }
}

