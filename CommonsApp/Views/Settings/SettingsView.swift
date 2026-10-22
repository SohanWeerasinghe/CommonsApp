//
//  SettingsView.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 21/9/2026.
//

import SwiftUI
import UserNotifications
import UIKit

struct SettingsView: View {

    @EnvironmentObject var store: AppStore
    @State private var showSignOutError = false
    @State private var signOutErrorMessage = ""
    @State private var isUpdatingAppLock = false
    @State private var showAppLockError = false
    @State private var appLockErrorMessage = ""
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var isRequestingNotifications = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Theme.paper.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // MARK: Privacy & Security section
                    VStack(alignment: .leading, spacing: 12) {

                        SectionHeader(title: "Privacy & Security")

                        PlaqueCard {
                            VStack(spacing: 0) {

                                // Face ID toggle row
                                HStack(spacing: 14) {

                                    // Icon
                                    Image(systemName: "faceid")
                                        .font(.system(size: 26))
                                        .foregroundStyle(Theme.brass)
                                        .frame(width: 32)

                                    // Label
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Face ID App Lock")
                                            .font(Theme.ui(14, weight: .semibold))
                                            .foregroundStyle(Theme.textPrimary)

                                        Text("Require Face ID when returning to Commons")
                                            .font(Theme.ui(11.5))
                                            .foregroundStyle(Theme.textMuted)
                                    }

                                    Spacer()

                                    // Toggle switch
                                    Toggle(
                                        "",
                                        isOn: Binding(
                                            get: {
                                                store.appLockEnabled
                                            },
                                            set: { newValue in
                                                changeAppLock(to: newValue)
                                            }
                                        )
                                    )
                                    .labelsHidden()
                                    .tint(Theme.brass)
                                    .disabled(isUpdatingAppLock)
                                }

                                // Green confirmation shown when lock is on
                                if store.appLockEnabled {
                                    Divider()
                                        .padding(.vertical, 12)

                                    HStack(spacing: 8) {
                                        Image(systemName: "checkmark.shield.fill")
                                            .foregroundStyle(Theme.sage)
                                            .font(.system(size: 13))

                                        Text("App will lock when you switch away")
                                            .font(Theme.ui(12))
                                            .foregroundStyle(Theme.sage)

                                        Spacer()
                                    }
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Require Authentication")
                            .font(.system(size: 15, weight: .semibold))

                        Picker(
                            "Require Authentication",
                            selection: Binding(
                                get: {
                                    store.appLockDelay
                                },
                                set: { newValue in
                                    store.setAppLockDelay(newValue)
                                }
                            )
                        ) {
                            Text("Immediately").tag(0)
                            Text("After 1 minute").tag(60)
                            Text("After 5 minutes").tag(300)
                            Text("After 15 minutes").tag(900)
                        }
                        .pickerStyle(.menu)
                        .disabled(!store.appLockEnabled)
                    }

                    // MARK: Notifications

                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Notifications")

                        PlaqueCard {
                            VStack(spacing: 16) {

                                HStack(spacing: 14) {
                                    Image(systemName: "bell.badge.fill")
                                        .font(.system(size: 22))
                                        .foregroundStyle(Theme.brass)
                                        .frame(width: 32)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Push Notifications")
                                            .font(Theme.ui(14, weight: .semibold))
                                            .foregroundStyle(Theme.textPrimary)

                                        Text(notificationStatusText)
                                            .font(Theme.ui(12))
                                            .foregroundStyle(Theme.textMuted)
                                    }

                                    Spacer()

                                    Image(
                                        systemName: notificationsAllowed
                                            ? "checkmark.circle.fill"
                                            : "bell.slash.fill"
                                    )
                                    .foregroundStyle(
                                        notificationsAllowed ? Theme.sage : Theme.textMuted
                                    )
                                }

                                Divider()

                                if notificationStatus == .notDetermined {
                                    Button {
                                        requestNotificationPermission()
                                    } label: {
                                        HStack {
                                            if isRequestingNotifications {
                                                ProgressView()
                                            }

                                            Text("Enable Notifications")
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(Theme.brass)
                                    .disabled(isRequestingNotifications)

                                } else {
                                    Button {
                                        openNotificationSettings()
                                    } label: {
                                        HStack {
                                            Image(systemName: "gearshape.fill")
                                            Text("Manage Notification Settings")
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(Theme.brass)
                                }
                            }
                        }
                    }

                    // MARK: Offline cache section
                    VStack(alignment: .leading, spacing: 12) {

                        SectionHeader(title: "Offline Data")

                        PlaqueCard {
                            VStack(spacing: 14) {
                                ForEach(store.offlineCache) { item in
                                    HStack(spacing: 12) {

                                        // Tick or empty circle
                                        Image(systemName: item.isCached
                                              ? "checkmark.circle.fill"
                                              : "circle")
                                            .foregroundStyle(
                                                item.isCached ? Theme.sage : Theme.hairline
                                            )

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.label)
                                                .font(Theme.ui(13, weight: .semibold))
                                                .foregroundStyle(Theme.textPrimary)

                                            if item.isCached {
                                                Text("Cached")
                                                    .font(Theme.ui(11))
                                                    .foregroundStyle(Theme.sage)
                                            } else {
                                                Text("Not cached")
                                                    .font(Theme.ui(11))
                                                    .foregroundStyle(Theme.textMuted)
                                            }
                                        }

                                        Spacer()
                                    }
                                }
                            }
                        }
                    }

                    // MARK: Demo section
                    VStack(alignment: .leading, spacing: 12) {

                        //My Profile section
                        VStack(alignment: .leading, spacing: 12) {

                            SectionHeader(title: "My Profile")

                            NavigationLink {
                                //ResidentProfileView(resident: store.currentResident)
                            } label: {
                                PlaqueCard {
                                    HStack(spacing: 14) {

                                        UnitBadge(unit: store.currentResident.unit.isEmpty
                                                  ? "?" : store.currentResident.unit,
                                                  size: 44)

                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(store.currentResident.name.isEmpty
                                                 ? "Your Profile" : store.currentResident.name)
                                                .font(Theme.ui(14, weight: .semibold))
                                                .foregroundStyle(Theme.textPrimary)

                                            Text("Unit \(store.currentResident.unit)")
                                                .font(Theme.ui(12))
                                                .foregroundStyle(Theme.textMuted)
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(Theme.textMuted)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                //Account section
                VStack(alignment: .leading, spacing: 12) {

                    SectionHeader(title: "Account")

                    PlaqueCard {
                        Button {
                            do {
                                try store.signOutResident()
                            } catch {
                                signOutErrorMessage = error.localizedDescription
                                showSignOutError = true
                            }
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 20))
                                    .foregroundStyle(.red)
                                    .frame(width: 32)

                                Text("Sign Out")
                                    .font(Theme.ui(14, weight: .semibold))
                                    .foregroundStyle(.red)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundStyle(Theme.textMuted)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            checkNotificationPermission()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                checkNotificationPermission()
            }
        }
        .navigationBarTitleDisplayMode(.large)
        .alert("Sign Out Failed", isPresented: $showSignOutError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(signOutErrorMessage)
        }
        .alert("App Lock", isPresented: $showAppLockError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(appLockErrorMessage)
        }
    }

    private var notificationsAllowed: Bool {
        notificationStatus == .authorized ||
        notificationStatus == .provisional ||
        notificationStatus == .ephemeral
    }

    private var notificationStatusText: String {
        switch notificationStatus {
        case .notDetermined:
            return "Notifications have not been enabled"

        case .denied:
            return "Notifications are disabled"

        case .authorized:
            return "Notifications are allowed"

        case .provisional:
            return "Quiet notifications are allowed"

        case .ephemeral:
            return "Temporary notification permission"

        @unknown default:
            return "Notification status unavailable"
        }
    }

    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationStatus = settings.authorizationStatus
            }
        }
    }

    private func requestNotificationPermission() {
        isRequestingNotifications = true

        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { _, _ in
            DispatchQueue.main.async {
                isRequestingNotifications = false
                checkNotificationPermission()
            }
        }
    }

    private func openNotificationSettings() {
        guard let url = URL(
            string: UIApplication.openSettingsURLString
        ) else {
            return
        }

        UIApplication.shared.open(url)
    }

    private func changeAppLock(to enabled: Bool) {
        if isUpdatingAppLock {
            return
        }

        isUpdatingAppLock = true

        if enabled {
            store.enableAppLock { success in
                isUpdatingAppLock = false

                if !success {
                    appLockErrorMessage =
                        "Unable to enable app lock. Check that Face ID or Touch ID is available and enrolled in your device settings."
                    showAppLockError = true
                }
            }
        } else {
            store.disableAppLock { success in
                isUpdatingAppLock = false

                if !success {
                    appLockErrorMessage =
                        "Authentication was not completed. App lock remains enabled."
                    showAppLockError = true
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environmentObject(AppStore())
}
