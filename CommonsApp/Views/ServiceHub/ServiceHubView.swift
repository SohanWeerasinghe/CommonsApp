//
//  ServiceHubView.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 21/9/2026.
//

import SwiftUI

struct ServiceHubView: View {

    @EnvironmentObject var store: AppStore

    @State private var showNewRequest = false
    @State private var showAmenities = false
    @State private var showSettings = false
    @State private var showContacts = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.wallBackgroundTop, Theme.wallBackgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // Header
                    Text("SERVICE HUB")
                        .font(Theme.ui(10, weight: .bold))
                        .foregroundStyle(Theme.appMuted)
                        .tracking(1.2)

                    Text("Home services")
                        .font(Theme.display(28, weight: .bold))
                        .foregroundStyle(Theme.appNavy)
                        .padding(.top, 5)

                    // Services
                    Text("What do you need?")
                        .font(Theme.display(17, weight: .bold))
                        .foregroundStyle(Theme.appNavy)
                        .padding(.top, 24)

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ],
                        spacing: 12
                    ) {
                        Button {
                            showNewRequest = true
                        } label: {
                            ServiceButton(
                                title: "Report issue",
                                subtitle: "Maintenance",
                                icon: "exclamationmark.triangle.fill",
                                iconColor: Theme.danger,
                                iconBackground: Theme.danger.opacity(0.12)
                            )
                        }
                        .buttonStyle(.plain)

                        Button {
                            showAmenities = true
                        } label: {
                            ServiceButton(
                                title: "Book amenity",
                                subtitle: "Shared spaces",
                                icon: "calendar",
                                iconColor: Theme.appPurple,
                                iconBackground: Theme.appPurpleSoft
                            )
                        }
                        .buttonStyle(.plain)

                        Button {
                            showSettings = true
                        } label: {
                            ServiceButton(
                                title: "Settings",
                                subtitle: "Preferences",
                                icon: "gearshape.fill",
                                iconColor: Theme.appGreen,
                                iconBackground: Theme.appGreenSoft
                            )
                        }
                        .buttonStyle(.plain)

                        Button {
                            showContacts = true
                        } label: {
                            ServiceButton(
                                title: "Contacts",
                                subtitle: "Building team",
                                icon: "phone.fill",
                                iconColor: Theme.info,
                                iconBackground: Theme.info.opacity(0.12)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 14)

                    // Requests
                    HStack {
                        Text("Your requests")
                            .font(Theme.display(17, weight: .bold))
                            .foregroundStyle(Theme.appNavy)

                        Spacer()

                        if !store.maintenanceRequests.isEmpty {
                            Text("\(store.maintenanceRequests.count)")
                                .font(Theme.ui(11, weight: .bold))
                                .foregroundStyle(Theme.appPurple)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Theme.appPurpleSoft)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.top, 28)

                    if store.maintenanceRequests.isEmpty {
                        AppEmptyState(
                            icon: "wrench.and.screwdriver",
                            title: "No requests yet",
                            message: "Maintenance requests you submit will appear here."
                        )
                        .padding(.top, 16)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(store.maintenanceRequests) { request in
                                RequestCard(request: request)
                            }
                        }
                        .padding(.top, 14)
                    }
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.top, 12)
                .padding(.bottom, 125)
            }
            .scrollIndicators(.hidden)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showNewRequest) {
            NewMaintenanceRequestView()
                .environmentObject(store)
        }
        .sheet(isPresented: $showAmenities) {
            AmenitiesListView()
                .environmentObject(store)
        }
        .sheet(isPresented: $showSettings) {
            SimpleSettingsView()
        }
        .sheet(isPresented: $showContacts) {
            SimpleContactsView()
        }
    }
}

private struct ServiceButton: View {

    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let iconBackground: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(iconBackground)
                    .frame(width: 42, height: 42)

                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            Spacer()

            Text(title)
                .font(Theme.ui(14, weight: .bold))
                .foregroundStyle(Theme.appNavy)

            Text(subtitle)
                .font(Theme.ui(10))
                .foregroundStyle(Theme.appMuted)
                .padding(.top, 3)
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 128)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Theme.appBorder, lineWidth: 1)
        }
    }
}
private struct RequestCard: View {

