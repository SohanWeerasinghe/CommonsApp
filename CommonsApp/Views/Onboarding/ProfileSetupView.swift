//
//  ProfileSetupView.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 21/9/2026.
//

import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject var store: AppStore

    @State private var name = "Alex Morgan"
    @State private var unit = "7B"
    @State private var phone = "+94 77 123 4567"

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "FBFAF7"), Color(hex: "F1F3F6")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ProfileSetupHeader {
                            store.onboardingStage = .waitingRoom
                        }

                        AddPhotoView()
                            .padding(.top, 30)

                        VStack(spacing: 7) {
                            ProfileSetupField(
                                title: "NAME",
                                text: $name,
                                keyboardType: .default
                            )

                            ProfileSetupField(
                                title: "UNIT",
                                text: $unit,
                                keyboardType: .default
                            )

                            ProfileSetupField(
                                title: "PHONE",
                                text: $phone,
                                keyboardType: .phonePad
                            )
                        }
                        .padding(.top, 27)

                        ProfilePrivacyCard()
                            .padding(.top, 40)
                    }
                    .padding(.horizontal, 20)
                }
                .scrollIndicators(.hidden)

                Button("Finish setup") {
                    store.completeProfileSetup(
                        name: name,
                        unit: unit,
                        phone: phone,
                        preference: .push,
                        showUnit: true
                    )
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color(hex: "7061CF"))
                .clipShape(Capsule())
                .disabled(name.isEmpty || unit.isEmpty)
                .opacity(name.isEmpty || unit.isEmpty ? 0.5 : 1)
                .padding(.horizontal, 20)
                .padding(.bottom, 56)
            }
        }
    }
}

struct ProfileSetupHeader: View {
    let goBack: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Button(action: goBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color(hex: "182134"))
                    .frame(width: 28, height: 44, alignment: .leading)
            }

            VStack(alignment: .leading, spacing: 7) {
                Text("PROFILE SETUP")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color(hex: "7F8795"))

                Text("Make it yours")
                    .font(.system(size: 25, weight: .bold))
                    .foregroundStyle(Color(hex: "182134"))
            }
        }
        .padding(.top, 2)
    }
}

struct AddPhotoView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ADD A PHOTO")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color(hex: "7F8795"))

            ZStack {
                Circle()
                    .fill(Color(hex: "EFECFF"))

                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(Color(hex: "6F61D7"))
            }
            .frame(width: 86, height: 86)
            .padding(.leading, 9)
        }
    }
}

struct ProfileSetupField: View {
    let title: LocalizedStringResource
    @Binding var text: String
    let keyboardType: UIKeyboardType

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color(hex: "7F8795"))

            TextField("", text: $text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(hex: "182134"))
                .keyboardType(keyboardType)
                .padding(.horizontal, 16)
                .frame(height: 51)
                .background(.white.opacity(0.78))
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .overlay {
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color(hex: "E0E3E8"), lineWidth: 1)
                }
        }
    }
}

struct ProfilePrivacyCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Name + unit visible to neighbours")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(hex: "182134"))

            Text("Phone stays private")
                .font(.system(size: 10))
                .foregroundStyle(Color(hex: "8E96A5"))
        }
        .padding(.horizontal, 17)
        .frame(maxWidth: .infinity, minHeight: 90, alignment: .leading)
        .background(.white.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(hex: "E0E3E8"), lineWidth: 1)
        }
    }
}

#Preview {
    ProfileSetupView()
        .environmentObject(AppStore())
}
