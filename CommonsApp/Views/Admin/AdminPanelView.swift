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
                                Button("Pin to Building Wall") {
                                    pinAnnouncement()
                                }
                                .buttonStyle(PrimaryButtonStyle())
                                .disabled(announcementText.isEmpty)
                                .opacity(announcementText.isEmpty ? 0.5 : 1)
                                
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
                                number: "\(store.chatThreads.count)",
                                label: "Active Chats"
                            )
                            StatCard(
                                number: "\(store.events.count)",
                                label: "Upcoming Events"
                            )
                            StatCard(
                                number: "\(store.maintenanceRequests.count)",
                                label: "Open Requests"
                            )
                            StatCard(
                                number: "\(store.items.count)",
                                label: "Shared Items"
                            )
                        }
                    }
                }
                .padding(16)
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
        store.pinAnnouncement(announcementText)
        didPin = true
        announcementText = ""
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
