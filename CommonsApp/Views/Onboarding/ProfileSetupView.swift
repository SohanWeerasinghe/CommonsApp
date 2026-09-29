//
//  ProfileSetupView.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 21/9/2026.
//

import SwiftUI

struct ProfileSetupView: View {

    @EnvironmentObject var store: AppStore

    // One variable for each field the user fills in
    @State private var name = ""
    @State private var unit = ""
    @State private var phone = ""
    @State private var preference: Resident.ContactPreference = .push
    @State private var showUnit = true

    var body: some View {
        ZStack {
            Theme.paper.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Title
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Set up your profile")
                            .font(Theme.display(26))
                            .foregroundStyle(Theme.textPrimary)

                        Text("Your neighbours will see this information")
                            .font(Theme.ui(14))
                            .foregroundStyle(Theme.textMuted)
                    }
                    .padding(.top, 16)

                    // Name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("FULL NAME")
                            .font(Theme.ui(12, weight: .semibold))
                            .foregroundStyle(Theme.textMuted)

                        TextField("e.g. Priya Nair", text: $name)
                            .padding(14)
                            .background(Theme.card)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Theme.hairline, lineWidth: 1)
                            )
                    }

                    // Unit number field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("UNIT NUMBER")
                            .font(Theme.ui(12, weight: .semibold))
                            .foregroundStyle(Theme.textMuted)

                        TextField("e.g. 4B", text: $unit)
                            .padding(14)
                            .background(Theme.card)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Theme.hairline, lineWidth: 1)
                            )
                    }

                    // Phone field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PHONE (OPTIONAL)")
                            .font(Theme.ui(12, weight: .semibold))
                            .foregroundStyle(Theme.textMuted)

                        TextField("e.g. 07700 900123", text: $phone)
                            .keyboardType(.phonePad)
                            .padding(14)
                            .background(Theme.card)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Theme.hairline, lineWidth: 1)
                            )
                    }

                    // Contact preference picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CONTACT PREFERENCE")
                            .font(Theme.ui(12, weight: .semibold))
                            .foregroundStyle(Theme.textMuted)

                        // Show all three options as buttons
                        HStack(spacing: 10) {
                            ForEach(Resident.ContactPreference.allCases, id: \.self) { option in
                                Button(option.rawValue) {
                                    preference = option
                                }
                                .font(Theme.ui(13, weight: .semibold))
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .foregroundStyle(
                                    preference == option ? Theme.ink : Theme.textMuted
                                )
                                .background(
                                    preference == option ? Theme.brass : Theme.card
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Theme.hairline, lineWidth: 1)
                                )
                            }
                        }
                    }

                    // Show unit toggle
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Show unit to neighbours")
                                .font(Theme.ui(14, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                            Text("Others can see your unit number on posts")
                                .font(Theme.ui(12))
                                .foregroundStyle(Theme.textMuted)
                        }
                        Spacer()
                        Toggle("", isOn: $showUnit)
                            .labelsHidden()
                            .tint(Theme.brass)
                    }
                    .padding(14)
                    .background(Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Theme.hairline, lineWidth: 1)
                    )

                    // Submit button
                    Button("Join the Building") {
                        store.completeProfileSetup(
                            name: name,
                            unit: unit,
                            phone: phone,
                            preference: preference,
                            showUnit: showUnit
                        )
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    // Only active when name and unit are filled in
                    .disabled(name.isEmpty || unit.isEmpty)
                    .opacity(name.isEmpty || unit.isEmpty ? 0.5 : 1)

                }
                .padding(16)
            }
        }
    }
}

#Preview {
    ProfileSetupView().environmentObject(AppStore())
}
