//
//  AppStore.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 21/9/2026.
//

import Foundation
import SwiftUI
import Combine
import LocalAuthentication
import FirebaseAuth
import FirebaseFirestore

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
        // Replaced by Firebase email/password registration.
        // Authentication will be handled by the sign-in form.
    }

    @MainActor
    func checkEmailVerification() async throws -> Bool {
        guard let user = Auth.auth().currentUser else {
            onboardingStage = .signIn
            return false
        }

        try await user.reload()

        guard user.isEmailVerified else {
            return false
        }

        try await loadResidentAccountStatus()
        return true
    }
    
    //checks the signed-in resident's Firestore profile and routes them correctly
    @MainActor
    func loadResidentAccountStatus() async throws {
        guard let user = Auth.auth().currentUser else {
            onboardingStage = .signIn
            return
        }

        try await user.reload()

        let document = try await Firestore.firestore()
            .collection("users")
            .document(user.uid)
            .getDocument(source: .server)

        guard document.exists, let data = document.data() else {
            onboardingStage = .profileSetup
            return
        }

        let name = data["name"] as? String ?? ""
        let unit = data["unit"] as? String ?? ""
        let phone = data["phone"] as? String ?? ""
        let showUnit = data["showUnitToNeighbors"] as? Bool ?? true

        currentResident = Resident(
            name: name,
            unit: unit,
            phone: phone,
            contactPreference: .push,
            showUnitToNeighbors: showUnit
        )

        pendingEmail = user.email ?? ""

        let approvalStatus = data["approvalStatus"] as? String ?? "pending"

        if !user.isEmailVerified {
            onboardingStage = .waitingRoom
        } else {
            switch approvalStatus {
            case "approved":
                onboardingStage = .active
            case "declined":
                onboardingStage = .accessDeclined
            default:
                onboardingStage = .pendingApproval
            }
        }
    }
    
    //use to save the user data to firestore
    
    @MainActor
    func saveResidentProfile(
        name: String,
        unit: String,
        phone: String,
        preference: Resident.ContactPreference,
        showUnit: Bool
    ) async throws {
        guard let user = Auth.auth().currentUser,
              let email = user.email else {
            throw NSError(
                domain: "CommonsApp",
                code: 401,
                userInfo: [
                    NSLocalizedDescriptionKey: "Please sign in before completing your profile."
                ]
            )
        }

        let profileData: [String: Any] = [
            "name": name.trimmingCharacters(in: .whitespacesAndNewlines),
            "unit": unit.trimmingCharacters(in: .whitespacesAndNewlines),
            "phone": phone.trimmingCharacters(in: .whitespacesAndNewlines),
            "email": email,
            "contactPreference": "push",
            "showUnitToNeighbors": showUnit,
            "approvalStatus": "pending",
            "createdAt": FieldValue.serverTimestamp()
        ]

        let profileReference = Firestore.firestore()
            .collection("users")
            .document(user.uid)

        try await Firestore.firestore().runTransaction { transaction, errorPointer in
            do {
                let existingProfile = try transaction.getDocument(profileReference)

                if existingProfile.exists {
                    errorPointer?.pointee = NSError(
                        domain: "CommonsApp",
                        code: 409,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "Your resident profile already exists. Please sign in instead."
                        ]
                    )
                    return nil
                }

                transaction.setData(profileData, forDocument: profileReference)
                return nil

            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }

        currentResident = Resident(
            name: name,
            unit: unit,
            phone: phone,
            contactPreference: preference,
            showUnitToNeighbors: showUnit
        )

        pendingEmail = email
        onboardingStage = .waitingRoom
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
    
    func toggleLike(_ post: Post) {
        // Find the matching post and add 1 like
        for index in 0..<posts.count {
            if posts[index].id == post.id {
                posts[index].likeCount += 1
                break
            }
        }
    }
    
    //Lend & Borrow
    
    func requestItem(_ item: SharedItem) -> ChatThread {
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
    
    func getSlots(for amenity: Amenity) -> [BookingSlot] {
        // Go through all slots and return only the ones
        // that belong to this amenity
        var result: [BookingSlot] = []
        for slot in bookingSlots {
            if slot.amenityID == amenity.id {
                result.append(slot)
            }
        }
        return result
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
        // Find Community Room by name instead of guessing the index
        var communityRoom: Amenity? = nil
        for amenity in amenities {
            if amenity.name == "Community Room" {
                communityRoom = amenity
                break
            }
        }

        // If we didn't find it, stop here
        if communityRoom == nil { return }

        let cal = Calendar.current
        // Start at 9am today
        let base = cal.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!

        bookingSlots = []
        for index in 0..<10 {
            let isSlotBooked = (index == 2 || index == 5 || index == 8)

            // Each slot is 1 hour apart
            let slotTime = cal.date(byAdding: .hour, value: index, to: base)!

            let slot = BookingSlot(
                amenityID: communityRoom!.id,
                start: slotTime,
                isBooked: isSlotBooked
            )
            bookingSlots.append(slot)
        }
    }
    
    //App Lock (Face ID / Touch ID)

    func lockApp() {
        // Only lock if the user has turned on app lock
        if appLockEnabled {
            isLocked = true
        }
    }
    
    func saveDataForWidget() {
        // We use UserDefaults with our App Group to share data
        // with the widget extension
        let defaults = UserDefaults(suiteName: "group.com.yourname.commonsapp")

        // Save the pinned announcement text
        defaults?.set(pinnedAnnouncementText, forKey: "pinnedAnnouncement")

        // Save the next event title if there is one
        if let nextEvent = events.first {
            defaults?.set(nextEvent.title, forKey: "nextEventTitle")
            defaults?.set(nextEvent.location, forKey: "nextEventLocation")
        }
    }

    func unlockWithBiometrics(completion: @escaping (Bool) -> Void) {
        // Import LocalAuthentication to use Face ID
        let context = LAContext()
        var error: NSError?

        // Check if Face ID or Touch ID is available on this device
        let canUseBiometrics = context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        )

        if canUseBiometrics {
            // Ask the user to authenticate
            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Unlock Commons"
            ) { success, error in
                // Come back to the main thread to update the UI
                DispatchQueue.main.async {
                    if success {
                        self.isLocked = false
                    }
                    completion(success)
                }
            }
        } else {
            // Biometrics not available on this device
            completion(false)
        }
    }
    
    func pinAnnouncement(_ text: String) {
        // Update pinned text
        pinnedAnnouncementText = text

        // Add as pinned post on the wall
        let newPost = Post(
            authorName: "Management",
            authorUnit: "—",
            timestamp: Date(),
            category: .announcement,
            text: text,
            isPinned: true
        )

        // Remove old pinned posts
        var updatedPosts: [Post] = []
        for post in posts {
            if !post.isPinned {
                updatedPosts.append(post)
            }
        }
        updatedPosts.insert(newPost, at: 0)
        posts = updatedPosts

        // Save for widget
        saveDataForWidget()
    }
}

