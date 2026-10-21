import SwiftUI

struct AdminMaintenanceView: View {
    @EnvironmentObject var store: AppStore
    @State private var maintenanceUpdateError: String?
    @State private var updatingMaintenanceId: UUID?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                maintenanceManagement
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AdminPalette.background.ignoresSafeArea())
        .navigationTitle("Maintenance")
        .navigationBarTitleDisplayMode(.inline)


    }
    private var maintenanceManagement: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Maintenance Requests")
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(AdminPalette.ink)
            if let error = store.maintenanceError {
                Text(error).foregroundStyle(.red)
            }
            if store.maintenanceRequests.isEmpty {
                Text("No maintenance requests yet.")
                    .foregroundStyle(AdminPalette.muted)
            }
            ForEach(store.maintenanceRequests) { request in
                VStack(alignment: .leading, spacing: 8) {
                    Text(request.title).font(.headline).foregroundStyle(AdminPalette.ink)
                    Text("Unit: \(request.unit) · \(request.stage.label)")
                        .font(.caption).foregroundStyle(AdminPalette.muted)
                    Text(request.details).font(.subheadline).foregroundStyle(AdminPalette.ink)
                    if request.stage != .complete {
                        Button(updatingMaintenanceId == request.id ? "Updating…" : "Advance to next stage") {
                            guard updatingMaintenanceId == nil else { return }
                            updatingMaintenanceId = request.id
                            Task { @MainActor in
                                defer { updatingMaintenanceId = nil }
                                do { try await store.advanceStage(of: request) }
                                catch { maintenanceUpdateError = error.localizedDescription }
                            }
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AdminPalette.purple)
                        .disabled(updatingMaintenanceId != nil)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white, in: RoundedRectangle(cornerRadius: 14))
            }
        }
        .alert("Maintenance update failed", isPresented: Binding(
            get: { maintenanceUpdateError != nil },
            set: { if !$0 { maintenanceUpdateError = nil } }
        )) {
            Button("OK", role: .cancel) { maintenanceUpdateError = nil }
        } message: {
            Text(maintenanceUpdateError ?? "Unknown error")
        }
    }
}
