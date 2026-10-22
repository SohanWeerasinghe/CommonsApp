//

//  AdminPanelView.swift

//  CommonsApp

//

//  Created by Sohan Weerasinghe on 21/9/2026.

//



import SwiftUI



struct AdminPanelView: View {



    @EnvironmentObject var store: AppStore



    // Holds the text typed into the announcement box

    @State private var announcementText = ""



    // Shows a confirmation message after pinning

    @State private var didPin = false

    @State private var isLoadingResidents = false

    @State private var residentsError = ""

    @State private var processingResidentID: String? = nil

    @State private var isSavingAnnouncement = false

    @State private var announcementError = ""
    @State private var showCreateEvent = false
    @State private var editingEvent: BuildingEvent?



    var body: some View {

        ZStack {

            Theme.paper.ignoresSafeArea()



            ScrollView {

                VStack(alignment: .leading, spacing: 24) {



                    // MARK: Pending residents section

                    VStack(alignment: .leading, spacing: 12) {



                        SectionHeader(title: "Pending Verification")



                        // Empty state

                        if store.pendingResidents.isEmpty {

                            PlaqueCard {

                                HStack(spacing: 12) {

                                    Image(systemName: "checkmark.seal.fill")

                                        .foregroundStyle(Theme.sage)

                                        .font(.system(size: 24))



                                    Text("All residents verified")

                                        .font(Theme.ui(14))

                                        .foregroundStyle(Theme.textMuted)

                                }

                            }



                        } else {



                            ForEach(store.pendingResidents) { resident in

                                PlaqueCard {

                                    VStack(alignment: .leading, spacing: 6) {

                                        Text(resident.name)

                                            .font(Theme.ui(15, weight: .semibold))

                                            .foregroundStyle(Theme.textPrimary)



                                        Text("Unit: \\(resident.unit)")

                                            .font(Theme.ui(13))

                                            .foregroundStyle(Theme.textMuted)



                                        Text("Application pending")

                                            .font(Theme.ui(12))



                                            .foregroundStyle(Theme.textMuted)



                                        //Approve decline buttons for pending residents

                                        HStack(spacing: 12) {

                                            Button("Approve") {

                                                guard processingResidentID == nil else { return }



                                                processingResidentID = resident.id

                                                residentsError = ""



                                                Task {

                                                    defer { processingResidentID = nil }



                                                    do {

                                                        try await store.updateResidentApproval(

                                                            residentID: resident.id,

                                                            approve: true

                                                        )

                                                    } catch {

                                                        residentsError = error.localizedDescription

                                                    }

                                                }

                                            }

                                            .buttonStyle(.borderedProminent)

                                            .tint(.green)

                                            .disabled(processingResidentID != nil)



                                            Button("Decline") {

                                                guard processingResidentID == nil else { return }



                                                processingResidentID = resident.id

                                                residentsError = ""



                                                Task {

                                                    defer { processingResidentID = nil }



                                                    do {

                                                        try await store.updateResidentApproval(

                                                            residentID: resident.id,

                                                            approve: false

                                                        )

                                                    } catch {

                                                        residentsError = error.localizedDescription

                                                    }

                                                }

                                            }

                                            .buttonStyle(.bordered)

                                            .tint(.red)

                                            .disabled(processingResidentID != nil)



                                            if processingResidentID == resident.id {

                                                ProgressView()

                                            }

                                        }

                                        .padding(.top, 8)

                                    }

                                    .frame(maxWidth: .infinity, alignment: .leading)

                                }

                                if isLoadingResidents {

                                    ProgressView("Loading resident applications...")

                                }



                                if !residentsError.isEmpty {

                                    Text(residentsError)

                                        .font(.caption)

                                        .foregroundStyle(.red)

                                }

                            }

                        }

                    }



                    // MARK: Pin announcement section

                    VStack(alignment: .leading, spacing: 12) {



                        SectionHeader(title: "Pin Announcement")



                        PlaqueCard {

                            VStack(alignment: .leading, spacing: 14) {



                                // Current pinned announcement

                                if !store.pinnedAnnouncementText.isEmpty {

                                    VStack(alignment: .leading, spacing: 6) {

                                        Text("CURRENTLY PINNED")

                                            .font(Theme.ui(10, weight: .semibold))

                                            .foregroundStyle(Theme.textMuted)



                                        Text(store.pinnedAnnouncementText)

                                            .font(Theme.ui(13))

                                            .foregroundStyle(Theme.textPrimary)

                                    }

                                    .padding(12)

                                    .frame(maxWidth: .infinity, alignment: .leading)

                                    .background(Theme.clay.opacity(0.1))

                                    .clipShape(RoundedRectangle(cornerRadius: 8))



                                    Divider()

                                }



                                // New announcement text box

                                Text("NEW ANNOUNCEMENT")

                                    .font(Theme.ui(10, weight: .semibold))

                                    .foregroundStyle(Theme.textMuted)



                                TextEditor(text: $announcementText)

                                    .frame(height: 100)

                                    .padding(8)

                                    .scrollContentBackground(.hidden)

                                    .background(Theme.paper)

                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                    .overlay(

                                        RoundedRectangle(cornerRadius: 8)

                                            .stroke(Theme.hairline, lineWidth: 1)

                                    )



                                // Pin button

                                Button {

                                    pinAnnouncement()

                                } label: {

                                    HStack(spacing: 8) {

                                        if isSavingAnnouncement {

                                            ProgressView()

                                        }



                                        Text(isSavingAnnouncement ? "Saving..." : "Pin to Building Wall")

                                    }

                                }

                                .buttonStyle(PrimaryButtonStyle())

                                .disabled(

                                    isSavingAnnouncement ||

                                    announcementText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

                                )

                                .opacity(

                                    isSavingAnnouncement ||

                                    announcementText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

                                    ? 0.5 : 1

                                )



                                if !announcementError.isEmpty {

                                    Text(announcementError)

                                        .font(Theme.ui(12))

                                        .foregroundStyle(.red)

                                }



                                // Success confirmation

                                if didPin {

                                    HStack(spacing: 6) {

                                        Image(systemName: "checkmark.circle.fill")

                                            .foregroundStyle(Theme.sage)

                                        Text("Pinned to the Building Wall")

                                            .font(Theme.ui(13))

                                            .foregroundStyle(Theme.sage)

                                    }

                                }

                            }

                        }

                    }



                    // MARK: Community events management
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Manage Events")

                        Button {
                            showCreateEvent = true
                        } label: {
                            Label("Create Event", systemImage: "plus.circle.fill")
                                .font(Theme.ui(15, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.brass)

                        if store.events.isEmpty {
                            PlaqueCard {
                                Text("No community events yet. Create your first event.")
                                    .font(Theme.ui(13))
                                    .foregroundStyle(Theme.textMuted)
                            }
                        } else {
                            ForEach(store.events.sorted(by: { $0.date > $1.date })) { event in
                                PlaqueCard {
                                    VStack(alignment: .leading, spacing: 10) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 5) {
                                                Text(event.title)
                                                    .font(Theme.ui(15, weight: .semibold))
                                                Text(event.date.formatted(date: .abbreviated, time: .shortened))
                                                    .font(Theme.ui(12))
                                                    .foregroundStyle(Theme.textMuted)
                                                Text(event.location)
                                                    .font(Theme.ui(12))
                                                    .foregroundStyle(Theme.textMuted)
                                            }
                                            Spacer()
                                            if event.isCancelled {
                                                Text("Cancelled")
                                                    .font(.caption.bold())
                                                    .foregroundStyle(.red)
                                            }
                                        }
                                        HStack {
                                            Label("\(event.attendeeCount) going", systemImage: "person.2")
                                                .font(Theme.ui(12))
                                            Spacer()
                                            if !event.isCancelled && event.firestoreId != nil {
                                                Button("Edit") { editingEvent = event }
                                                    .buttonStyle(.bordered)
                                            }
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }

                    // MARK: Building stats section

                    VStack(alignment: .leading, spacing: 12) {



                        SectionHeader(title: "Building Overview")



                        // Stats in a 2 column grid

                        LazyVGrid(

                            columns: [

                                GridItem(.flexible()),

                                GridItem(.flexible())

                            ],

                            spacing: 12

                        ) {

                            StatCard(

                                number: "\\(store.chatThreads.count)",

                                label: "Active Chats"

                            )

                            StatCard(

                                number: "\\(store.events.count)",

                                label: "Upcoming Events"

                            )

                            StatCard(

                                number: "\\(store.maintenanceRequests.count)",

                                label: "Open Requests"

                            )

                            StatCard(

                                number: "\\(store.items.count)",

                                label: "Shared Items"

                            )

                        }

                    }

                }

                .padding(16)

            }

        }

        .sheet(isPresented: $showCreateEvent) {
            NavigationStack {
                CommunityEventEditor(existing: nil)
                    .environmentObject(store)
            }
        }
        .sheet(item: $editingEvent) { event in
            NavigationStack {
                CommunityEventEditor(existing: event)
                    .environmentObject(store)
            }
        }
        .navigationTitle("Admin Panel")

        .navigationBarTitleDisplayMode(.large)

        .task {

            isLoadingResidents = true

            residentsError = ""



            // Clear sample residents before loading real applications.

            store.pendingResidents = []



            defer {

                isLoadingResidents = false

            }



            do {

                try await store.loadPendingResidents()

            } catch {

                residentsError = error.localizedDescription

            }

        }

    }



    // Pins the announcement to the building wall

    func pinAnnouncement() {

        let text = announcementText.trimmingCharacters(

            in: .whitespacesAndNewlines

        )



        guard !text.isEmpty, !isSavingAnnouncement else { return }



        isSavingAnnouncement = true

        announcementError = ""

        didPin = false



        Task {

            defer {

                isSavingAnnouncement = false

            }



            do {

                try await store.saveAnnouncementToFirestore(text)



                // Preserve the existing Building Wall and widget behavior.

                store.pinAnnouncement(text)



                didPin = true

                announcementText = ""



            } catch {

                announcementError = error.localizedDescription

            }

        }

    }



    // Small stat box showing a number and a label

    private struct StatCard: View {



        let number: String

        let label: String



        var body: some View {

            VStack(spacing: 6) {

                Text(number)

                    .font(Theme.display(28))

                    .foregroundStyle(Theme.brass)



                Text(label)

                    .font(Theme.ui(11.5))

                    .foregroundStyle(Theme.textMuted)

                    .multilineTextAlignment(.center)

            }

            .frame(maxWidth: .infinity)

            .padding(16)

            .background(Theme.card)

            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))

            .overlay(

                RoundedRectangle(cornerRadius: Theme.cardRadius)

                    .stroke(Theme.hairline, lineWidth: 1)

            )

        }

    }

}
