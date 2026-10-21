import SwiftUI

struct AdminGymManagementView: View {
    @EnvironmentObject var store: AppStore
    @State private var gymCapacityInput = ""
    @State private var gymAdminError: String?
    @State private var gymAdminMessage: String?
    @State private var gymBusy = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                gymManagement
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AdminPalette.background.ignoresSafeArea())
        .navigationTitle("Gym Management")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { gymCapacityInput = String(store.gymCapacity) }

    }
    private var gymManagement: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Gym Management")
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(AdminPalette.ink)
            Text("Current limit: \(store.gymCapacity) residents per time slot")
                .font(.subheadline)
                .foregroundStyle(AdminPalette.muted)
            HStack {
                TextField("Maximum residents", text: $gymCapacityInput)
                    .keyboardType(.numberPad)
                    .onChange(of: gymCapacityInput) { _, _ in gymAdminError = nil }
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundColor(AdminPalette.ink)
                    .preferredColorScheme(.light)
                    .tint(.purple)
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                Button("Save capacity") {
                    guard let value = Int(gymCapacityInput) else {
                        gymAdminError = "Enter a whole number from 1 to 100."
                        return
                    }
                    gymBusy = true
                    Task { @MainActor in
                        defer { gymBusy = false }
                        do { try await store.setGymCapacity(value); gymAdminMessage = "Capacity updated." }
                        catch { gymAdminError = error.localizedDescription }
                    }
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(AdminPalette.purple, in: RoundedRectangle(cornerRadius: 12))
                .disabled(gymBusy)
            }
            Button(gymBusy ? "Preparing sessions…" : "Publish next 14 days of Gym sessions") {
                gymBusy = true
                Task { @MainActor in
                    defer { gymBusy = false }
                    do {
                        try await store.prepareGymSlots()
                        gymAdminMessage = "Gym sessions published. Existing reservations were preserved."
                    } catch { gymAdminError = error.localizedDescription }
                }
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(AdminPalette.purple)
            .disabled(gymBusy)
            Text("Sessions: 9 AM–9 PM, one hour each. Publish again to extend availability; existing reservations are not reset.")
                .font(.caption).foregroundStyle(AdminPalette.muted)
            if let message = gymAdminMessage { Text(message).font(.caption).foregroundStyle(.green) }
            if let error = gymAdminError { Text(error).font(.caption).foregroundStyle(.red) }
            ForEach(Array(store.bookingSlots.prefix(12))) { slot in
                if let id = slot.firestoreId {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(slot.start.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AdminPalette.ink)
                        Text("\(store.gymOccupancy[id] ?? 0) / \(store.gymCapacity) reserved")
                            .font(.caption).foregroundStyle(AdminPalette.muted)
                        if let members = store.gymMembersBySlot[id], !members.isEmpty {
                            Text("Resident IDs: " + members.joined(separator: ", "))
                                .font(.caption2).foregroundStyle(AdminPalette.muted)
                                .textSelection(.enabled)
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white, in: RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(16)
        .background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 18))
    }
}
