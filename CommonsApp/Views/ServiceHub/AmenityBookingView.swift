//
//  AmenityBookingView.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 21/9/2026.
//

import SwiftUI

struct AmenityBookingView: View {

    @EnvironmentObject var store: AppStore

    let amenity: Amenity

    @State private var bookedSlot: BookingSlot? = nil
    @State private var showConfirmation = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.wallBackgroundTop, Theme.wallBackgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    VStack(alignment: .leading, spacing: 6) {
                        Text("BOOK AMENITY")
                            .font(Theme.ui(10, weight: .bold))
                            .foregroundStyle(Theme.appMuted)
                            .tracking(1.2)

                        Text(amenity.name)
                            .font(Theme.display(27, weight: .bold))
                            .foregroundStyle(Theme.appNavy)

                        Text(amenity.subtitle)
                            .font(Theme.ui(13))
                            .foregroundStyle(Theme.appMuted)
                    }

                    ZStack(alignment: .bottomLeading) {
                        LinearGradient(
                            colors: [
                                Theme.appPurple.opacity(0.20),
                                Theme.info.opacity(0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )

                        Image(systemName: amenityIcon())
                            .font(.system(size: 60, weight: .light))
                            .foregroundStyle(Theme.appPurple.opacity(0.55))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.appGreen)

                            Text("Available to residents")
                                .font(Theme.ui(11, weight: .semibold))
                                .foregroundStyle(Theme.appNavy)
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 34)
                        .background(Theme.card.opacity(0.92))
                        .clipShape(Capsule())
                        .padding(14)
                    }
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .padding(.top, 20)

                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Theme.appPurpleSoft)
                                .frame(width: 44, height: 44)

                            Image(systemName: "calendar")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(Theme.appPurple)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("BOOKING DATE")
                                .font(Theme.ui(9, weight: .bold))
                                .foregroundStyle(Theme.appMuted)

                            Text(todayText())
                                .font(Theme.ui(14, weight: .bold))
                                .foregroundStyle(Theme.appNavy)
                        }

                        Spacer()
                    }
                    .padding(14)
                    .background(Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Theme.appBorder, lineWidth: 1)
                    }
                    .padding(.top, 16)

                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Available times")
                                .font(Theme.display(18, weight: .bold))
                                .foregroundStyle(Theme.appNavy)

                            Text("Choose a time that works for you")
                                .font(Theme.ui(11))
                                .foregroundStyle(Theme.appMuted)
                        }

                        Spacer()
                    }
                    .padding(.top, 26)

                    let availableSlots = store.getSlots(for: amenity)

                    if availableSlots.isEmpty {
                        AppEmptyState(
                            icon: "calendar.badge.exclamationmark",
                            title: "No slots available",
                            message: "There are no booking slots available today."
                        )
                        .padding(.top, 14)

                    } else {
                        VStack(spacing: 10) {
                            ForEach(availableSlots) { slot in
                                SlotRow(
                                    slot: slot,
                                    onBook: {
                                        store.book(slot)
                                        bookedSlot = slot
                                        showConfirmation = true
                                    }
                                )
                            }
                        }
                        .padding(.top, 14)
                    }

                   HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Theme.appPurple)

                        Text("Your booking will be confirmed immediately after you choose an available time.")
                            .font(Theme.ui(11))
                            .foregroundStyle(Theme.appMuted)
                            .lineSpacing(2)

                        Spacer()
                    }
                    .padding(14)
                    .background(Theme.appPurpleSoft.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .padding(.top, 20)
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.top, 14)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Book amenity")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showConfirmation) {
            if let slot = bookedSlot {
                BookingConfirmedView(
                    amenity: amenity,
                    slot: slot
                )
            }
        }
    }

    func amenityIcon() -> String {
        let name = amenity.name.lowercased()

        if name.contains("roof") {
            return "sun.horizon.fill"
        }

        if name.contains("gym") || name.contains("fitness") {
            return "figure.strengthtraining.traditional"
        }

        if name.contains("room") || name.contains("lounge") {
            return "sofa.fill"
        }

        if name.contains("garden") {
            return "leaf.fill"
        }

        return "building.2.fill"
    }

    func todayText() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
}

private struct SlotRow: View {

    let slot: BookingSlot
    let onBook: () -> Void

    var body: some View {
        HStack(spacing: 12) {

            ZStack {
                RoundedRectangle(cornerRadius: 11)
                    .fill(
                        slot.isBooked
                        ? Theme.paper
                        : Theme.appPurpleSoft
                    )
                    .frame(width: 42, height: 42)

                Image(systemName: "clock")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(
                        slot.isBooked
                        ? Theme.appMuted
                        : Theme.appPurple
                    )
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(slotTimeText())
                    .font(Theme.ui(14, weight: .bold))
                    .foregroundStyle(
                        slot.isBooked
                        ? Theme.appMuted
                        : Theme.appNavy
                    )

                Text(slot.isBooked ? "Not available" : "Available")
                    .font(Theme.ui(10, weight: .medium))
                    .foregroundStyle(
                        slot.isBooked
                        ? Theme.appMuted
                        : Theme.appGreen
                    )
            }

            Spacer()

            if slot.isBooked {
                Text("Booked")
                    .font(Theme.ui(11, weight: .semibold))
                    .foregroundStyle(Theme.appMuted)
                    .padding(.horizontal, 13)
                    .frame(height: 32)
                    .background(Theme.paper)
                    .clipShape(Capsule())

            } else {
                Button {
                    onBook()
                } label: {
                    Text("Book")
                        .font(Theme.ui(11, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .frame(height: 34)
                        .background(Theme.appPurple)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(13)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 17))
        .overlay {
            RoundedRectangle(cornerRadius: 17)
                .stroke(Theme.appBorder, lineWidth: 1)
        }
        .opacity(slot.isBooked ? 0.7 : 1)
    }

    func slotTimeText() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: slot.start)
    }
}
