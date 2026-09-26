//
//  SignInView.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 21/9/2026.
//

import SwiftUI

struct SignInView: View {

    // Get the store from the backpack
    @EnvironmentObject var store: AppStore

    // use to holds whatever the user types in the email box
    @State private var email = ""

    var body: some View {
        ZStack {
            // Dark navy background that fills the whole screen
            Theme.ink.ignoresSafeArea()

            VStack(spacing: 0) {

                Spacer()

                // App logo area
                VStack(spacing: 12) {
                    Image(systemName: "building.2.crop.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Theme.brass)

                    Text("Commons")
                        .font(Theme.display(32))
                        .foregroundStyle(Theme.textOnInk)

                    Text("007 Colombo 07")
                        .font(Theme.ui(14))
                        .foregroundStyle(Theme.textOnInkMuted)
                }

                Spacer()

                // Email input and button
                VStack(spacing: 16) {

                    // Email text field
                    TextField("your@email.com", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding(14)
                        .background(Theme.inkLight)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(Theme.textOnInk)

                    // Send magic link button
                    Button("Send Magic Link") {
                        store.sendMagicLink()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    // Button is disabled if email box is empty
                    .disabled(email.isEmpty)
                    .opacity(email.isEmpty ? 0.5 : 1)

                    Text("We'll email you a one-tap sign-in link")
                        .font(Theme.ui(12))
                        .foregroundStyle(Theme.textOnInkMuted)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
            }
        }
    }
}

#Preview {
    SignInView().environmentObject(AppStore())
}
