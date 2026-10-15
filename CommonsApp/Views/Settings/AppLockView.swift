//
//  AppLockView.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 21/9/2026.
//

import SwiftUI

// This screen covers the whole app when isLocked is true
// The user must pass Face ID to get back in
struct AppLockView: View {

    @EnvironmentObject var store: AppStore

    // Shows an error message if Face ID fails
    @State private var errorMessage = ""
    @State private var isAuthenticating = false

    var body: some View {
        ZStack {
            // Dark background covering the whole screen
            Theme.ink.ignoresSafeArea()

            VStack(spacing: 40) {

                Spacer()

                // App icon and name
                VStack(spacing: 16) {
                    Image(systemName: "building.2.crop.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(Theme.brass)

                    Text("Commons")
                        .font(Theme.display(28))
                        .foregroundStyle(Theme.textOnInk)
                }

                Spacer()

                // Unlock section
                VStack(spacing: 16) {

                    // Error message if auth failed
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(Theme.ui(13))
                            .foregroundStyle(Theme.clay)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }

                    // Face ID unlock button
                    Button {
                        tryUnlock()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "faceid")
                                .font(.system(size: 20))
                            Text("Unlock with Face ID")
                                .font(Theme.ui(15, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .foregroundStyle(Theme.ink)
                        .background(isAuthenticating ? Theme.brass.opacity(0.6) : Theme.brass)
                        .clipShape(Capsule())
                    }
                    .disabled(isAuthenticating)
                    .padding(.horizontal, 40)
                }

                Spacer()
                    .frame(height: 40)
            }
        }
        // Automatically try Face ID when this screen appears
        .onAppear {
            tryUnlock()
        }
    }

    // Asks the store to run the Face ID check
    func tryUnlock() {
        isAuthenticating = true
        errorMessage = ""

        store.unlockWithBiometrics { success in
            isAuthenticating = false
            if !success {
                errorMessage = "Face ID failed. Tap to try again."
            }
        }
    }
}

#Preview {
    AppLockView().environmentObject(AppStore())
}
