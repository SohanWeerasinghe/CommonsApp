// ServiceHubView.swift — CommonsApp service dashboard redesign
import SwiftUI

struct ServiceHubView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showNewRequest = false
    @State private var showAmenities = false
    @State private var showSettings = false
    @State private var showContacts = false

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.wallBackgroundTop, Theme.wallBackgroundBottom], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    spotlight
                    HStack {
                        Text("Explore services")
                            .font(Theme.display(21, weight: .bold))
                            .foregroundStyle(Theme.appNavy)
                        Spacer()
                        Text("EVERYDAY ESSENTIALS")
                            .font(Theme.ui(9, weight: .bold))
                            .tracking(0.8)
                            .foregroundStyle(Theme.appMuted)
                    }
                    LazyVGrid(columns: columns, spacing: 12) {
                        Button { showNewRequest = true } label: {
                            ServiceTile(title: "Report an issue", subtitle: "Get maintenance help", icon: "wrench.adjustable.fill", accent: Theme.danger, surface: Theme.danger.opacity(0.10))
                        }
                        Button { showAmenities = true } label: {
                            ServiceTile(title: "Book a space", subtitle: "Amenities & facilities", icon: "calendar.badge.clock", accent: Theme.appPurple, surface: Theme.appPurpleSoft)
                        }
                        Button { showSettings = true } label: {
                            ServiceTile(title: "Preferences", subtitle: "Manage your account", icon: "slider.horizontal.3", accent: Theme.appGreen, surface: Theme.appGreenSoft)
                        }
                        Button { showContacts = true } label: {
                            ServiceTile(title: "Get in touch", subtitle: "Building contacts", icon: "phone.arrow.up.right.fill", accent: Theme.info, surface: Theme.info.opacity(0.10))
                        }
                    }
                    .buttonStyle(.plain)
                    requestsSection
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.top, 12)
                .padding(.bottom, 140)
            }
            .scrollIndicators(.hidden)
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showNewRequest) { NewMaintenanceRequestView().environmentObject(store) }
        .sheet(isPresented: $showAmenities) { AmenitiesListView().environmentObject(store) }
        .sheet(isPresented: $showSettings) { SimpleSettingsView() }
        .sheet(isPresented: $showContacts) { SimpleContactsView() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                Image(systemName: "square.grid.2x2.fill")
                    .foregroundStyle(Theme.appPurple)
                Text("SERVICE HUB")
                    .tracking(1.4)
                    .foregroundStyle(Theme.appMuted)
            }
            .font(Theme.ui(10, weight: .bold))
            Text("At your service")
                .font(Theme.display(30, weight: .bold))
                .foregroundStyle(Theme.appNavy)
            Text("Everything you need to feel at home.")
                .font(Theme.ui(13))
                .foregroundStyle(Theme.appMuted)
        }
    }

    private var spotlight: some View {
        Button { showNewRequest = true } label: {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    Label("NEED A HAND?", systemImage: "sparkles")
                        .font(Theme.ui(10, weight: .bold))
                        .tracking(0.8)
                        .foregroundStyle(.white.opacity(0.75))
                    Text("We're here to help.")
                        .font(Theme.display(22, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                    Text("Report a problem in a few taps.")
                        .font(Theme.ui(12))
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.leading)
                    Label("Create request", systemImage: "arrow.up.right")
                        .font(Theme.ui(12, weight: .bold))
                        .foregroundStyle(Theme.appPurple)
                        .padding(.horizontal, 14)
                        .frame(height: 34)
                        .background(.white, in: Capsule())
                        .padding(.top, 5)
                }
                Spacer(minLength: 0)
                Image(systemName: "house.lodge.fill")
                    .font(.system(size: 66, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.20))
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(colors: [Theme.appPurple, Theme.appPurple.opacity(0.79)], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 26)
            )
        }
        .buttonStyle(.plain)
    }

    private var requestsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Your requests")
                    .font(Theme.display(21, weight: .bold))
                    .foregroundStyle(Theme.appNavy)
                Spacer()
                Text("\(store.maintenanceRequests.count)")
                    .font(Theme.ui(12, weight: .bold))
                    .foregroundStyle(Theme.appPurple)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.appPurpleSoft, in: Capsule())
            }
            if store.maintenanceRequests.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(Theme.appGreen)
                    Text("All caught up")
                        .font(Theme.ui(16, weight: .bold))
                        .foregroundStyle(Theme.appNavy)
                    Text("Maintenance requests will appear here when you submit them.")
                        .font(Theme.ui(12))
                        .foregroundStyle(Theme.appMuted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(28)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 22))
            } else {
                VStack(spacing: 10) {
                    ForEach(store.maintenanceRequests) { request in
                        ServiceRequestRow(request: request)
                    }
                }
            }
        }
    }
}

