import SwiftUI

struct RootView: View {

    @EnvironmentObject var store: AppStore

    // Watches whether the app is in the foreground or background
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            // Show the right screen based on onboarding stage
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
            }
            if store.onboardingStage == .signIn {
                SignInView()
            } else if store.onboardingStage == .profileSetup {
                ProfileSetupView()
            } else if store.onboardingStage == .waitingRoom {
                WaitingRoomView()
            } else if store.onboardingStage == .pendingApproval {
                Text("Your profile is waiting for admin approval.")
            } else if store.onboardingStage == .accessDeclined {
                Text("Your resident application was declined.")
            } else if store.onboardingStage == .active {
                MainTabView()
            }

            // If the app is locked show the lock screen on top
            // of everything else
            if store.isLocked {
                AppLockView()
            }
        }
        // Watch for the app going to background
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background {
                // Lock the app when it goes to background
                store.lockApp()
            }
        }
        .task {
            await store.restoreSession()
        }
    }
}
