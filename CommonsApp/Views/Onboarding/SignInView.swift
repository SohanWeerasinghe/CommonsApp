//
//  SignInView.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 21/9/2026.
//

import SwiftUI
import FirebaseAuth

struct SignInView: View {
    @EnvironmentObject var store: AppStore
    @State private var showEmailForm = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "FBFAF7"), Color(hex: "F1F3F6")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Text("COMMONS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color(hex: "CF941D"))
                    .padding(.top, 6)

                ZStack(alignment: .bottomLeading) {
                    LinearGradient(
                        colors: [
                            Color(hex: "5D8DDF"),
                            Color(hex: "8068C9"),
                            Color(hex: "D17775")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    Text("BUILDING EXTERIOR.")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.leading, 12)
                        .padding(.bottom, 11)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 330)
                .clipShape(RoundedRectangle(cornerRadius: 30))
                .padding(.top, 24)

                Text("Everything in your building,\nwithout the noise.")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color(hex: "182134"))
                    .lineSpacing(1)
                    .padding(.top, 18)

                Text("Updates, neighbours, shared things and services.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "8E96A5"))
                    .padding(.top, 20)

                Spacer()

                Button("Continue with email") {
                    showEmailForm = true
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color(hex: "7061CF"))
                .clipShape(Capsule())

                Spacer()
                    .frame(height: 116)
            }
            .padding(.horizontal, 20)
        }
        .sheet(isPresented: $showEmailForm) {
            EmailAuthFormView()
        }
    }
}

private struct EmailAuthFormView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var isRegistering = true
    @State private var isLoading = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Account details") {
                    TextField("Email address", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    SecureField("Password", text: $password)
                        .textContentType(isRegistering ? .newPassword : .password)
                }

                Section {
                    Button(isRegistering ? "Create Account" : "Sign In") {
                        Task {
                            await authenticate()
                        }
                    }
                    .disabled(isLoading || email.isEmpty || password.isEmpty)

                    if isLoading {
                        ProgressView("Please wait...")
                    }

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button(isRegistering
                           ? "Already have an account? Sign In"
                           : "New resident? Create Account") {
                        isRegistering.toggle()
                        errorMessage = ""
                    }
                }
            }
            .navigationTitle(isRegistering ? "Create Account" : "Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    @MainActor
    private func authenticate() async {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanEmail.isEmpty, password.count >= 6 else {
            errorMessage = "Enter a valid email and a password with at least 6 characters."
            return
        }

        isLoading = true
        errorMessage = ""

        defer {
            isLoading = false
        }

        do {
            if isRegistering {
                let result = try await Auth.auth().createUser(
                    withEmail: cleanEmail,
                    password: password
                )

                try await result.user.sendEmailVerification()

                store.pendingEmail = cleanEmail
                store.onboardingStage = .waitingRoom
            } else {
                let result = try await Auth.auth().signIn(
                    withEmail: cleanEmail,
                    password: password
                )

                store.pendingEmail = cleanEmail

                try await result.user.reload()

                if result.user.isEmailVerified {
                    // Temporary until we implement Firestore profile lookup.
                    store.onboardingStage = .profileSetup
                } else {
                    store.onboardingStage = .waitingRoom
                }
            }

            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    SignInView()
        .environmentObject(AppStore())
}