private struct ServiceTile: View {
    let title: String
    let subtitle: String
    let icon: String
    let accent: Color
    let surface: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(accent)
                    .frame(width: 50, height: 50)
                    .background(surface, in: RoundedRectangle(cornerRadius: 15))
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.appMuted)
            }
            Spacer(minLength: 20)
            Text(title)
                .font(Theme.ui(15, weight: .bold))
                .foregroundStyle(Theme.appNavy)
                .lineLimit(2)
            Text(subtitle)
                .font(Theme.ui(11))
                .foregroundStyle(Theme.appMuted)
                .lineLimit(2)
                .padding(.top, 5)
        }
        .padding(17)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 162)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 23))
        .overlay(RoundedRectangle(cornerRadius: 23).stroke(Theme.appBorder, lineWidth: 1))
    }
}

private struct ServiceRequestRow: View {
    let request: MaintenanceRequest

    private var statusColor: Color {
        request.stage == .complete ? Theme.appGreen : Theme.info
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: request.stage == .complete ? "checkmark.circle.fill" : "wrench.and.screwdriver.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(statusColor)
                .frame(width: 52, height: 52)
                .background(statusColor.opacity(0.11), in: RoundedRectangle(cornerRadius: 16))
            VStack(alignment: .leading, spacing: 7) {
                Text(request.title)
                    .font(Theme.ui(14, weight: .bold))
                    .foregroundStyle(Theme.appNavy)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    Circle().fill(statusColor).frame(width: 6, height: 6)
                    Text(request.stage.label)
                        .font(Theme.ui(11, weight: .semibold))
                        .foregroundStyle(statusColor)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 21))
        .overlay(RoundedRectangle(cornerRadius: 21).stroke(Theme.appBorder, lineWidth: 1))
    }
}

private struct AmenitiesListView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Theme.wallBackgroundTop,
                        Theme.wallBackgroundBottom
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header

                        VStack(spacing: 12) {
                            ForEach(store.amenities) { amenity in
                                NavigationLink {
                                    AmenityBookingView(amenity: amenity)
                                } label: {
                                    amenityCard(amenity)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, Theme.screenPadding)
                    .padding(.top, 24)
                    .padding(.bottom, 32)
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Book amenity")
                        .font(Theme.ui(16, weight: .bold))
                        .foregroundStyle(Theme.appNavy)
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Theme.appNavy)
                            .frame(width: 36, height: 36)
                            .background(Theme.card, in: Circle())
                    }
                    .accessibilityLabel("Close")
                }
            }
            .tint(Theme.appPurple)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("YOUR COMMUNITY")
                .font(Theme.ui(10, weight: .bold))
                .tracking(1.3)
                .foregroundStyle(Theme.appPurple)

            Text("Find your space")
                .font(Theme.display(28, weight: .bold))
                .foregroundStyle(Theme.appNavy)

            Text("Make the most of your community amenities. Choose a space to view available sessions.")
                .font(Theme.ui(13))
                .foregroundStyle(Theme.appMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func amenityCard(_ amenity: Amenity) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 25, weight: .medium))
                .foregroundStyle(Theme.appPurple)
                .frame(width: 62, height: 62)
                .background(
                    Theme.appPurpleSoft,
                    in: RoundedRectangle(cornerRadius: 18)
                )

            VStack(alignment: .leading, spacing: 7) {
                Text(amenity.name)
                    .font(Theme.ui(17, weight: .bold))
                    .foregroundStyle(Theme.appNavy)

                Text(amenity.subtitle)
                    .font(Theme.ui(12))
                    .foregroundStyle(Theme.appMuted)
                    .lineLimit(2)

                Label("View sessions", systemImage: "clock")
                    .font(Theme.ui(10, weight: .semibold))
                    .foregroundStyle(Theme.appPurple)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Theme.appPurpleSoft, in: Capsule())
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.appPurple)
                .frame(width: 30, height: 30)
                .background(Theme.appPurpleSoft, in: Circle())
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Theme.card,
            in: RoundedRectangle(cornerRadius: 23)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 23)
                .stroke(Theme.appBorder, lineWidth: 1)
        }
    }
}


private struct SimpleSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            SettingsView()
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
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
                            .foregroundStyle(Theme.appPurple)
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
                                .foregroundStyle(Theme.appMuted)
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
                                .foregroundStyle(Theme.appMuted)
                        }
                    }
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Contacts")
            .navigationBarTitleDisplayMode(.inline)
            .tint(Theme.appPurple)
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
