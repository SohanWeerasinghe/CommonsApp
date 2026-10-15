//
//  WaitingRoomView.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 21/9/2026.
//

import SwiftUI

struct WaitingRoomView: View {

    @EnvironmentObject var store: AppStore

    var body: some View {
        ZStack {
            Theme.ink.ignoresSafeArea()

            VStack(spacing: 0) {

                Spacer()

                // Icon and message
                VStack(spacing: 20) {
                    Image(systemName: "envelope.open.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(Theme.brass)

                    Text("Check your inbox")
                        .font(Theme.display(24))
                        .foregroundStyle(Theme.textOnInk)

                    Text("We sent a sign-in link to your email.\nTap it to continue.")
                        .font(Theme.ui(15))
                        .foregroundStyle(Theme.textOnInkMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()

                // In a real app this happens automatically when
                // the user taps the email link.
                // Here we simulate it with a button.
                VStack(spacing: 12) {
                    Button("I've verified my email") {
                        Task {
                            do {
                                let verified = try await store.checkEmailVerification()
                                if !verified {
                                    print("Email is not verified yet.")
                                }
                            } catch {
                                print("Verification check failed: \(error.localizedDescription)")
                            }
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(24)
            }
        }
    }
}

#Preview {
    WaitingRoomView().environmentObject(AppStore())
}
