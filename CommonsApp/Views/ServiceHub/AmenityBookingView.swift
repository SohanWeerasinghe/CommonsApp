import SwiftUI

struct AmenityBookingView: View {
    @EnvironmentObject private var store: AppStore
    let amenity: Amenity
    @State private var selectedDate = Date()
    @State private var processingID: String?
    @State private var confirmedSlot: BookingSlot?
    @State private var showConfirmation = false
    @State private var errorText: String?

    private var daySlots: [BookingSlot] {
        store.getSlots(for: amenity).filter {
            Calendar.current.isDate($0.start, inSameDayAs: selectedDate)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("GYM RESERVATIONS")
                        .font(Theme.ui(11, weight: .bold))
                        .tracking(1.3).foregroundStyle(Theme.appPurple)
                    Text("Make time for you")
                        .font(Theme.display(29, weight: .bold))
                        .foregroundStyle(Theme.appNavy)
                    Text("Reserve a one-hour workout. Capacity is set by building management.")
                        .font(Theme.ui(13)).foregroundStyle(Theme.appMuted)
                }
                .padding(.top, 14)

                HStack(spacing: 12) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 28)).foregroundStyle(Theme.appPurple)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Community Gym").font(Theme.ui(17, weight: .bold))
                            .foregroundStyle(Theme.appNavy)
                        Text("Maximum \(store.gymCapacity) residents per session")
                            .font(Theme.ui(12)).foregroundStyle(Theme.appMuted)
                    }
                    Spacer()
                }
                .padding(18)
                .background(Theme.appPurpleSoft, in: RoundedRectangle(cornerRadius: 20))

                DatePicker("Choose date", selection: $selectedDate,
                           in: Date()...Calendar.current.date(byAdding: .day, value: 13, to: Date())!,
                           displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .font(Theme.ui(14, weight: .semibold))
                    .foregroundStyle(Theme.appNavy)
                    .tint(Theme.appPurple)

                if let error = store.gymError {
                    Text(error).foregroundStyle(.red).font(.caption)
                }
                Text("Available sessions")
                    .font(Theme.display(20, weight: .bold))
                    .foregroundStyle(Theme.appNavy)

                if daySlots.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 30)).foregroundStyle(Theme.appMuted)
                        Text("No Gym sessions configured for this day")
                            .font(Theme.ui(13)).foregroundStyle(Theme.appMuted)
                        Text("Building management can publish upcoming sessions.")
                            .font(Theme.ui(11)).foregroundStyle(Theme.appMuted)
                    }
                    .frame(maxWidth: .infinity).padding(30)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 18))
                }

                ForEach(daySlots) { slot in
                    let key = slot.firestoreId ?? ""
                    let used = store.gymOccupancy[key] ?? 0
                    let mine = store.gymMySlotIDs.contains(key)
                    let remaining = max(0, store.gymCapacity - used)
                    HStack(spacing: 12) {
                        Image(systemName: "clock.fill")
                            .foregroundStyle(Theme.appPurple)
                            .frame(width: 32)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(slot.start.formatted(date: .omitted, time: .shortened))
                                .font(Theme.ui(15, weight: .bold))
                                .foregroundStyle(Theme.appNavy)
                            Text(mine ? "Your reservation" : "\(remaining) spaces remaining")
                                .font(Theme.ui(11))
                                .foregroundStyle(mine ? Theme.appGreen : Theme.appMuted)
                        }
                        Spacer()
                        Button {
                            guard processingID == nil else { return }
                            processingID = key
                            Task { @MainActor in
                                defer { processingID = nil }
                                do {
                                    try await store.reserveGymSlot(slot, cancel: mine)

                                    if !mine {
                                        confirmedSlot = slot
                                        showConfirmation = true
                                    }
                                } catch {
                                    HapticManager.error()
                                    errorText = error.localizedDescription
                                }
                            }
                        } label: {
                            Text(processingID == key ? "Wait…" : mine ? "Cancel" : "Book")
                                .font(Theme.ui(12, weight: .bold))
                                .foregroundStyle(mine ? Theme.appNavy : .white)
                                .padding(.horizontal, 17).padding(.vertical, 11)
                                .background(mine ? Theme.appPurpleSoft : Theme.appPurple,
                                            in: Capsule())
                        }
                        .disabled(processingID != nil || (!mine && remaining == 0))
                    }
                    .padding(14)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 17))
                }
                Text("Your booked sessions are marked above. Cancel before the session starts to release your space.")
                    .font(Theme.ui(11)).foregroundStyle(Theme.appMuted)
            }
            .padding(.horizontal, Theme.screenPadding)
            .padding(.bottom, 32)
        }
        .background(Theme.wallBackgroundBottom.ignoresSafeArea())
        .navigationTitle("Gym booking")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showConfirmation) {
            if let slot = confirmedSlot {
                BookingConfirmedView(amenity: amenity, slot: slot)
            }
        }
        .alert("Booking unsuccessful", isPresented: Binding(
            get: { errorText != nil }, set: { if !$0 { errorText = nil } }
        )) { Button("OK", role: .cancel) { errorText = nil } }
        message: { Text(errorText ?? "Please try again.") }
    }
}
