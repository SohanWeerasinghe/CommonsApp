//
//  CommonsSiriIntents.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 22/10/2026.
//


import AppIntents
import FirebaseAuth
import FirebaseFirestore

// MARK: - Community Wall

struct OpenCommunityWallIntent: AppIntent {

    static var title: LocalizedStringResource = "Open Community Wall"

    static var description = IntentDescription(
        "Open the community wall in CommonsApp."
    )

    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        SiriNavigation.shared.open(.wall)
        return .result()
    }
}

// MARK: - Messages

struct OpenCommonsMessagesIntent: AppIntent {

    static var title: LocalizedStringResource = "Open Commons Messages"

    static var description = IntentDescription(
        "Open resident messages in CommonsApp."
    )

    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        SiriNavigation.shared.open(.chat)
        return .result()
    }
}

// MARK: - Events

struct OpenCommonsEventsIntent: AppIntent {

    static var title: LocalizedStringResource = "Open Community Events"

    static var description = IntentDescription(
        "Open community events in CommonsApp."
    )

    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        SiriNavigation.shared.open(.events)
        return .result()
    }
}

// MARK: - Siri Shortcuts

struct CommonsAppShortcuts: AppShortcutsProvider {

    static var appShortcuts: [AppShortcut] {

        AppShortcut(
            intent: OpenCommunityWallIntent(),
            phrases: [
                "Open community wall in \(.applicationName)",
                "Show my community wall in \(.applicationName)"
            ],
            shortTitle: "Community Wall",
            systemImageName: "house.fill"
        )

        AppShortcut(
            intent: OpenCommonsMessagesIntent(),
            phrases: [
                "Open messages in \(.applicationName)",
                "Show my messages in \(.applicationName)"
            ],
            shortTitle: "Messages",
            systemImageName: "message.fill"
        )

        AppShortcut(
            intent: OpenCommonsEventsIntent(),
            phrases: [
                "Open events in \(.applicationName)",
                "Show community events in \(.applicationName)"
            ],
            shortTitle: "Community Events",
            systemImageName: "calendar"
        )
        
        AppShortcut(
            intent: UpcomingCommunityEventsIntent(),
            phrases: [
                "What's coming up in \(.applicationName)",
                "What community events are coming up in \(.applicationName)",
                "Tell me the next event in \(.applicationName)"
            ],
            shortTitle: "Upcoming Event",
            systemImageName: "calendar.badge.clock"
        )

    }
    
    
    // MARK: - Read Upcoming Community Event

   struct UpcomingCommunityEventsIntent: AppIntent {

       static var title: LocalizedStringResource =
           "What's Coming Up in CommonsApp"

       static var description = IntentDescription(
           "Find and read the next upcoming community event."
       )

       // Siri can respond without opening the app.
       static var openAppWhenRun: Bool = false

       @MainActor
       func perform() async throws -> some IntentResult & ProvidesDialog {

           guard let user = Auth.auth().currentUser else {
               return .result(
                   dialog: "Please sign in to CommonsApp to check community events."
               )
           }

           do {
               // Verify the current account.
               try await user.reload()

               let token = try await user.getIDTokenResult(
                   forcingRefresh: true
               )

               let isAdmin = token.claims["admin"] as? Bool == true

               if !isAdmin {

                   guard user.isEmailVerified else {
                       return .result(
                           dialog: "Please verify your email in CommonsApp first."
                       )
                   }

                   let profile = try await Firestore.firestore()
                       .collection("users")
                       .document(user.uid)
                       .getDocument(source: .server)

                   guard profile.exists,
                         let data = profile.data(),
                         data["approvalStatus"] as? String == "approved"
                   else {
                       return .result(
                           dialog: "Your CommonsApp account must be approved before you can access community events."
                       )
                   }
               }

               // Retrieve current events from Firestore.
               let snapshot = try await Firestore.firestore()
                   .collection("events")
                   .getDocuments(source: .server)

               let now = Date()

               var upcomingEvents: [(title: String, date: Date, location: String)] = []

               for document in snapshot.documents {

                   let data = document.data()

                   guard let title = data["title"] as? String,
                         let timestamp = data["date"] as? Timestamp,
                         let location = data["location"] as? String,
                         let status = data["status"] as? String
                   else {
                       continue
                   }

                   let eventDate = timestamp.dateValue()

                   if status == "active" && eventDate >= now {
                       upcomingEvents.append((
                           title: title,
                           date: eventDate,
                           location: location
                       ))
                   }
               }

               upcomingEvents.sort {
                   $0.date < $1.date
               }

               guard let nextEvent = upcomingEvents.first else {
                   return .result(
                       dialog: "There are no upcoming community events scheduled in CommonsApp."
                   )
               }

               let dateFormatter = DateFormatter()
               dateFormatter.dateStyle = .full
               dateFormatter.timeStyle = .short

               let dateText = dateFormatter.string(
                   from: nextEvent.date
               )

               let message = """
               Your next community event is \(nextEvent.title), \
               on \(dateText), at \(nextEvent.location).
               """

               return .result(
                   dialog: IntentDialog(stringLiteral: message)
               )

           } catch {
               return .result(
                   dialog: "I couldn't retrieve community events right now. Please open CommonsApp and try again."
               )
           }
       }
   }

}

