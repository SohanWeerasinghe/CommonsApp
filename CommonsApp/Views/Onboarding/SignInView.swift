import SwiftUI
import FirebaseAuth

// CommonsApp authentication. The Firebase and onboarding flows are unchanged.
struct SignInView: View {
    @State private var showEmailForm = false

    private let navy = Color(red: 0.10, green: 0.14, blue: 0.23)
    private let violet = Color(red: 0.43, green: 0.36, blue: 0.88)

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.grid.2x2.fill")
                            .font(.system(size: 17, weight: .semibold))
                        Text("COMMONS")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .tracking(2.3)
                    }
                    .foregroundStyle(navy)
                    .padding(.top, 22)

                    welcomeArtwork
                        .padding(.top, 28)

                    Text("Your community.\nAll in one place.")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .tracking(-1.3)
                        .foregroundStyle(navy)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 30)

                    Text("Stay connected with neighbours, discover events and keep up with what matters in your building.")
                        .font(.system(size: 15))
                        .foregroundStyle(Color(red: 0.44, green: 0.48, blue: 0.57))
                        .lineSpacing(4)
                        .padding(.top, 12)

                    Spacer(minLength: 34)

                    Button {
                        showEmailForm = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Continue with email")
                                .font(.system(size: 16, weight: .semibold))
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .frame(height: 58)
                        .background(violet, in: RoundedRectangle(cornerRadius: 19))
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: 6) {
                        Image(systemName: "lock.shield")
                        Text("A private space for your building")
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(Color(red: 0.50, green: 0.53, blue: 0.61))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 17)
                    .padding(.bottom, 28)
                }
                .padding(.horizontal, 26)
                .frame(minHeight: geometry.size.height, alignment: .top)
            }
            .scrollIndicators(.hidden)
            .background(Color(red: 0.976, green: 0.975, blue: 0.992).ignoresSafeArea())
        }
        .sheet(isPresented: $showEmailForm) {
            EmailAuthFormView()
        }
    }

    private var welcomeArtwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.36, green: 0.39, blue: 0.80),
                                 Color(red: 0.57, green: 0.45, blue: 0.83),
                                 Color(red: 0.86, green: 0.64, blue: 0.67)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(.white.opacity(0.12))
                .frame(width: 240, height: 240)
                .offset(x: 120, y: -80)

            Circle()
                .fill(.white.opacity(0.09))
                .frame(width: 180, height: 180)
                .offset(x: -120, y: 100)

            VStack(spacing: 16) {
                Image(systemName: "building.2.crop.circle.fill")
                    .font(.system(size: 90, weight: .ultraLight))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white)
                Text("A better way to belong")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .frame(height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .accessibilityLabel("Commons community illustration")
    }
}

private struct EmailAuthFormView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var isRegistering = true
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showsPassword = false

    private let navy = Color(red: 0.10, green: 0.14, blue: 0.23)
    private let violet = Color(red: 0.43, green: 0.36, blue: 0.88)
    private let muted = Color(red: 0.46, green: 0.49, blue: 0.58)
    private let background = Color(red: 0.976, green: 0.975, blue: 0.992)

    private var canSubmit: Bool {
        !isLoading && !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !password.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 9) {
                        Image(systemName: "square.grid.2x2.fill")
                        Text("COMMONS")
                            .tracking(2)
                    }
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(violet)
                    .padding(.top, 30)

                    Text(isRegistering ? "Join your\ncommunity." : "Welcome\nback.")
                        .font(.system(size: 37, weight: .bold, design: .rounded))
                        .tracking(-1.2)
                        .foregroundStyle(navy)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 20)

                    Text(isRegistering
                         ? "Create an account to connect with your building."
                         : "Sign in to pick up where you left off.")
                        .font(.system(size: 15))
                        .foregroundStyle(muted)
                        .padding(.top, 10)
                        .padding(.bottom, 30)

                    VStack(alignment: .leading, spacing: 9) {
                        Text("EMAIL ADDRESS")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.2)
                            .foregroundStyle(muted)

                        HStack(spacing: 12) {
                            Image(systemName: "envelope")
                                .foregroundStyle(violet)
                                .frame(width: 20)
                            TextField("you@example.com", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .submitLabel(.next)
                        }
                        .font(.system(size: 15))
                        .padding(.horizontal, 17)
                        .frame(height: 58)
                        .background(.white, in: RoundedRectangle(cornerRadius: 17))
                    }

                    VStack(alignment: .leading, spacing: 9) {
                        Text("PASSWORD")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.2)
                            .foregroundStyle(muted)

                        HStack(spacing: 12) {
                            Image(systemName: "lock")
                                .foregroundStyle(violet)
                                .frame(width: 20)

                            Group {
                                if showsPassword {
                                    TextField("Enter your password", text: $password)
                                } else {
                                    SecureField("Enter your password", text: $password)
                                }
                            }
                            .textContentType(isRegistering ? .newPassword : .password)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                            Button {
                                showsPassword.toggle()
                            } label: {
                                Image(systemName: showsPassword ? "eye.slash" : "eye")
                                    .foregroundStyle(muted)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(showsPassword ? "Hide password" : "Show password")
                        }
                        .font(.system(size: 15))
                        .padding(.horizontal, 17)
                        .frame(height: 58)
                        .background(.white, in: RoundedRectangle(cornerRadius: 17))

                        if isRegistering {
                            Text("Use at least 6 characters.")
                                .font(.system(size: 12))
                                .foregroundStyle(muted)
                        }
                    }
                    .padding(.top, 22)

                    if !errorMessage.isEmpty {
                        Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.red)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
                            .padding(.top, 18)
                    }

                    Button {
                        Task { await authenticate() }
                    } label: {
                        HStack(spacing: 10) {
                            Spacer()
                            if isLoading {
                                ProgressView().tint(.white)
                            }
                            Text(isRegistering ? "Create account" : "Sign in")
                            Image(systemName: "arrow.right")
                            Spacer()
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(height: 58)
                        .background(violet, in: RoundedRectangle(cornerRadius: 18))
                        .opacity(canSubmit ? 1 : 0.5)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSubmit)
                    .padding(.top, 28)

                    Button {
                        isRegistering.toggle()
                        errorMessage = ""
                        showsPassword = false
                    } label: {
                        HStack(spacing: 5) {
                            Text(isRegistering ? "Already have an account?" : "New to Commons?")
                                .foregroundStyle(muted)
                            Text(isRegistering ? "Sign in" : "Create account")
                                .foregroundStyle(violet)
                                .fontWeight(.bold)
                        }
                        .font(.system(size: 14))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 26)
                .padding(.bottom, 35)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(navy)
                }
            }
            .toolbarBackground(background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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
        defer { isLoading = false }

        do {
            if isRegistering {
                let result = try await Auth.auth().createUser(
                    withEmail: cleanEmail,
                    password: password
                )
                try await result.user.sendEmailVerification()
                store.pendingEmail = cleanEmail
                store.onboardingStage = .profileSetup
            } else {
                _ = try await Auth.auth().signIn(
                    withEmail: cleanEmail,
                    password: password
                )
                store.pendingEmail = cleanEmail
                try await store.loadResidentAccountStatus()
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
