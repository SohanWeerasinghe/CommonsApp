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
    
    func sendMagicLink(){
        onboardingStage = .waitingRoom
    }
    
    func simulateVerification() {
        onboardingStage = .profileSetup
    }
    
    func completeProfileSetup(name:String, unit:String, phone:String, preference: Resident.ContactPreference,
                              showUnit: Bool) {
        currentResident = Resident(
                name: name,
                unit: unit,
                phone: phone,
                contactPreference: preference,
                showUnitToNeighbors: showUnit
            )
            onboardingStage = .active
    }
    
    //Feed Actions
    
    func addPost(text:String, category: Post.Category, hasPhoto: Bool) {
        let post = Post(
            authorName: currentResident.name.isEmpty ? "You" : currentResident.name,
            authorUnit: currentResident.unit,
            timestamp: <#T##Date#>(),
            category: category,
            text: text,
            hasPhoto: hasPhoto
        )
        posts.insert(Post, at: 0)
    }
    func toggleLike (post : Post) {
        guard let index = posts.firstIndex(where: {$0.id == post.id}) else { return }
        posts[index].likeCount += 1
    }
    
    //Lend & Borrow
    
    func requestItem(item : SharedItem) -> ChatThread {
        if let existing = chatThreads.first(where: { $0.neighborUnit == item.ownerUnit }) {
            return existing
        }
        let ownerFirst = item.ownerName.components(separatedBy: " ").first ?? item.ownerName
        let thread = ChatThread(
            neighborName: item.ownerName,
            neighborUnit: item.ownerUnit,
            contextNote: "You requested \(item.name) from \(ownerFirst)",
            messages: []
        )
        chatThreads.insert(thread, at: 0)
        return thread
    }
    
    // Events
    
    func toggleRSVP (for event: BuildingEvent) {
        guard let index = events.firstIndex(where: { $0.id == event.id}) else { return}
        events[index].isGoing.toggle()
        events[index].attendeeCount += events[index].isGoing ? 1 : -1
    }
    
    //Service hub actions
    
    func submitMaintenanceRequest( title:String, details:String) {
        let request = MaintenanceRequest (
            title: title,
            details: details,
            unit: currentResident.unit,
            submittedAt: <#T##Date#>()
        )
        maintenanceRequests.insert(request, at: 0)
    }
    
    func advanceStage( of request: MaintenanceRequest) {
        guard let index = bookingSlots.firstIndex(where: {$0.id == slot.id}) else {
            bookingSlots[index].isBooked = true
        }
    }
    
    func slots(for amenity: Amenity) -> [BookingSlot] {
        bookingSlots.filter { $0.amenityID == amenity.id }
    }
    
    // Chat
    func send( text:String, in thread:ChatThread) {
        guard let index = chatThreads.firstIndex(where: {$0.id == thread.id}) else {
            chatThreads[index].messages.append(
                ChatMessage(text:text, isMine: true, timestamp: Date())
            )
        }
    }
}
