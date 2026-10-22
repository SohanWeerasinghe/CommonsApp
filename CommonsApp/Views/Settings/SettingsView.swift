//
//  SettingsView.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 21/9/2026.
//
import SwiftUI
import UserNotifications
import UIKit
private enum SettingsPalette {
    static let background = Color(red: 0.965, green: 0.963, blue: 0.985)
    static let ink = Color(red: 0.12, green: 0.17, blue: 0.28)
    static let secondary = Color(red: 0.46, green: 0.49, blue: 0.59)
    static let purple = Color(red: 0.43, green: 0.36, blue: 0.91)
    static let lavender = Color(red: 0.93, green: 0.91, blue: 1.0)
    static let green = Color(red: 0.20, green: 0.64, blue: 0.51)
}
struct SettingsView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var showEditProfile = false
    @State private var showSignOutError = false
    @State private var signOutErrorMessage = ""
    @State private var isUpdatingAppLock = false
    @State private var showAppLockError = false
    @State private var appLockErrorMessage = ""
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var isRequestingNotifications = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                introduction
                profileCard
                securitySection
                notificationSection
                accountSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 40)
        }
        .background(SettingsPalette.background.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.light)
        .sheet(isPresented: $showEditProfile) {
            NavigationStack {
                EditProfileView()
                    .environmentObject(store)
            }
        }
        .onAppear { checkNotificationPermission() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { checkNotificationPermission() }
        }
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
    private var introduction: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("YOUR SPACE")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(2)
                .foregroundStyle(SettingsPalette.purple)
            Text("Make Commons yours")
                .font(.system(size: 27, weight: .bold, design: .rounded))
                .foregroundStyle(SettingsPalette.ink)
            Text("Manage your privacy, notifications and account.")
                .font(.system(size: 13))
                .foregroundStyle(SettingsPalette.secondary)
        }
    }
    private var profileCard: some View {
        Button {
            showEditProfile = true
        } label: {
        HStack(spacing: 14) {
            Text(store.currentResident.unit.isEmpty ? "?" : store.currentResident.unit)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(SettingsPalette.purple)
                .frame(width: 58, height: 58)
                .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 18))
            VStack(alignment: .leading, spacing: 5) {
                Text(store.currentResident.name.isEmpty ? "Your Profile" : store.currentResident.name)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text("Unit \(store.currentResident.unit)")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.8))
            }
            Spacer(minLength: 0)
            Image(systemName: "person.crop.circle")
                .font(.system(size: 23))
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [SettingsPalette.purple, Color(red: 0.32, green: 0.30, blue: 0.69)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24)
        )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Edit personal details")
    }
    private var securitySection: some View {
        VStack(alignment: .leading, spacing: 11) {
            sectionHeading("Privacy & Security", symbol: "lock.shield")
            settingsCard {
                HStack(spacing: 13) {
                    iconTile("faceid", color: SettingsPalette.purple)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Face ID App Lock")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(SettingsPalette.ink)
                        Text("Protect Commons when you return")
                            .font(.system(size: 11))
                            .foregroundStyle(SettingsPalette.secondary)
                    }
                    Spacer(minLength: 4)
                    Toggle("Face ID App Lock", isOn: Binding(
                        get: { store.appLockEnabled },
                        set: { changeAppLock(to: $0) }
                    ))
                    .labelsHidden()
                    .tint(SettingsPalette.purple)
                    .disabled(isUpdatingAppLock)
                }
                Divider().padding(.leading, 55)
                HStack(spacing: 13) {
                    iconTile("clock.arrow.circlepath", color: SettingsPalette.purple)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Require Authentication")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(SettingsPalette.ink)
                        Text("Choose when the app locks")
                            .font(.system(size: 11))
                            .foregroundStyle(SettingsPalette.secondary)
                    }
                    Spacer(minLength: 4)
                    Picker("Require Authentication", selection: Binding(
                        get: { store.appLockDelay },
                        set: { store.setAppLockDelay($0) }
                    )) {
                        Text("Immediately").tag(0)
                        Text("After 1 minute").tag(60)
                        Text("After 5 minutes").tag(300)
                        Text("After 15 minutes").tag(900)
                    }
                    .labelsHidden()
                    .tint(SettingsPalette.purple)
                    .disabled(!store.appLockEnabled)
                }
                if store.appLockEnabled {
                    Label("App lock is enabled", systemImage: "checkmark.shield.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(SettingsPalette.green)
                        .padding(.leading, 55)
                }
            }
        }
    }
    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            sectionHeading("Notifications", symbol: "bell")
            settingsCard {
                HStack(spacing: 13) {
                    iconTile("bell.badge.fill", color: SettingsPalette.purple)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Push Notifications")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(SettingsPalette.ink)
                        Text(notificationStatusText)
                            .font(.system(size: 11))
                            .foregroundStyle(SettingsPalette.secondary)
                    }
                    Spacer(minLength: 4)
                    Image(systemName: notificationsAllowed ? "checkmark.circle.fill" : "bell.slash.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(notificationsAllowed ? SettingsPalette.green : SettingsPalette.secondary)
                }
                Divider().padding(.leading, 55)
                Button {
                    if notificationStatus == .notDetermined {
                        requestNotificationPermission()
                    } else {
                        openNotificationSettings()
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "slider.horizontal.3")
                        Text(notificationStatus == .notDetermined ? "Enable Notifications" : "Notification Settings")
                        Spacer()
                        if isRequestingNotifications {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.up.right")
                        }
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(SettingsPalette.purple)
                    .padding(.vertical, 3)
                }
                .buttonStyle(.plain)
                .disabled(isRequestingNotifications)
            }
        }
    }
    
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            sectionHeading("Account", symbol: "person.crop.circle")
            settingsCard {
                Button {
                    do {
                        try store.signOutResident()
                    } catch {
                        signOutErrorMessage = error.localizedDescription
                        showSignOutError = true
                    }
                } label: {
                    HStack(spacing: 13) {
                        iconTile("rectangle.portrait.and.arrow.right", color: .red)
                        Text("Sign Out")
                            .font(.system(size: 14, weight: .semibold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
        }
    }
    private func sectionHeading(_ title: String, symbol: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(SettingsPalette.purple)
            Text(title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(SettingsPalette.ink)
        }
        .padding(.leading, 3)
    }
    private func iconTile(_ symbol: String, color: Color) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 19, weight: .medium))
            .foregroundStyle(color)
            .frame(width: 42, height: 42)
            .background(SettingsPalette.lavender.opacity(0.65), in: RoundedRectangle(cornerRadius: 13))
    }
    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14, content: content)
            .padding(17)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white, in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(SettingsPalette.ink.opacity(0.06)))
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