    let request: MaintenanceRequest

    var body: some View {
        HStack(spacing: 13) {
            ZStack {
                Circle()
                    .fill(statusColor().opacity(0.12))
                    .frame(width: 42, height: 42)

                Circle()
                    .fill(statusColor())
                    .frame(width: 10, height: 10)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(request.title)
                    .font(Theme.ui(14, weight: .bold))
                    .foregroundStyle(Theme.appNavy)
                    .lineLimit(1)

                Text(request.stage.label)
                    .font(Theme.ui(11, weight: .medium))
                    .foregroundStyle(statusColor())
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Theme.appTertiary)
        }
        .padding(15)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 74)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(Theme.appBorder, lineWidth: 1)
        }
    }

    func statusColor() -> Color {
        if request.stage == .complete {
            return Theme.appGreen
        } else {
            return Theme.info
        }
    }
}
private struct AmenitiesListView: View {

    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss

    var body: some View {

        NavigationStack {

            ZStack {

                Color(
                    red: 0.97,
                    green: 0.97,
                    blue: 0.96
                )
                .ignoresSafeArea()

                ScrollView {

                    VStack(spacing: 14) {

                        ForEach(store.amenities) { amenity in

                            NavigationLink {
                                AmenityBookingView(
                                    amenity: amenity
                                )
                            } label: {

                                HStack {

                                    VStack(alignment: .leading, spacing: 5) {

                                        Text(amenity.name)
                                            .font(
                                                .system(
                                                    size: 15,
                                                    weight: .semibold
                                                )
                                            )
                                            .foregroundStyle(.primary)

                                        Text(amenity.subtitle)
                                            .font(.system(size: 12))
                                            .foregroundStyle(.gray)
                                    }

                                    Spacer()

                                    Image(
                                        systemName: "chevron.right"
                                    )
                                    .foregroundStyle(.gray)
                                }
                                .padding(16)
                                .background(.white)
                                .clipShape(
                                    RoundedRectangle(
                                        cornerRadius: 16
                                    )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Book amenity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(
                    placement: .topBarLeading
                ) {

                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}
private struct SimpleSettingsView: View {

    @Environment(\.dismiss) var dismiss

    var body: some View {

        NavigationStack {

            ZStack {

                Color(
                    red: 0.97,
                    green: 0.97,
                    blue: 0.96
                )
                .ignoresSafeArea()

                VStack {

                    Text("Service settings")
                        .font(.system(size: 20, weight: .bold))

                    Text("Settings can be managed here.")
                        .font(.system(size: 14))
                        .foregroundStyle(.gray)
                        .padding(.top, 8)

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(
                    placement: .topBarLeading
                ) {

                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}


private struct SimpleContactsView: View {

    @Environment(\.dismiss) var dismiss

    var body: some View {

        NavigationStack {

            ZStack {

                Color(
                    red: 0.97,
                    green: 0.97,
                    blue: 0.96
                )
                .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 18) {

                    HStack(spacing: 14) {

                        Image(systemName: "person.fill")
                            .foregroundStyle(.blue)

                        VStack(alignment: .leading, spacing: 4) {

                            Text("Building Management")
                                .font(
                                    .system(
                                        size: 15,
                                        weight: .semibold
                                    )
                                )

                            Text("Contact the management team")
                                .font(.system(size: 12))
                                .foregroundStyle(.gray)
                        }
                    }

                    Divider()

                    HStack(spacing: 14) {

                        Image(systemName: "wrench.fill")
                            .foregroundStyle(.orange)

                        VStack(alignment: .leading, spacing: 4) {

                            Text("Maintenance")
                                .font(
                                    .system(
                                        size: 15,
                                        weight: .semibold
                                    )
                                )

                            Text("Maintenance support")
                                .font(.system(size: 12))
                                .foregroundStyle(.gray)
                        }
                    }

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Contacts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(
                    placement: .topBarLeading
                ) {

                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ServiceHubView()
        .environmentObject(AppStore())
}
