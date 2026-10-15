//
//  BookingConfirmedView.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 26/9/2026.
//

import SwiftUI

struct BookingConfirmedView: View {

    let amenity: Amenity
    let slot: BookingSlot

    var body: some View {
        ZStack {
            Theme.paper.ignoresSafeArea()

            VStack(spacing: 32) {

                Spacer()

                // Big checkmark
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(Theme.sage)

                // Confirmation text
                VStack(spacing: 10) {
                    Text("Booking Confirmed")
                        .font(Theme.display(26))
                        .foregroundStyle(Theme.textPrimary)

                    Text("\(amenity.name) · \(slotTimeText())")
                        .font(Theme.ui(16))
                        .foregroundStyle(Theme.textMuted)
                }

                // Info box
                VStack(spacing: 8) {
                    HStack(spacing: 10) {
                        Image(systemName: "bell.fill")
                            .foregroundStyle(Theme.brass)
                        Text("You will get a reminder\n30 minutes before your slot")
                            .font(Theme.ui(13))
                            .foregroundStyle(Theme.textMuted)
                    }
                    .padding(14)
                    .background(Theme.brass.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal, 32)

                Spacer()
            }
        }
        .navigationTitle("Confirmed")
        .navigationBarTitleDisplayMode(.inline)
    }

    // Format the booking time
    func slotTimeText() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: slot.start)
    }
}
