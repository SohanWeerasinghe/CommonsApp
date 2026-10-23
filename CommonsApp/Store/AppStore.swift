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
import WidgetKit
    // MARK: - App-wide state and Firestore listener references
final class AppStore: ObservableObject {
    //Onboarding
    @Published var onboardingStage: OnboardingStage = .loading
    @Published var pendingEmail: String = ""
    @Published var currentResident = Resident(name: "", unit: "")
    //Feed
    @Published var posts: [Post] = []
    @Published var eventNoticePosts: [Post] = []
    //Lend & Borrow
    @Published var items: [SharedItem] = []
    @Published var reservedSharedItemIds: Set<String> = []
    @Published var unpublishedSharedItemIds: Set<String> = []
    @Published var borrowRequests: [BorrowRequest] = []
    @Published var borrowRequestsError: String? = nil
    private var borrowRequestsListener: ListenerRegistration?
    //Events
    @Published var events: [BuildingEvent] = []
    @Published var eventsError: String? = nil
    private var eventsListener: ListenerRegistration?
    private var eventAttendeeListeners: [String: ListenerRegistration] = [:]
    //Service Hub
    @Published var maintenanceRequests: [MaintenanceRequest] = []
    @Published var maintenanceError: String? = nil
    private var maintenanceListener: ListenerRegistration?
    @Published var amenities: [Amenity] = []
    @Published var bookingSlots: [BookingSlot] = []
    @Published var gymCapacity: Int = 10
    @Published var gymOccupancy: [String: Int] = [:]
    @Published var gymMySlotIDs: Set<String> = []
    @Published var gymMembersBySlot: [String: [String]] = [:]
    @Published var gymError: String? = nil
    private var gymSlotsListener: ListenerRegistration?
    private var gymSettingsListener: ListenerRegistration?
    //Chat
    @Published var chatThreads: [ChatThread] = []
    @Published var incomingChatNotification: ChatNotification? = nil
    private var initializedChatListeners: Set<String> = []
    private var activeChatId: String? = nil
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
    @Published private(set) var appLockEnabled: Bool = false
    @Published var isLocked: Bool = false
    private let appLockPreferenceKey = "commonsAppLockEnabled"
    @Published private(set) var appLockDelay: Int = 0
    private let appLockDelayPreferenceKey = "commonsAppLockDelay"
    private var appLeftForegroundAt: Date?
    //Demo
    @Published var isManagerMode: Bool = false
    //Sample data loading
    // MARK: - Initialization and sample data
    init() {
        appLockEnabled = UserDefaults.standard.bool(forKey: appLockPreferenceKey)
        isLocked = appLockEnabled
        appLockDelay = UserDefaults.standard.integer(
            forKey: appLockDelayPreferenceKey
        )
        seedSampleData()
    }
    // MARK: - Authentication and resident onboarding
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
        stopEventsListener()
        stopMaintenanceListener()
        stopGymListeners()
        maintenanceRequests.removeAll()
        maintenanceError = nil
        events.removeAll()
        eventsError = nil
        // Clear data from the previous resident's session.
        pinnedAnnouncementText = ""
        posts.removeAll()
        eventNoticePosts.removeAll()
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
            startEventsListener()
            startMaintenanceListener()
            startGymListeners()
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
                startEventsListener()
                startMaintenanceListener()
                startGymListeners()
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
        // Google accounts already have a verified email. They can wait for admin approval.
        // Email/password accounts still need the existing email verification step.
        if user.isEmailVerified {
            onboardingStage = .pendingApproval
        } else {
            onboardingStage = .waitingRoom
        }
    }
    // MARK: - Administrator resident approvals
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
        var status = "declined"
        if approve {
            status = "approved"
        }
        try await Firestore.firestore()
            .collection("users")
            .document(residentID)
            .updateData([
                "approvalStatus": status
            ])
        try await loadPendingResidents()
    }
    // MARK: - Community Wall posts and photos
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
    // Validate and publish a post; save its optional photo in the same Firestore batch.
    func saveResidentPostToFirestore(
        text: String,
        category: Post.Category,
        showAuthorName: Bool,
        showAuthorUnit: Bool,
        photoData: Data? = nil
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
        var visibleName = ""
        if showAuthorName {
            visibleName = name
        }
        var visibleUnit = ""
        if showAuthorName && showAuthorUnit && unitAllowed {
            visibleUnit = unit
        }
        let database = Firestore.firestore()
        let postReference = database.collection("posts").document()
        var postFields: [String: Any] = [
            "text": trimmedText,
            "category": category.rawValue,
            "createdAt": FieldValue.serverTimestamp(),
            "createdBy": user.uid,
            "showAuthorName": showAuthorName,
            "showAuthorUnit": !visibleUnit.isEmpty,
            "authorName": visibleName,
            "authorUnit": visibleUnit
        ]
        let batch = database.batch()
        if let photoData {
            let base64 = photoData.base64EncodedString()
            guard !base64.isEmpty && base64.count <= 500_000 else {
                throw NSError(domain: "CommonsApp", code: 413,
                              userInfo: [NSLocalizedDescriptionKey: "Photo exceeds the size limit."])
            }
            postFields["photoId"] = postReference.documentID
            let photoReference = database.collection("residentPostPhotos")
                .document(postReference.documentID)
            batch.setData([
                "imageBase64": base64,
                "ownerUID": user.uid,
                "createdAt": FieldValue.serverTimestamp()
            ], forDocument: photoReference)
        }
        batch.setData(postFields, forDocument: postReference)
        try await batch.commit()
    }
    // Keep the feed synchronized with Firestore posts.
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
                            text: text,
                            hasPhoto: data["photoId"] as? String != nil,
                            photoId: data["photoId"] as? String
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
    // MARK: - Chat listeners and incoming messages
    func stopChatListeners() {
        chatThreadsListener?.remove()
        chatThreadsListener = nil
        for listener in chatMessageListeners.values {
            listener.remove()
        }
        chatMessageListeners.removeAll()
        initializedChatListeners.removeAll()
        activeChatId = nil
        incomingChatNotification = nil
    }
    @MainActor
    // Load the signed-in resident’s chat conversations.
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
                        var residentDirectory: [String: (name: String, unit: String)] = [:]
                        for document in directory.documents {
                            let data = document.data()
                            if let name = data["name"] as? String, !name.isEmpty {
                                let unit = data["unit"] as? String ?? ""
                                residentDirectory[document.documentID] = (name: name, unit: unit)
                            }
                        }
                        self.chatDirectory = residentDirectory
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
                    let chatIds = Set(threads.compactMap { $0.firestoreId })
                    for chatId in chatIds {
                        self.startChatMessagesListener(chatId: chatId)
                    }
                    for chatId in Array(self.chatMessageListeners.keys) {
                        if !chatIds.contains(chatId) {
                            self.stopChatMessagesListener(chatId: chatId)
                        }
                    }
                }
            }
    }
    @MainActor
    // Listen for messages and detect new incoming notifications.
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
                    print("CHAT DEBUG: Message snapshot received for \(chatId)")
                    print("CHAT DEBUG: Documents = \(documents.count)")
                    print("CHAT DEBUG: Changes = \(snapshot?.documentChanges.count ?? 0)")
                    let isFirstSnapshot = !self.initializedChatListeners.contains(chatId)
                    if isFirstSnapshot {
                        self.initializedChatListeners.insert(chatId)
                    }
                    if !isFirstSnapshot && self.activeChatId != chatId {
                        let existingMessageIds = Set(
                            existingMessages.compactMap { $0.firestoreId }
                        )
                        for change in snapshot?.documentChanges ?? [] {
                            if change.type != .added {
                                continue
                            }
                            let document = change.document
                            let data = document.data()
                            if existingMessageIds.contains(document.documentID) {
                                continue
                            }
                            guard let senderId = data["senderId"] as? String,
                                  senderId != uid,
                                  let text = data["text"] as? String,
                                  !text.isEmpty
                            else {
                                continue
                            }
                            let senderName = self.chatThreads[threadIndex].neighborName
                            print("CHAT NOTIFICATION: \(senderName): \(text)")
                            self.incomingChatNotification = ChatNotification(
                                id: document.documentID,
                                chatId: chatId,
                                senderName: senderName,
                                message: text
                            )
                        }
                    }
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
        initializedChatListeners.remove(chatId)
    }
    // MARK: - Post reactions
    func toggleLike(_ post: Post) {
        // Find the matching post and add 1 like
        for index in 0..<posts.count {
            if posts[index].id == post.id {
                posts[index].likeCount += 1
                break
            }
        }
    }
    // MARK: - Creating resident chats
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
    // MARK: - Lend and Borrow listings and photos
    //Lend & Borrow
    @MainActor
    // Listen for published listings and their photo references.
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
                    var unpublishedIDs: Set<String> = []
                    var reservedIDs: Set<String> = []
                    for document in snapshot?.documents ?? [] {
                        let data = document.data()
                        if data["isPublished"] as? Bool == false {
                            unpublishedIDs.insert(document.documentID)
                        }
                        let activeRequestID = data["activeRequestId"] as? String ?? ""
                        if !activeRequestID.isEmpty {
                            reservedIDs.insert(document.documentID)
                        }
                    }
                    self.unpublishedSharedItemIds = unpublishedIDs
                    self.reservedSharedItemIds = reservedIDs
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
                            firestoreId: doc.documentID,
                            photoId: data["photoId"] as? String)
                    }
                }
            }
    }
    func stopSharedItemsListener() {
        sharedItemsListener?.remove()
        sharedItemsListener = nil
    }
    @MainActor
    // Create a lending or needed listing with an optional Firestore photo.
    func publishSharedItem(name: String, detail: String, status: SharedItem.Status,
                           availability: String, photoData: Data? = nil) async throws {
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
        var ownerUnit = ""
        if data["showUnitToNeighbors"] as? Bool == true {
            ownerUnit = data["unit"] as? String ?? ""
        }
        let database = Firestore.firestore()
        let itemReference = database.collection("sharedItems").document()
        var fields: [String: Any] = [
            "name": title, "detail": description, "status": status.rawValue,
            "availability": availability, "ownerUID": uid,
            "ownerName": data["name"] as? String ?? "Resident",
            "ownerUnit": ownerUnit,
            "createdAt": FieldValue.serverTimestamp(),
            "isPublished": true
        ]
        let batch = database.batch()
        if let photoData {
            let base64 = photoData.base64EncodedString()
            guard !base64.isEmpty && base64.count <= 500_000 else {
                throw NSError(domain: "CommonsApp.Items", code: 413,
                              userInfo: [NSLocalizedDescriptionKey: "Photo exceeds the size limit."])
            }
            fields["photoId"] = itemReference.documentID
            batch.setData([
                "imageBase64": base64,
                "ownerUID": uid,
                "createdAt": FieldValue.serverTimestamp()
            ], forDocument: database.collection("sharedItemPhotos").document(itemReference.documentID))
        }
        batch.setData(fields, forDocument: itemReference)
        try await batch.commit()
    }
    // MARK: - Borrow request lifecycle
    // Requests are independent of Chat. Read only requests involving this UID.
    @MainActor
    // Listen for requests involving the signed-in resident.
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
    // Submit a borrowing request using a transaction to prevent conflicts.
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
    // Advance borrowing requests through their allowed status changes.
    func advanceBorrowRequest(_ request: BorrowRequest, to next: BorrowRequest.Status, keepPublished: Bool = true) async throws {
        guard onboardingStage == .active, let uid = Auth.auth().currentUser?.uid else {
            throw itemError("Please sign in.")
        }
        let ownerAction = request.ownerUID == uid
        let borrowerAction = request.borrowerUID == uid
        let needed = request.isNeededOffer
        var permitted = false
        switch (request.status, next) {
        case (.pending, .approved), (.pending, .declined), (.approved, .collected):
            permitted = ownerAction
        case (.collected, .returned):
            if needed {
                permitted = borrowerAction
            } else {
                permitted = ownerAction
            }
        case (.pending, .cancelled), (.approved, .cancelled):
            permitted = borrowerAction
        default:
            permitted = false
        }
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
    // MARK: - Community events, RSVP, and cover images
    //Events
    @MainActor
    // Load community events and their cover references.
    func startEventsListener() {
        guard eventsListener == nil,
              onboardingStage == .active || onboardingStage == .admin,
              let uid = Auth.auth().currentUser?.uid else { return }
        eventsError = nil
        eventsListener = Firestore.firestore()
            .collection("events")
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor [weak self] in
                    guard let self,
                          Auth.auth().currentUser?.uid == uid,
                          self.onboardingStage == .active ||
                          self.onboardingStage == .admin else { return }
                    if let error {
                        self.eventsError = error.localizedDescription
                        return
                    }
                    self.eventsError = nil
                    self.events = (snapshot?.documents ?? []).compactMap { doc in
                        let data = doc.data()
                        guard let title = data["title"] as? String,
                              let date = (data["date"] as? Timestamp)?.dateValue(),
                              let location = data["location"] as? String,
                              let statusString = data["status"] as? String,
                              let status = BuildingEvent.Status(rawValue: statusString)
                        else { return nil }
                        let previousEvent = self.events.first {
                            $0.firestoreId == doc.documentID
                        }
                        var event = BuildingEvent(
                            id: previousEvent?.id ?? UUID(),
                            title: title,
                            date: date,
                            location: location,
                            attendeeCount: previousEvent?.attendeeCount ?? 0,
                            isGoing: previousEvent?.isGoing ?? false
                        )
                        event.firestoreId = doc.documentID
                        event.description = data["description"] as? String ?? ""
                        event.endDate = (data["endDate"] as? Timestamp)?.dateValue()
                        event.allowsRSVP = data["allowsRSVP"] as? Bool ?? false
                        event.status = status
                        event.createdBy = data["createdBy"] as? String ?? ""
                        event.coverId = data["coverId"] as? String
                        return event
                    }
                    .sorted { $0.date < $1.date }
                    self.syncEventAttendeeListeners(for: self.events, uid: uid)
                    self.saveDataForWidget()
                    await EventReminderManager.shared.synchronize(with: self.events)
                }
            }
    }
    @MainActor
    // Keep event attendee counts and RSVP states up to date.
    private func syncEventAttendeeListeners(
        for currentEvents: [BuildingEvent],
        uid: String
    ) {
        let eventIds = Set(currentEvents.compactMap(\.firestoreId))
        // Remove listeners for events that no longer exist.
        for (eventId, listener) in eventAttendeeListeners {
            if !eventIds.contains(eventId) {
                listener.remove()
                eventAttendeeListeners.removeValue(forKey: eventId)
            }
        }
        // Listen to attendee changes for each event.
        for eventId in eventIds {
            guard eventAttendeeListeners[eventId] == nil else {
                continue
            }
            let listener = Firestore.firestore()
                .collection("events")
                .document(eventId)
                .collection("attendees")
                .addSnapshotListener { [weak self] snapshot, error in
                    Task { @MainActor [weak self] in
                        guard let self,
                              Auth.auth().currentUser?.uid == uid,
                              self.eventAttendeeListeners[eventId] != nil,
                              self.onboardingStage == .active ||
                              self.onboardingStage == .admin else {
                            return
                        }
                        if let error {
                            self.eventsError = error.localizedDescription
                            return
                        }
                        let attendees = snapshot?.documents ?? []
                        let count = attendees.count
                        let isGoing = attendees.contains {
                            $0.documentID == uid
                        }
                        guard let index = self.events.firstIndex(where: {
                            $0.firestoreId == eventId
                        }) else {
                            return
                        }
                        self.events[index].attendeeCount = count
                        self.events[index].isGoing = isGoing
                    }
                }
            eventAttendeeListeners[eventId] = listener
        }
    }
    @MainActor
    func stopEventsListener() {
        eventsListener?.remove()
        eventsListener = nil
        for listener in eventAttendeeListeners.values {
            listener.remove()
        }
        eventAttendeeListeners.removeAll()
    }
    @MainActor
    func toggleRSVP(for event: BuildingEvent) {
        guard onboardingStage == .active,
              let uid = Auth.auth().currentUser?.uid,
              let eventId = event.firestoreId,
              !eventId.isEmpty,
              event.allowsRSVP,
              !event.isCancelled,
              event.date > Date() else {
            eventsError = "RSVP is not available for this event."
            return
        }
        Task { @MainActor in
            do {
                let db = Firestore.firestore()
                let eventRef = db.collection("events").document(eventId)
                let attendeeRef = eventRef.collection("attendees").document(uid)
                // Read the current RSVP from Firestore, not local demo state.
                let existing = try await attendeeRef.getDocument(source: .server)
                if existing.exists {
                    try await attendeeRef.delete()
                } else {
                    try await attendeeRef.setData([
                        "userId": uid,
                        "createdAt": FieldValue.serverTimestamp()
                    ])
                }
                eventsError = nil
            } catch {
                eventsError = error.localizedDescription
                print("Events RSVP error: \(error.localizedDescription)")
            }
        }
    }
    // Admin-only event writes. Firestore rules independently verify the admin claim.
    @MainActor
    // Allow verified administrators to create or edit events and covers.
    func saveCommunityEvent(
        existing: BuildingEvent?, title: String, description: String,
        start: Date, end: Date, location: String, allowsRSVP: Bool,
        coverData: Data? = nil, removeCover: Bool = false
    ) async throws {
        guard onboardingStage == .admin, let user = Auth.auth().currentUser else {
            throw eventError("Administrator access required.")
        }
        let token = try await user.getIDTokenResult(forcingRefresh: true)
        guard token.claims["admin"] as? Bool == true else {
            throw eventError("Administrator permission was not verified.")
        }
        let name = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let details = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let place = location.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name.count <= 100,
              details.count <= 2000, !place.isEmpty, place.count <= 200,
              start > Date(), end > start else {
            throw eventError("Enter a title, location, future start time and a later end time.")
        }
        let db = Firestore.firestore()
        let eventRef: DocumentReference
        let action: String
        let batch = db.batch()
        if let existing {
            guard let id = existing.firestoreId, !id.isEmpty,
                  !existing.isCancelled else { throw eventError("This event cannot be edited.") }
            eventRef = db.collection("events").document(id)
            action = "updated"
            batch.updateData([
                "title": name, "description": details,
                "date": Timestamp(date: start), "endDate": Timestamp(date: end),
                "location": place, "allowsRSVP": allowsRSVP,
                "updatedAt": FieldValue.serverTimestamp()
            ], forDocument: eventRef)
        } else {
            eventRef = db.collection("events").document()
            action = "created"
            batch.setData([
                "title": name, "description": details,
                "date": Timestamp(date: start), "endDate": Timestamp(date: end),
                "location": place, "allowsRSVP": allowsRSVP,
                "status": "active", "createdBy": user.uid,
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
            ], forDocument: eventRef)
        }
        if let coverData {
            let base64 = coverData.base64EncodedString()
            guard !base64.isEmpty && base64.count <= 500_000 else {
                throw eventError("Event cover exceeds the photo size limit.")
            }
            batch.setData([
                "imageBase64": base64,
                "ownerUID": user.uid,
                "updatedAt": FieldValue.serverTimestamp()
            ], forDocument: db.collection("eventCovers").document(eventRef.documentID))
            batch.updateData(["coverId": eventRef.documentID], forDocument: eventRef)
        } else if removeCover, existing?.coverId != nil {
            batch.updateData(["coverId": FieldValue.delete()], forDocument: eventRef)
            batch.deleteDocument(db.collection("eventCovers").document(eventRef.documentID))
        }
        let notice = eventNoticeText(action: action, title: name, date: start, location: place)
        let noticeRef = db.collection("announcements").document()
        batch.setData([
            "text": notice, "createdAt": FieldValue.serverTimestamp(),
            "createdBy": user.uid, "isPinned": false,
            "eventId": eventRef.documentID, "eventAction": action
        ], forDocument: noticeRef)
        try await batch.commit()
    }
    @MainActor
    func cancelCommunityEvent(_ event: BuildingEvent) async throws {
        guard onboardingStage == .admin,
              let user = Auth.auth().currentUser,
              let id = event.firestoreId, !id.isEmpty,
              !event.isCancelled else { throw eventError("Cannot cancel this event.") }
        let token = try await user.getIDTokenResult(forcingRefresh: true)
        guard token.claims["admin"] as? Bool == true else {
            throw eventError("Administrator permission was not verified.")
        }
        let db = Firestore.firestore()
        let batch = db.batch()
        batch.updateData([
            "status": "cancelled", "updatedAt": FieldValue.serverTimestamp()
        ], forDocument: db.collection("events").document(id))
        let noticeRef = db.collection("announcements").document()
        batch.setData([
            "text": eventNoticeText(action: "cancelled", title: event.title,
                                    date: event.date, location: event.location),
            "createdAt": FieldValue.serverTimestamp(),
            "createdBy": user.uid, "isPinned": false,
            "eventId": id, "eventAction": "cancelled"
        ], forDocument: noticeRef)
        try await batch.commit()
    }
    private func eventNoticeText(action: String, title: String, date: Date,
                                 location: String) -> String {
        let when = date.formatted(date: .abbreviated, time: .shortened)
        switch action {
        case "created":
            return "📅 New community event: \(title)\nWhen: \(when)\nWhere: \(location)"
        case "updated":
            return "📝 Event updated: \(title)\nUpdated schedule: \(when)\nLocation: \(location)"
        default:
            return "❌ Event cancelled: \(title)\nOriginally scheduled: \(when)\nLocation: \(location)\nThis event will not take place."
        }
    }
    private func eventError(_ message: String) -> NSError {
        NSError(domain: "CommonsApp.Events", code: 400,
                userInfo: [NSLocalizedDescriptionKey: message])
    }
    // MARK: - Maintenance requests
    //Service Hub Actions
    // MARK: - Firebase maintenance requests
    // Residents query their own documents; admins query all documents.
    // Load maintenance requests based on resident or admin access.
    func startMaintenanceListener() {
        guard maintenanceListener == nil,
              onboardingStage == .active || onboardingStage == .admin,
              let uid = Auth.auth().currentUser?.uid else { return }
        let collection = Firestore.firestore().collection("maintenanceRequests")
        var query: Query = collection
        if onboardingStage != .admin {
            query = collection.whereField("residentId", isEqualTo: uid)
        }
        maintenanceListener = query.addSnapshotListener { [weak self] snapshot, error in
            Task { @MainActor [weak self] in
                guard let self, Auth.auth().currentUser?.uid == uid,
                      self.onboardingStage == .active || self.onboardingStage == .admin else { return }
                if let error {
                    self.maintenanceError = error.localizedDescription
                    return
                }
                self.maintenanceError = nil
                self.maintenanceRequests = (snapshot?.documents ?? []).compactMap { document in
                    let data = document.data()
                    guard let title = data["title"] as? String,
                          let details = data["details"] as? String,
                          let unit = data["unit"] as? String,
                          let residentId = data["residentId"] as? String,
                          let submittedAt = (data["submittedAt"] as? Timestamp)?.dateValue(),
                          let stageNumber = data["stage"] as? Int,
                          let stage = MaintenanceRequest.Stage(rawValue: stageNumber),
                          let id = UUID(uuidString: document.documentID) else { return nil }
                    return MaintenanceRequest(id: id, title: title, details: details,
                                              unit: unit, submittedAt: submittedAt,
                                              stage: stage, residentId: residentId,
                                              photoPath: data["photoPath"] as? String)
                }.sorted { $0.submittedAt > $1.submittedAt }
            }
        }
    }
    func stopMaintenanceListener() {
        maintenanceListener?.remove()
        maintenanceListener = nil
    }
    // Photos are analyzed on-device by Core ML and are never uploaded.
    // Only resident-reviewed title and description are stored in Firestore.
    @MainActor
    // Submit a maintenance request without uploading its local photo.
    func submitMaintenanceRequest(title: String, details: String, photoData: Data?) async throws {
        guard onboardingStage == .active,
              let user = Auth.auth().currentUser else {
            throw NSError(domain: "CommonsApp.Maintenance", code: 401,
                          userInfo: [NSLocalizedDescriptionKey: "Only approved residents can submit requests."])
        }
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanDetails = details.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty, cleanTitle.count <= 120,
              !cleanDetails.isEmpty, cleanDetails.count <= 2000 else {
            throw NSError(domain: "CommonsApp.Maintenance", code: 400,
                          userInfo: [NSLocalizedDescriptionKey: "Check the title and description lengths."])
        }
        // Keep the existing method signature so the SwiftUI form is unchanged.
        // The image remains only in the current on-device form session.
        _ = photoData
        let requestId = UUID().uuidString.lowercased()
        let fields: [String: Any] = [
            "title": cleanTitle, "details": cleanDetails,
            "unit": currentResident.unit, "residentId": user.uid,
            "submittedAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(), "stage": 0
        ]
        try await Firestore.firestore().collection("maintenanceRequests")
            .document(requestId).setData(fields)
    }
    @MainActor
    func advanceStage(of request: MaintenanceRequest) async throws {
        guard onboardingStage == .admin, Auth.auth().currentUser != nil else {
            throw NSError(domain: "CommonsApp.Maintenance", code: 403,
                          userInfo: [NSLocalizedDescriptionKey: "Administrator access required."])
        }
        guard request.stage != .complete else { return }
        try await Firestore.firestore().collection("maintenanceRequests")
            .document(request.id.uuidString.lowercased())
            .updateData(["stage": request.stage.rawValue + 1,
                         "updatedAt": FieldValue.serverTimestamp()])
    }
    // MARK: - Gym reservations
    // MARK: - Gym reservations. One document per administrator-created slot.
    // Membership is an array in that document; concurrent changes use transactions.
    @MainActor
    // Watch gym settings and available booking slots.
    func startGymListeners() {
        guard gymSlotsListener == nil, gymSettingsListener == nil,
              onboardingStage == .active || onboardingStage == .admin,
              let uid = Auth.auth().currentUser?.uid else { return }
        gymSettingsListener = Firestore.firestore().collection("gymSettings")
            .document("main").addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor [weak self] in
                    guard let self, Auth.auth().currentUser?.uid == uid else { return }
                    if let error { self.gymError = error.localizedDescription; return }
                    self.gymCapacity = max(1, snapshot?.data()?["capacity"] as? Int ?? 10)
                }
            }
        gymSlotsListener = Firestore.firestore().collection("gymSlots")
            .whereField("start", isGreaterThanOrEqualTo: Timestamp(date: Calendar.current.startOfDay(for: Date())))
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor [weak self] in
                    guard let self, Auth.auth().currentUser?.uid == uid else { return }
                    if let error { self.gymError = error.localizedDescription; return }
                    self.gymError = nil
                    let docs = snapshot?.documents ?? []
                    var occupancy: [String: Int] = [:]
                    var membersBySlot: [String: [String]] = [:]
                    var mySlotIDs: Set<String> = []
                    for document in docs {
                        let members = document.data()["members"] as? [String] ?? []
                        occupancy[document.documentID] = members.count
                        membersBySlot[document.documentID] = members
                        if members.contains(uid) {
                            mySlotIDs.insert(document.documentID)
                        }
                    }
                    self.gymOccupancy = occupancy
                    self.gymMembersBySlot = membersBySlot
                    self.gymMySlotIDs = mySlotIDs
                    let gymID = self.amenities.first(where: { $0.name == "Gym" })?.id ?? UUID()
                    self.bookingSlots = docs.compactMap { doc in
                        guard let start = (doc.data()["start"] as? Timestamp)?.dateValue() else { return nil }
                        return BookingSlot(amenityID: gymID, start: start, firestoreId: doc.documentID)
                    }.sorted { $0.start < $1.start }
                }
            }
    }
    func stopGymListeners() {
        gymSlotsListener?.remove(); gymSlotsListener = nil
        gymSettingsListener?.remove(); gymSettingsListener = nil
        gymOccupancy.removeAll(); gymMembersBySlot.removeAll()
        gymMySlotIDs.removeAll(); bookingSlots.removeAll()
    }
    @MainActor
    func setGymCapacity(_ capacity: Int) async throws {
        guard onboardingStage == .admin, (1...100).contains(capacity) else {
            throw gymFailure("Administrator access and a capacity of 1–100 are required.")
        }
        try await Firestore.firestore().collection("gymSettings")
            .document("main").setData(["capacity": capacity], merge: true)
    }
    // Admin creates the next 14 days of hourly slots, 9 AM–8 PM.
    // Existing slots are never overwritten (preserves reservations).
    @MainActor
    func prepareGymSlots() async throws {
        guard onboardingStage == .admin else { throw gymFailure("Administrator access required.") }
        let db = Firestore.firestore()
        let settings = db.collection("gymSettings").document("main")
        if !(try await settings.getDocument(source: .server)).exists {
            try await settings.setData(["capacity": 10])
        }
        let calendar = Calendar.current
        let collection = db.collection("gymSlots")
        let existing = try await collection
            .whereField("start", isGreaterThanOrEqualTo: Timestamp(date: Date()))
            .getDocuments(source: .server)
        let existingIDs = Set(existing.documents.map(\.documentID))
        let batch = db.batch()
        var newCount = 0
        for dayOffset in 0..<14 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset,
                                          to: calendar.startOfDay(for: Date())) else { continue }
            for hour in 9..<21 {
                guard let start = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day),
                      start > Date() else { continue }
                let key = gymSlotKey(start)
                guard !existingIDs.contains(key) else { continue }
                batch.setData([
                    "start": Timestamp(date: start), "members": [String](),
                    "updatedAt": FieldValue.serverTimestamp()
                ], forDocument: collection.document(key))
                newCount += 1
            }
        }
        if newCount > 0 { try await batch.commit() }
    }
    // Locale-independent document key shared by all devices.
    private func gymSlotKey(_ date: Date) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "Asia/Colombo")
        f.dateFormat = "yyyyMMddHH"
        return f.string(from: date)
    }
    @MainActor
    // Reserve or cancel a gym slot using a transaction.
    func reserveGymSlot(_ slot: BookingSlot, cancel: Bool = false) async throws {
        guard onboardingStage == .active, let uid = Auth.auth().currentUser?.uid,
              let id = slot.firestoreId, slot.start > Date() else {
            throw gymFailure("Please choose a future Gym slot while signed in as a resident.")
        }
        let db = Firestore.firestore()
        let ref = db.collection("gymSlots").document(id)
        let config = db.collection("gymSettings").document("main")
        _ = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                let setting = try transaction.getDocument(config)
                let snap = try transaction.getDocument(ref)
                guard let data = snap.data(),
                      let members = data["members"] as? [String],
                      let start = (data["start"] as? Timestamp)?.dateValue(),
                      start > Date() else { throw self.gymFailure("This slot is no longer available.") }
                let capacity = setting.data()?["capacity"] as? Int ?? 0
                var next = members
                if cancel {
                    guard members.contains(uid) else { throw self.gymFailure("No reservation to cancel.") }
                    next.removeAll { $0 == uid }
                } else {
                    guard !members.contains(uid) else { throw self.gymFailure("You already booked this slot.") }
                    guard members.count < capacity else { throw self.gymFailure("This Gym slot is full.") }
                    next.append(uid)
                }
                transaction.updateData([
                    "members": next, "updatedAt": FieldValue.serverTimestamp()
                ], forDocument: ref)
                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }
    func getSlots(for amenity: Amenity) -> [BookingSlot] {
        guard amenity.name == "Gym" else { return [] }
        return bookingSlots.filter { $0.amenityID == amenity.id && $0.start > Date() }
    }
    private func gymFailure(_ message: String) -> NSError {
        NSError(domain: "CommonsApp.Gym", code: 400,
                userInfo: [NSLocalizedDescriptionKey: message])
    }
    // MARK: - Sending chat messages
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
    // MARK: - Sample data and initial state
    //Sample Data Setup
    // Populate initial sample data used by the app.
    private func seedSampleData() {
        let now = Date()
        //Create sample posts
        posts = [
            Post(
                authorName: "Management",
                authorUnit: "—",
                timestamp: now,
                category: .announcement,
                text: "",
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
        // Events are loaded from Firestore.
        events = []
        //Create sample maintenance request
        maintenanceRequests = []
        //Create sample amenities
        amenities = [Amenity(name: "Gym", subtitle: "Reserve your workout time")]
        bookingSlots = []
        //Create sample pending residents
        pendingResidents = [
            PendingResident(id: "demo-priya", name: "Priya Nair", unit: "4B", requestedAt: now),
            PendingResident(id: "demo-tom", name: "Tom Alcott", unit: "11D", requestedAt: now)
        ]
        pinnedAnnouncementText = ""
        //Create offline cache items
        offlineCache = [
            OfflineCacheItem(label: "Door entry codes", isCached: true, lastSynced: now),
            OfflineCacheItem(label: "Emergency contacts", isCached: true, lastSynced: now),
            OfflineCacheItem(label: "Building Wall feed", isCached: true, lastSynced: now),
            OfflineCacheItem(label: "Photos & attachments", isCached: false, lastSynced: nil)
        ]
    }
    // MARK: - App lock timing and lifecycle
    func setAppLockDelay(_ seconds: Int) {
        let allowedValues = [0, 60, 300, 900]
        guard allowedValues.contains(seconds) else {
            return
        }
        appLockDelay = seconds
        UserDefaults.standard.set(
            seconds,
            forKey: appLockDelayPreferenceKey
        )
    }
    func appDidLeaveForeground() {
        guard appLockEnabled else {
            return
        }
        if appLeftForegroundAt == nil {
            appLeftForegroundAt = Date()
        }
        if appLockDelay == 0 {
            lockApp()
        }
    }
    func appDidBecomeActive() {
        guard appLockEnabled else {
            appLeftForegroundAt = nil
            return
        }
        guard let leftAt = appLeftForegroundAt else {
            return
        }
        let elapsedSeconds = Date().timeIntervalSince(leftAt)
        if elapsedSeconds >= Double(appLockDelay) {
            lockApp()
        }
        appLeftForegroundAt = nil
    }
    // MARK: - App lock and biometric security
    //App Lock (Face ID / Touch ID)
    func lockApp() {
        if appLockEnabled {
            isLocked = true
        }
    }
    func enableAppLock(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        ) else {
            DispatchQueue.main.async {
                completion(false)
            }
            return
        }
        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Enable biometric protection for Commons"
        ) { success, _ in
            DispatchQueue.main.async {
                if success {
                    self.appLockEnabled = true
                    self.isLocked = false
                    UserDefaults.standard.set(true, forKey: self.appLockPreferenceKey)
                }
                completion(success)
            }
        }
    }
    func disableAppLock(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(
            .deviceOwnerAuthentication,
            error: &error
        ) else {
            DispatchQueue.main.async {
                completion(false)
            }
            return
        }
        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: "Disable Commons app lock"
        ) { success, _ in
            DispatchQueue.main.async {
                if success {
                    self.appLockEnabled = false
                    self.isLocked = false
                    UserDefaults.standard.set(false, forKey: self.appLockPreferenceKey)
                }
                completion(success)
            }
        }
    }
    // MARK: - Home-screen widget data
    // Update information shared with the home-screen widget.
    func saveDataForWidget() {
        let sharedContainer = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.sohan.CommonsApp"
        )
        print(
            "WIDGET DEBUG: App Group container =",
            sharedContainer?.path ?? "UNAVAILABLE"
        )
        let defaults = UserDefaults(
            suiteName: "group.com.sohan.CommonsApp"
        )
        guard let defaults else {
            print("Widget shared storage is unavailable.")
            return
        }
        print("WIDGET DEBUG: Shared storage available")
        print("WIDGET DEBUG: Announcement =", pinnedAnnouncementText)
        print("WIDGET DEBUG: Events count =", events.count)
        // Save the latest announcement.
        defaults.set(
            pinnedAnnouncementText,
            forKey: "pinnedAnnouncement"
        )
        print(
            "WIDGET DEBUG: Read-back announcement =",
            defaults.string(forKey: "pinnedAnnouncement") ?? "nil"
        )
        // Find the next active upcoming event.
        let now = Date()
        let upcomingEvents = events
            .filter { !$0.isCancelled && $0.date >= now }
            .sorted { $0.date < $1.date }
        if let nextEvent = upcomingEvents.first {
            defaults.set(
                nextEvent.title,
                forKey: "nextEventTitle"
            )
            defaults.set(
                nextEvent.location,
                forKey: "nextEventLocation"
            )
        } else {
            // Clear previously saved event information.
            defaults.removeObject(forKey: "nextEventTitle")
            defaults.removeObject(forKey: "nextEventLocation")
        }
        // Request a widget timeline refresh.
        WidgetCenter.shared.reloadTimelines(
            ofKind: "CommonsAppWidget"
        )
    }
    func unlockWithBiometrics(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(
            .deviceOwnerAuthentication,
            error: &error
        ) else {
            DispatchQueue.main.async {
                completion(false)
            }
            return
        }
        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: "Unlock Commons"
        ) { success, _ in
            DispatchQueue.main.async {
                if success {
                    self.isLocked = false
                }
                completion(success)
            }
        }
    }
    // MARK: - Administrator announcements
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
            .limit(to: 50)
            .getDocuments()
        guard let document = snapshot.documents.first(where: { $0.data()["isPinned"] as? Bool != false }),
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
    // MARK: - Active chat and announcement listeners
    @MainActor
    func setActiveChat(_ chatId: String?) {
        activeChatId = chatId
        if chatId != nil {
            incomingChatNotification = nil
        }
    }
    //newest Firestore announcement and updates the Building Wall automatically
    // Keep the latest administrator announcements synchronized.
    func startAnnouncementListener() {
        // Prevent duplicate listeners.
        guard announcementListener == nil else { return }
        guard Auth.auth().currentUser != nil else { return }
        announcementListener = Firestore.firestore()
            .collection("announcements")
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Announcement listener error: \(error.localizedDescription)")
                    return
                }
                guard let documents = snapshot?.documents else { return }
                let pinned = documents.first { $0.data()["isPinned"] as? Bool != false }
                let notices: [Post] = documents.compactMap { document in
                    let data = document.data()
                    guard data["eventAction"] as? String != nil,
                          let message = data["text"] as? String else { return nil }
                    return Post(
                        authorName: "Management", authorUnit: "",
                        timestamp: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                        category: .announcement, text: message
                    )
                }
                Task { @MainActor in
                    guard let self = self else { return }
                    self.eventNoticePosts = notices
                    if let pinned,
                       let message = pinned.data()["text"] as? String {
                        let timestamp = (pinned.data()["createdAt"] as? Timestamp)?
                            .dateValue() ?? Date()
                        self.pinnedAnnouncementText = message
                        let announcementPost = Post(
                            authorName: "Management", authorUnit: "—",
                            timestamp: timestamp, category: .announcement,
                            text: message, isPinned: true
                        )
                        self.posts.removeAll { $0.isPinned }
                        self.posts.insert(announcementPost, at: 0)
                        self.saveDataForWidget()
                    } else {
                        self.pinnedAnnouncementText = ""
                        self.posts.removeAll { $0.isPinned }
                    }
                }
            }
    }
    struct ChatNotification: Identifiable {
        let id: String
        let chatId: String
        let senderName: String
        let message: String
    }
    func stopAnnouncementListener() {
        announcementListener?.remove()
        announcementListener = nil
    }
    // MARK: - Resident profile updates
    // Edit approved resident details without changing approval or unit assignment.
    @MainActor
    func updateResidentPersonalDetails(name: String, phone: String, showUnit: Bool) async throws {
        guard onboardingStage == .active, let user = Auth.auth().currentUser else {
            throw NSError(domain: "CommonsApp.Profile", code: 401,
                          userInfo: [NSLocalizedDescriptionKey: "Please sign in as an approved resident."])
        }
        let updatedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let updatedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !updatedName.isEmpty, updatedName.count <= 100 else {
            throw NSError(domain: "CommonsApp.Profile", code: 400,
                          userInfo: [NSLocalizedDescriptionKey: "Enter a name between 1 and 100 characters."])
        }
        guard updatedPhone.count <= 30 else {
            throw NSError(domain: "CommonsApp.Profile", code: 400,
                          userInfo: [NSLocalizedDescriptionKey: "Phone number must be 30 characters or fewer."])
        }
        let reference = Firestore.firestore().collection("users").document(user.uid)
        let snapshot = try await reference.getDocument(source: .server)
        guard let data = snapshot.data(), data["approvalStatus"] as? String == "approved" else {
            throw NSError(domain: "CommonsApp.Profile", code: 403,
                          userInfo: [NSLocalizedDescriptionKey: "An approved resident account is required."])
        }
        try await reference.updateData([
            "name": updatedName,
            "phone": updatedPhone,
            "showUnitToNeighbors": showUnit
        ])
        currentResident.name = updatedName
        currentResident.phone = updatedPhone
        currentResident.showUnitToNeighbors = showUnit
    }
}
