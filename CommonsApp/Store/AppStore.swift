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
    @Published var onboardingStage: OnboardingStage = .loading
    @Published var pendingEmail: String = ""
    @Published var currentResident = Resident(name: "", unit: "")
    
    //Feed
    @Published var posts: [Post] = []
    
    //Lend & Borrow
    @Published var items: [SharedItem] = []
    @Published var reservedSharedItemIds: Set<String> = []
    @Published var unpublishedSharedItemIds: Set<String> = []
    @Published var borrowRequests: [BorrowRequest] = []
    @Published var borrowRequestsError: String? = nil
    private var borrowRequestsListener: ListenerRegistration?
    
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
    private var announcementListener: ListenerRegistration?
    private var residentPostsListener: ListenerRegistration?
    private var sharedItemsListener: ListenerRegistration?
    @Published var sharedItemsError: String? = nil
    private var chatDirectory: [String: (name: String, unit: String)] = [:]
    private var chatThreadsListener: ListenerRegistration?
    private var chatMessageListeners: [String: ListenerRegistration] = [:]
    
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
    // Prevent the app from loading resident data after sign-out.
    @MainActor
    func signOutResident() throws {
        try Auth.auth().signOut()

        // Stop Firestore listeners.
        stopAnnouncementListener()
        stopResidentPostsListener()
        stopSharedItemsListener()
        stopBorrowRequestsListener()
        borrowRequests.removeAll()
        items.removeAll()
        reservedSharedItemIds.removeAll()
        unpublishedSharedItemIds.removeAll()
        stopChatListeners()
        chatDirectory.removeAll()

        // Clear data from the previous resident's session.
        pinnedAnnouncementText = ""
        posts.removeAll()
        chatThreads.removeAll()

        pendingEmail = ""
        currentResident = Resident(name: "", unit: "")
        onboardingStage = .signIn

        // Refresh the widget after clearing the announcement.
        saveDataForWidget()
    }
    @MainActor
    func restoreSession() async {
        guard Auth.auth().currentUser != nil else {
            onboardingStage = .signIn
            return
        }

        do {
            try await loadResidentAccountStatus()
        } catch {
            print("Session restoration failed: \(error.localizedDescription)")
            onboardingStage = .signIn
        }
    }
    
    //checks the signed-in resident's Firestore profile and routes them correctly
    @MainActor
    func loadResidentAccountStatus() async throws {
        guard let user = Auth.auth().currentUser else {
            onboardingStage = .signIn
            return
        }

        try await user.reload()

        // Check the administrator role using Firebase's verified ID token.
        let tokenResult = try await user.getIDTokenResult(forcingRefresh: true)

        let isAdmin = tokenResult.claims["admin"] as? Bool == true

        if isAdmin {
            onboardingStage = .admin
            return
        }

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
                startSharedItemsListener()
                startBorrowRequestsListener()
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

        print("PROFILE DEBUG - Auth UID:", user.uid,
              "Email:", email,
              "Verified:", user.isEmailVerified)

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

        try await profileReference.setData(profileData)

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
    
    // Load pending resident applications for the administrator.
    @MainActor
    func loadPendingResidents() async throws {

        guard let user = Auth.auth().currentUser else {
            throw NSError(
                domain: "CommonsApp",
                code: 401,
                userInfo: [
                    NSLocalizedDescriptionKey: "Please sign in as an administrator."
                ]
            )
        }

        let tokenResult = try await user.getIDTokenResult(forcingRefresh: true)

        guard tokenResult.claims["admin"] as? Bool == true else {
            throw NSError(
                domain: "CommonsApp",
                code: 403,
                userInfo: [
                    NSLocalizedDescriptionKey: "Administrator access required."
                ]
            )
        }

        let snapshot = try await Firestore.firestore()
            .collection("users")
            .whereField("approvalStatus", isEqualTo: "pending")
            .getDocuments(source: .server)

        pendingResidents = snapshot.documents.compactMap { document in
            let data = document.data()

            guard let name = data["name"] as? String,
                  let unit = data["unit"] as? String else {
                return nil
            }

            let requestedAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()

            return PendingResident(
                id: document.documentID,
                name: name,
                unit: unit,
                requestedAt: requestedAt
            )
        }
    }

    // Approve or decline a pending resident.
    @MainActor
    func updateResidentApproval(
        residentID: String,
        approve: Bool
    ) async throws {

        guard let user = Auth.auth().currentUser else {
            throw NSError(
                domain: "CommonsApp",
                code: 401,
                userInfo: [
                    NSLocalizedDescriptionKey: "Please sign in as an administrator."
                ]
            )
        }

        let tokenResult = try await user.getIDTokenResult(forcingRefresh: true)

        guard tokenResult.claims["admin"] as? Bool == true else {
            throw NSError(
                domain: "CommonsApp",
                code: 403,
                userInfo: [
                    NSLocalizedDescriptionKey: "Administrator access required."
                ]
            )
        }

        let status = approve ? "approved" : "declined"

        try await Firestore.firestore()
            .collection("users")
            .document(residentID)
            .updateData([
                "approvalStatus": status
            ])

        try await loadPendingResidents()
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
    
    func saveResidentPostToFirestore(
        text: String,
        category: Post.Category,
        showAuthorName: Bool,
        showAuthorUnit: Bool
    ) async throws {

        guard let user = Auth.auth().currentUser else {
            throw NSError(
                domain: "CommonsApp",
                code: 401,
                userInfo: [
                    NSLocalizedDescriptionKey: "You must be signed in."
                ]
            )
        }

        guard category == .news || category == .askForHelp else {
            throw NSError(
                domain: "CommonsApp",
                code: 403,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Residents cannot publish announcements."
                ]
            )
        }

        let trimmedText = text.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedText.isEmpty && trimmedText.count <= 2000 else {
            throw NSError(
                domain: "CommonsApp",
                code: 400,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Post must contain between 1 and 2000 characters."
                ]
            )
        }

        let profile = try await Firestore.firestore()
            .collection("users")
            .document(user.uid)
            .getDocument(source: .server)

        guard let profileData = profile.data(),
              profileData["approvalStatus"] as? String == "approved" else {
            throw NSError(
                domain: "CommonsApp",
                code: 403,
                userInfo: [
                    NSLocalizedDescriptionKey: "Approved resident profile required."
                ]
            )
        }

        let name = profileData["name"] as? String ?? ""
        let unit = profileData["unit"] as? String ?? ""
        let unitAllowed = profileData["showUnitToNeighbors"] as? Bool == true

        let visibleName = showAuthorName ? name : ""
        let visibleUnit = showAuthorName && showAuthorUnit && unitAllowed
            ? unit
            : ""

        try await Firestore.firestore()
            .collection("posts")
            .addDocument(data: [
                "text": trimmedText,
                "category": category.rawValue,
                "createdAt": FieldValue.serverTimestamp(),
                "createdBy": user.uid,
                "showAuthorName": showAuthorName,
                "showAuthorUnit": !visibleUnit.isEmpty,
                "authorName": visibleName,
                "authorUnit": visibleUnit
            ])
    }

    func startResidentPostsListener() {
        guard residentPostsListener == nil else { return }
        guard Auth.auth().currentUser != nil else { return }

        residentPostsListener = Firestore.firestore()
            .collection("posts")
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .addSnapshotListener { [weak self] snapshot, error in

                if let error = error {
                    print("Resident posts listener error: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else { return }

                Task { @MainActor in
                    guard let self = self else { return }

                    let residentPosts: [Post] = documents.compactMap { document in
                        let data = document.data()

                        guard let text = data["text"] as? String,
                              let categoryString = data["category"] as? String,
                              let category = Post.Category(rawValue: categoryString)
                        else {
                            return nil
                        }

                        let timestamp = (data["createdAt"] as? Timestamp)?
                            .dateValue() ?? Date()

                        let showName = data["showAuthorName"] as? Bool == true
                        let showUnit = data["showAuthorUnit"] as? Bool == true

                        let savedName = data["authorName"] as? String ?? ""
                        let savedUnit = data["authorUnit"] as? String ?? ""

                        let displayName = showName && !savedName.isEmpty
                            ? savedName
                            : "Anonymous User"

                        let displayUnit = showName && showUnit
                            ? savedUnit
                            : ""

                        return Post(
                            authorName: displayName,
                            authorUnit: displayUnit,
                            timestamp: timestamp,
                            category: category,
                            text: text
                        )
                    }

                    // Keep administrator announcements separate.
                    self.posts.removeAll { !$0.isPinned }
                    self.posts.append(contentsOf: residentPosts)
                }
            }
    }

    func stopResidentPostsListener() {
        residentPostsListener?.remove()
        residentPostsListener = nil
    }

    func stopChatListeners() {
        chatThreadsListener?.remove()
        chatThreadsListener = nil

        for listener in chatMessageListeners.values {
            listener.remove()
        }

        chatMessageListeners.removeAll()
    }

    @MainActor
    func startChatThreadsListener() {
        guard chatThreadsListener == nil else { return }
        guard onboardingStage == .active else { return }
        guard let uid = Auth.auth().currentUser?.uid else { return }

        chatThreadsListener = Firestore.firestore()
            .collection("chats")
            .whereField("participantIds", arrayContains: uid)
            .addSnapshotListener { [weak self] snapshot, error in

                if let error = error {
                    print("Chat listener error: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else { return }

                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    guard Auth.auth().currentUser?.uid == uid else { return }
                    guard self.onboardingStage == .active else { return }

                    // Resolve only public, approved-resident directory fields.

                    do {

                        let directory = try await Firestore.firestore()

                            .collection("residentDirectory").getDocuments()

                        self.chatDirectory = Dictionary(uniqueKeysWithValues: directory.documents.compactMap { doc -> (String, (name: String, unit: String))? in

                            guard let name = doc.data()["name"] as? String, !name.isEmpty else { return nil }

                            return (doc.documentID, (name: name, unit: doc.data()["unit"] as? String ?? ""))

                        })

                    } catch {

                        print("Directory lookup failed: \(error.localizedDescription)")

                    }


                    let threads: [ChatThread] = documents.compactMap { document in
                        let data = document.data()

                        guard let participants = data["participantIds"] as? [String],
                              participants.count == 2,
                              participants.contains(uid),
                              let neighborUID = participants.first(where: { $0 != uid })
                        else {
                            return nil
                        }

                        // Names and units are not available in the current
                        // chat schema. Do not expose private user profiles.
                        let existing = self.chatThreads.first {
                            $0.firestoreId == document.documentID
                        }

                        var thread = ChatThread(
                            neighborName: self.chatDirectory[neighborUID]?.name ?? existing?.neighborName ?? "Resident",
                            neighborUnit: self.chatDirectory[neighborUID]?.unit ?? existing?.neighborUnit ?? "",
                            contextNote: existing?.contextNote,
                            messages: existing?.messages ?? [],
                            firestoreId: document.documentID,
                            neighborUID: neighborUID
                        )

                        if let existing {
                            thread.id = existing.id
                        }

                        return thread
                    }

                    self.chatThreads = threads
                }
            }
    }

    @MainActor
    func startChatMessagesListener(chatId: String) {
        guard chatMessageListeners[chatId] == nil else { return }
        guard onboardingStage == .active else { return }
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let listener = Firestore.firestore()
            .collection("chats")
            .document(chatId)
            .collection("messages")
            .order(by: "createdAt")
            .addSnapshotListener { [weak self] snapshot, error in

                if let error = error {
                    print("Chat messages listener error: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else { return }

                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    guard Auth.auth().currentUser?.uid == uid else { return }
                    guard self.onboardingStage == .active else { return }
                    guard self.chatMessageListeners[chatId] != nil else { return }

                    guard let threadIndex = self.chatThreads.firstIndex(where: {
                        $0.firestoreId == chatId
                    }) else {
                        return
                    }

                    let existingMessages = self.chatThreads[threadIndex].messages

                    let messages: [ChatMessage] = documents.compactMap { document in
                        let data = document.data()

                        guard let senderId = data["senderId"] as? String,
                              let text = data["text"] as? String
                        else {
                            return nil
                        }

                        let timestamp = (data["createdAt"] as? Timestamp)?
                            .dateValue() ?? Date()

                        let existing = existingMessages.first {
                            $0.firestoreId == document.documentID
                        }

                        var message = ChatMessage(
                            text: text,
                            isMine: senderId == uid,
                            timestamp: timestamp,
                            firestoreId: document.documentID
                        )

                        if let existing {
                            message.id = existing.id
                        }

                        return message
                    }

                    self.chatThreads[threadIndex].messages = messages
                }
            }

        chatMessageListeners[chatId] = listener
    }

    func stopChatMessagesListener(chatId: String) {
        chatMessageListeners[chatId]?.remove()
        chatMessageListeners.removeValue(forKey: chatId)
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
    
    //Prevents creating a conversation with me
    @MainActor
    func createChat(with neighborUID: String) async throws -> String {
        guard onboardingStage == .active,
              let currentUID = Auth.auth().currentUser?.uid,
              !neighborUID.isEmpty,
              currentUID != neighborUID else {
            throw NSError(
                domain: "CommonsApp.Chat",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid chat participants."
                ]
            )
        }

        let participants = [currentUID, neighborUID].sorted()

        // Deterministic, collision-free ID for a pair of Firebase UIDs.
        let chatId = participants
            .map { "\($0.utf8.count)_\($0)" }
            .joined(separator: "_")

        let chatReference = Firestore.firestore()
            .collection("chats")
            .document(chatId)

        // Check whether this conversation already exists.
        do {
            try await chatReference.setData([
                "participantIds": participants,
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
            ])
        } catch {
            // If the chat already exists, verify that it is accessible.
            let existing = try await chatReference.getDocument()
            guard existing.exists else {
                throw error
            }
        }

        return chatId
    }
    
    //Lend & Borrow
    
    @MainActor
    func startSharedItemsListener() {
        guard sharedItemsListener == nil, onboardingStage == .active,
              let uid = Auth.auth().currentUser?.uid else { return }
        sharedItemsError = nil
        sharedItemsListener = Firestore.firestore().collection("sharedItems")
            .order(by: "createdAt", descending: true).limit(to: 100)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor [weak self] in
                    guard let self = self, Auth.auth().currentUser?.uid == uid,
                          self.onboardingStage == .active else { return }
                    if let error = error {
                        self.sharedItemsError = error.localizedDescription
                        return
                    }
                    self.sharedItemsError = nil
                    self.unpublishedSharedItemIds = Set((snapshot?.documents ?? []).compactMap { doc in
                    (doc.data()["isPublished"] as? Bool == false) ? doc.documentID : nil
                })
                self.reservedSharedItemIds = Set((snapshot?.documents ?? []).compactMap { doc in
                    let lock = doc.data()["activeRequestId"] as? String ?? ""
                    return lock.isEmpty ? nil : doc.documentID
                })
                self.items = (snapshot?.documents ?? []).compactMap { doc in
                        let data = doc.data()
                        guard let name = data["name"] as? String,
                              let detail = data["detail"] as? String,
                              let ownerUID = data["ownerUID"] as? String,
                              let ownerName = data["ownerName"] as? String,
                              let ownerUnit = data["ownerUnit"] as? String,
                              let statusString = data["status"] as? String,
                              let status = SharedItem.Status(rawValue: statusString) else { return nil }
                        return SharedItem(id: UUID(uuidString: doc.documentID) ?? UUID(),
                            name: name, detail: detail, ownerName: ownerName,
                            ownerUnit: ownerUnit, status: status, ownerUID: ownerUID,
                            availability: data["availability"] as? String ?? "Available now",
                            firestoreId: doc.documentID)
                    }
                }
            }
    }

    func stopSharedItemsListener() {
        sharedItemsListener?.remove()
        sharedItemsListener = nil
    }

    @MainActor
    func publishSharedItem(name: String, detail: String, status: SharedItem.Status,
                           availability: String) async throws {
        guard onboardingStage == .active, let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "CommonsApp.Items", code: 403,
                          userInfo: [NSLocalizedDescriptionKey: "Approved resident required."])
        }
        let title = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let description = detail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, title.count <= 100, description.count <= 1000,
              ["Available now", "Weekends only"].contains(availability) else {
            throw NSError(domain: "CommonsApp.Items", code: 400,
                          userInfo: [NSLocalizedDescriptionKey: "Check the item name and description."])
        }
        let profile = try await Firestore.firestore().collection("users")
            .document(uid).getDocument(source: .server)
        guard let data = profile.data(), data["approvalStatus"] as? String == "approved" else {
            throw NSError(domain: "CommonsApp.Items", code: 403,
                          userInfo: [NSLocalizedDescriptionKey: "Approved resident required."])
        }
        try await Firestore.firestore().collection("sharedItems").addDocument(data: [
            "name": title, "detail": description, "status": status.rawValue,
            "availability": availability, "ownerUID": uid,
            "ownerName": data["name"] as? String ?? "Resident",
            "ownerUnit": data["showUnitToNeighbors"] as? Bool == true
                ? (data["unit"] as? String ?? "") : "",
            "createdAt": FieldValue.serverTimestamp(),
            "isPublished": true
        ])
    }

    // Requests are independent of Chat. Read only requests involving this UID.
    @MainActor
    func startBorrowRequestsListener() {
        guard borrowRequestsListener == nil, onboardingStage == .active,
              let uid = Auth.auth().currentUser?.uid else { return }
        borrowRequestsError = nil
        // Two participant queries would need merging; the authorized collection
        // query uses a participantIds array to receive both incoming and outgoing.
        borrowRequestsListener = Firestore.firestore().collection("borrowRequests")
            .whereField("participantIds", arrayContains: uid)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor [weak self] in
                    guard let self, Auth.auth().currentUser?.uid == uid,
                          self.onboardingStage == .active else { return }
                    if let error { self.borrowRequestsError = error.localizedDescription; return }
                    self.borrowRequestsError = nil
                    self.borrowRequests = (snapshot?.documents ?? []).compactMap { doc in
                        let d = doc.data()
                        guard let itemId = d["itemId"] as? String,
                              let itemName = d["itemName"] as? String,
                              let owner = d["ownerUID"] as? String,
                              let borrower = d["borrowerUID"] as? String,
                              let requester = d["requesterName"] as? String,
                              let start = (d["startDate"] as? Timestamp)?.dateValue(),
                              let end = (d["endDate"] as? Timestamp)?.dateValue(),
                              let statusRaw = d["status"] as? String,
                              let status = BorrowRequest.Status(rawValue: statusRaw) else { return nil }
                        return BorrowRequest(id: doc.documentID, itemId: itemId,
                            itemName: itemName, ownerUID: owner, borrowerUID: borrower,
                            requesterName: requester, startDate: start, endDate: end,
                            note: d["note"] as? String ?? "", status: status,
                            createdAt: (d["createdAt"] as? Timestamp)?.dateValue() ?? .distantPast,
                            listingStatus: d["listingStatus"] as? String ?? "Lending")
                    }.sorted { $0.createdAt > $1.createdAt }
                }
            }
    }

    func stopBorrowRequestsListener() {
        borrowRequestsListener?.remove()
        borrowRequestsListener = nil
    }

    @MainActor
    func submitBorrowRequest(for item: SharedItem, startDate: Date,
                             endDate: Date, note: String) async throws {
        guard onboardingStage == .active, let uid = Auth.auth().currentUser?.uid,
              let owner = item.ownerUID, owner != uid else {
            throw itemError("You cannot request this listing.")
        }
        let start = Calendar.current.startOfDay(for: startDate)
        let end = Calendar.current.startOfDay(for: endDate)
        guard start >= Calendar.current.startOfDay(for: Date()), end >= start,
              end.timeIntervalSince(start) <= 60 * 86400, note.count <= 500 else {
            throw itemError("Choose valid dates (up to 60 days) and a note under 500 characters.")
        }
        guard let firestoreId = item.firestoreId, !firestoreId.isEmpty else {
            throw itemError("This listing has no Firestore document ID. Refresh and try again.")
        }
        let db = Firestore.firestore()
        let itemRef = db.collection("sharedItems").document(firestoreId)
        let requestRef = db.collection("borrowRequests").document()
        let profile = try await db.collection("users").document(uid).getDocument(source: .server)
        guard let resident = profile.data(), resident["approvalStatus"] as? String == "approved" else {
            throw itemError("Approved resident required.")
        }
        let requesterName = resident["name"] as? String ?? "Resident"
        let itemName = item.name
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        _ = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                let listing = try transaction.getDocument(itemRef)
                guard let data = listing.data(),
                      data["ownerUID"] as? String == owner,
                      data["status"] as? String == item.status.rawValue,
                      data["isPublished"] as? Bool != false,
                      data["name"] as? String == itemName else {
                    throw NSError(domain: "CommonsApp.Borrow", code: 409,
                                  userInfo: [NSLocalizedDescriptionKey: "This listing is no longer available."])
                }
                guard (data["activeRequestId"] as? String ?? "").isEmpty else {
                    throw NSError(domain: "CommonsApp.Borrow", code: 409,
                                  userInfo: [NSLocalizedDescriptionKey: "This item already has an active borrowing request."])
                }
                transaction.setData([
                    "itemId": firestoreId, "itemName": itemName,
                    "ownerUID": owner, "borrowerUID": uid,
                    "listingStatus": item.status.rawValue,
                    "participantIds": [owner, uid].sorted(),
                    "requesterName": requesterName,
                    "startDate": Timestamp(date: start), "endDate": Timestamp(date: end),
                    "note": trimmedNote, "status": "pending",
                    "createdAt": FieldValue.serverTimestamp(),
                    "updatedAt": FieldValue.serverTimestamp()
                ], forDocument: requestRef)
                transaction.updateData(["activeRequestId": requestRef.documentID], forDocument: itemRef)
                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }

    @MainActor
    func advanceBorrowRequest(_ request: BorrowRequest, to next: BorrowRequest.Status, keepPublished: Bool = true) async throws {
        guard onboardingStage == .active, let uid = Auth.auth().currentUser?.uid else {
            throw itemError("Please sign in.")
        }
        let ownerAction = request.ownerUID == uid
        let borrowerAction = request.borrowerUID == uid
        let needed = request.isNeededOffer
        let permitted: Bool = {
            switch (request.status, next) {
            case (.pending, .approved), (.pending, .declined),
                 (.approved, .collected): return ownerAction
            case (.collected, .returned): return needed ? borrowerAction : ownerAction
            case (.pending, .cancelled), (.approved, .cancelled): return borrowerAction
            default: return false
            }
        }()
        guard permitted else { throw itemError("This action is not permitted.") }
        let db = Firestore.firestore()
        let requestRef = db.collection("borrowRequests").document(request.id)
        let itemRef = db.collection("sharedItems").document(request.itemId)
        // A transaction serializes approvals against a single active listing.
        _ = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                let req = try transaction.getDocument(requestRef)
                let item = try transaction.getDocument(itemRef)
                guard let rd = req.data(), let id = item.data(),
                      rd["status"] as? String == request.status.rawValue,
                      rd["ownerUID"] as? String == request.ownerUID,
                      rd["borrowerUID"] as? String == request.borrowerUID,
                      rd["itemId"] as? String == request.itemId,
                      (rd["listingStatus"] as? String ?? "Lending") == request.listingStatus,
                      id["status"] as? String == request.listingStatus,
                      id["ownerUID"] as? String == request.ownerUID else {
                    throw NSError(domain: "CommonsApp.Borrow", code: 409, userInfo: [NSLocalizedDescriptionKey: "The request has changed. Refresh and try again."])
                }
                let active = id["activeRequestId"] as? String ?? ""
                guard active == request.id else {
                    throw NSError(domain: "CommonsApp.Borrow", code: 409,
                                  userInfo: [NSLocalizedDescriptionKey: "Reservation mismatch. Refresh and try again."])
                }
                if next == .returned || next == .declined || next == .cancelled {
                    if next == .returned {
                        if needed {
                            transaction.updateData(["activeRequestId": ""], forDocument: itemRef)
                        } else {
                            transaction.updateData(["activeRequestId": "", "isPublished": keepPublished], forDocument: itemRef)
                        }
                    } else {
                        transaction.updateData(["activeRequestId": ""], forDocument: itemRef)
                    }
                }
                transaction.updateData(["status": next.rawValue,
                                        "updatedAt": FieldValue.serverTimestamp()], forDocument: requestRef)
                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }

    @MainActor
    func setSharedItemPublished(itemId: String, published: Bool) async throws {
        guard onboardingStage == .active, let uid = Auth.auth().currentUser?.uid else {
            throw itemError("Please sign in.")
        }
        let ref = Firestore.firestore().collection("sharedItems").document(itemId)
        _ = try await Firestore.firestore().runTransaction { transaction, errorPointer -> Any? in
            do {
                let snap = try transaction.getDocument(ref)
                guard let data = snap.data(), data["ownerUID"] as? String == uid,
                      (data["activeRequestId"] as? String ?? "").isEmpty else {
                    throw self.itemError("Only the owner can change a listing without an active request.")
                }
                transaction.updateData(["isPublished": published], forDocument: ref)
                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }

    private func itemError(_ message: String) -> NSError {
        NSError(domain: "CommonsApp.Borrow", code: 400,
                userInfo: [NSLocalizedDescriptionKey: message])
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
        let messageText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !messageText.isEmpty,
              messageText.count <= 2000,
              let chatId = thread.firestoreId,
              let uid = Auth.auth().currentUser?.uid
        else {
            return
        }

        Firestore.firestore()
            .collection("chats")
            .document(chatId)
            .collection("messages")
            .addDocument(data: [
                "senderId": uid,
                "text": messageText,
                "createdAt": FieldValue.serverTimestamp()
            ]) { error in
                if let error = error {
                    print("Failed to send chat message: \(error.localizedDescription)")
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
        
        // Firestore provides shared items for approved residents.
        items = []
        
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
        
        //Create sample pending residents
        pendingResidents = [
            PendingResident(id: "demo-priya", name: "Priya Nair", unit: "4B", requestedAt: now),
            PendingResident(id: "demo-tom", name: "Tom Alcott", unit: "11D", requestedAt: now)
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

    func saveAnnouncementToFirestore(_ text: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(
                domain: "CommonsApp",
                code: 401,
                userInfo: [
                    NSLocalizedDescriptionKey: "You must be signed in."
                ]
            )
        }

        let token = try await user.getIDTokenResult()

        guard token.claims["admin"] as? Bool == true else {
            throw NSError(
                domain: "CommonsApp",
                code: 403,
                userInfo: [
                    NSLocalizedDescriptionKey: "Only administrators can post announcements."
                ]
            )
        }

        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedText.isEmpty else {
            throw NSError(
                domain: "CommonsApp",
                code: 400,
                userInfo: [
                    NSLocalizedDescriptionKey: "Announcement cannot be empty."
                ]
            )
        }

        try await Firestore.firestore()
            .collection("announcements")
            .addDocument(data: [
                "text": trimmedText,
                "createdAt": FieldValue.serverTimestamp(),
                "createdBy": user.uid,
                "isPinned": true
            ])
    }

    func loadLatestAnnouncement() async throws {
        guard Auth.auth().currentUser != nil else {
            return
        }

        let snapshot = try await Firestore.firestore()
            .collection("announcements")
            .order(by: "createdAt", descending: true)
            .limit(to: 1)
            .getDocuments()

        guard let document = snapshot.documents.first,
              let text = document.data()["text"] as? String,
              !text.isEmpty else {
            return
        }

        pinnedAnnouncementText = text

        // Update the existing Building Wall post collection.
        let announcementPost = Post(
            authorName: "Management",
            authorUnit: "—",
            timestamp: (document.data()["createdAt"] as? Timestamp)?.dateValue()
                ?? Date(),
            category: .announcement,
            text: text,
            isPinned: true
        )

        posts.removeAll { $0.isPinned }
        posts.insert(announcementPost, at: 0)

        // Preserve widget updates.
        saveDataForWidget()
    }

    //newest Firestore announcement and updates the Building Wall automatically
    func startAnnouncementListener() {
        // Prevent duplicate listeners.
        guard announcementListener == nil else { return }

        guard Auth.auth().currentUser != nil else { return }

        announcementListener = Firestore.firestore()
            .collection("announcements")
            .order(by: "createdAt", descending: true)
            .limit(to: 1)
            .addSnapshotListener { [weak self] snapshot, error in

                if let error = error {
                    print("Announcement listener error: \(error.localizedDescription)")
                    return
                }

                guard let document = snapshot?.documents.first,
                      let text = document.data()["text"] as? String else {
                    return
                }

                let timestamp = (document.data()["createdAt"] as? Timestamp)?
                    .dateValue() ?? Date()

                Task { @MainActor in
                    guard let self = self else { return }

                    self.pinnedAnnouncementText = text

                    let announcementPost = Post(
                        authorName: "Management",
                        authorUnit: "—",
                        timestamp: timestamp,
                        category: .announcement,
                        text: text,
                        isPinned: true
                    )

                    self.posts.removeAll { $0.isPinned }
                    self.posts.insert(announcementPost, at: 0)

                    self.saveDataForWidget()
                }
            }
    }

    func stopAnnouncementListener() {
        announcementListener?.remove()
        announcementListener = nil
    }
}

