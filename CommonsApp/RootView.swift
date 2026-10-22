
import SwiftUI

struct RootView: View {

    @EnvironmentObject var store: AppStore

    @Environment(\.scenePhase) private var scenePhase

    @State private var isRefreshing = false
    @State private var refreshError = ""

    var body: some View {
        ZStack {
            // Display one screen based on the resident's account status
            if store.onboardingStage == .loading {
                VStack(spacing: 16) {
                    ProgressView()

                    Text("Checking your account...")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            } else if store.onboardingStage == .signIn {
                SignInView()

            } else if store.onboardingStage == .profileSetup {
                ProfileSetupView()

            } else if store.onboardingStage == .waitingRoom {
                WaitingRoomView()

            } else if store.onboardingStage == .pendingApproval {
                VStack(spacing: 20) {
                    Image(systemName: "clock.badge.checkmark")
                        .font(.system(size: 44))
                        .foregroundStyle(.secondary)

                    Text("Waiting for Admin Approval")
                        .font(.title3.bold())

                    Text("Your profile has been submitted. Please wait for an administrator to approve your account.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button {
                        Task {
                            isRefreshing = true
                            refreshError = ""

                            defer {
                                isRefreshing = false
                            }

                            do {
                                try await store.loadResidentAccountStatus()
                            } catch {
                                refreshError = error.localizedDescription
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if isRefreshing {
                                ProgressView()
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }

                            Text(isRefreshing ? "Checking..." : "Refresh Status")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(14)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isRefreshing)

                    if !refreshError.isEmpty {
                        Text(refreshError)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            } else if store.onboardingStage == .accessDeclined {
                VStack(spacing: 20) {

                    Image(systemName: "person.crop.circle.badge.xmark")
                        .font(.system(size: 48))
                        .foregroundStyle(.red)

                    Text("Application Declined")
                        .font(.title3.bold())

                    Text("Your resident application was not approved. Please contact your building administrator for assistance.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button {
                        do {
                            try store.signOutResident()
                        } catch {
                            refreshError = error.localizedDescription
                        }
                    } label: {
                        Text("Sign Out")
                            .frame(maxWidth: .infinity)
                            .padding(14)
                    }
                    .buttonStyle(.borderedProminent)

                    if !refreshError.isEmpty {
                        Text(refreshError)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                //switch between admin and normal user based on email u signed in
            } else if store.onboardingStage == .admin {
                NavigationStack {
                    AdminPanelView()
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Sign Out") {
                                    do {
                                        try store.signOutResident()
                                    } catch {
                                        refreshError = error.localizedDescription
                                    }
                                }
                            }
                        }
                }

            } else if store.onboardingStage == .active {
                MainTabView()
            }

            // Keep the existing app lock functionality
            if store.isLocked {
                AppLockView()
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .inactive || newPhase == .background {
                store.lockApp()
            }
        }
        .task {
            await store.restoreSession()
        }
    }
}
