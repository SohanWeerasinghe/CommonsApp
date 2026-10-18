//
//  AdminPanelView.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 21/9/2026.
//

import SwiftUI

private enum AdminPalette {
    static let ink = Color(red: 0.10, green: 0.14, blue: 0.26)
    static let muted = Color(red: 0.44, green: 0.49, blue: 0.60)
    static let purple = Color(red: 0.40, green: 0.32, blue: 0.87)
    static let background = Color(red: 0.965, green: 0.970, blue: 0.985)
    static let border = Color(red: 0.90, green: 0.92, blue: 0.95)
}

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
            AdminPalette.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    dashboardHeader
                    dashboardOverview

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
                                        Text("Unit: \(resident.unit)")
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
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Manage Events")
                                    .font(.system(size: 19, weight: .bold, design: .rounded))
                                    .foregroundStyle(AdminPalette.ink)
                                Text("Create and manage community events")
                                    .font(.system(size: 12))
                                    .foregroundStyle(AdminPalette.muted)
                            }
                            Spacer(minLength: 0)
                            Button { showCreateEvent = true } label: {
                                Label("Create", systemImage: "plus")
                                    .font(.system(size: 13, weight: .semibold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 11)
                                    .foregroundStyle(.white)
                                    .background(AdminPalette.purple, in: Capsule())
                            }
                        }
                        if store.events.isEmpty {
                            VStack(spacing: 9) {
                                Image(systemName: "calendar.badge.plus")
                                    .font(.system(size: 28))
                                    .foregroundStyle(AdminPalette.purple)
                                Text("No events created yet")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(AdminPalette.ink)
                                Text("Create your first community event to get started.")
                                    .font(.system(size: 12))
                                    .foregroundStyle(AdminPalette.muted)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 28)
                            .background(.white, in: RoundedRectangle(cornerRadius: 20))
                        } else {
                            ForEach(store.events.sorted(by: { $0.date > $1.date })) { event in
                                HStack(alignment: .top, spacing: 12) {
                                    VStack(spacing: 3) {
                                        Text(event.date.formatted(.dateTime.month(.abbreviated)).uppercased())
                                            .font(.system(size: 10, weight: .bold))
                                        Text(event.date.formatted(.dateTime.day()))
                                            .font(.system(size: 24, weight: .bold, design: .rounded))
                                    }
                                    .foregroundStyle(AdminPalette.purple)
                                    .frame(width: 58, height: 64)
                                    .background(AdminPalette.purple.opacity(0.09), in: RoundedRectangle(cornerRadius: 14))
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(event.title)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(AdminPalette.ink)
                                        Label(event.location, systemImage: "mappin")
                                        Label(event.date.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                                        Label("\(event.attendeeCount) attending", systemImage: "person.2")
                                    }
                                    .font(.system(size: 11))
                                    .foregroundStyle(AdminPalette.muted)
                                    Spacer(minLength: 0)
                                    VStack(alignment: .trailing, spacing: 10) {
                                        Text(event.isCancelled ? "CANCELLED" : "ACTIVE")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(event.isCancelled ? Color.red : Color.green)
                                        if !event.isCancelled && event.firestoreId != nil {
                                            Button { editingEvent = event } label: {
                                                Image(systemName: "pencil")
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundStyle(AdminPalette.purple)
                                                    .frame(width: 36, height: 36)
                                                    .background(AdminPalette.background, in: RoundedRectangle(cornerRadius: 11))
                                            }
                                            .accessibilityLabel("Edit \(event.title)")
                                        }
                                    }
                                }
                                .padding(14)
                                .background(.white, in: RoundedRectangle(cornerRadius: 19))
                                .overlay(RoundedRectangle(cornerRadius: 19).stroke(AdminPalette.border))
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 36)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
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
    private var dashboardHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "building.2.crop.circle.fill")
                .font(.system(size: 35))
                .foregroundStyle(AdminPalette.purple)
                .frame(width: 54, height: 54)
                .background(.white, in: RoundedRectangle(cornerRadius: 17))
            VStack(alignment: .leading, spacing: 3) {
                Text("Admin Dashboard")
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .foregroundStyle(AdminPalette.ink)
                Text("Manage your community")
                    .font(.system(size: 13))
                    .foregroundStyle(AdminPalette.muted)
            }
            Spacer(minLength: 0)
        }
    }

    private var dashboardOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Building Overview")
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(AdminPalette.ink)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                metric("Active Chats", store.chatThreads.count, "bubble.left.and.bubble.right.fill", .blue)
                metric("Upcoming Events", store.events.filter { !$0.isCancelled && $0.date >= Date() }.count, "calendar", AdminPalette.purple)
                metric("Open Requests", store.maintenanceRequests.count, "wrench.and.screwdriver.fill", .orange)
                metric("Shared Items", store.items.count, "shippingbox.fill", .green)
            }
        }
    }

    private func metric(_ label: String, _ count: Int, _ symbol: String, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 38, height: 38)
                .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
            Text("\(count)")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(AdminPalette.ink)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AdminPalette.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(AdminPalette.border))
    }
}
