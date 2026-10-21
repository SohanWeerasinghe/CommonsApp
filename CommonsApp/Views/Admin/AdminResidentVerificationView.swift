import SwiftUI

struct AdminResidentVerificationView: View {
    @EnvironmentObject var store: AppStore
    @State private var isLoadingResidents = false
    @State private var residentsError = ""
    @State private var processingResidentID: String? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                verificationContent
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AdminPalette.background.ignoresSafeArea())
        .navigationTitle("Resident Verification")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            isLoadingResidents = true
            residentsError = ""
            store.pendingResidents = []
            defer { isLoadingResidents = false }
            do { try await store.loadPendingResidents() }
            catch { residentsError = error.localizedDescription }
        }

    }
    private var verificationContent: some View {
        VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Pending Verification")
                        // Empty state
                        if store.pendingResidents.isEmpty {
                            PlaqueCard {
                                HStack(spacing: 12) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundStyle(Theme.sage)
                                        .font(.system(size: 24))
                                    Text("All residents verified")
                                        .font(Theme.ui(14))
                                        .foregroundStyle(Theme.textMuted)
                                }
                            }
                        } else {
                            ForEach(store.pendingResidents) { resident in
                                PlaqueCard {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(resident.name)
                                            .font(Theme.ui(15, weight: .semibold))
                                            .foregroundStyle(Theme.textPrimary)
                                        Text("Unit: \(resident.unit)")
                                            .font(Theme.ui(13))
                                            .foregroundStyle(Theme.textMuted)
                                        Text("Application pending")
                                            .font(Theme.ui(12))
                                            .foregroundStyle(Theme.textMuted)
                                        //Approve decline buttons for pending residents
                                        HStack(spacing: 12) {
                                            Button("Approve") {
                                                guard processingResidentID == nil else { return }
                                                processingResidentID = resident.id
                                                residentsError = ""
                                                Task {
                                                    defer { processingResidentID = nil }
                                                    do {
                                                        try await store.updateResidentApproval(
                                                            residentID: resident.id,
                                                            approve: true
                                                        )
                                                    } catch {
                                                        residentsError = error.localizedDescription
                                                    }
                                                }
                                            }
                                            .buttonStyle(.borderedProminent)
                                            .tint(.green)
                                            .disabled(processingResidentID != nil)
                                            Button("Decline") {
                                                guard processingResidentID == nil else { return }
                                                processingResidentID = resident.id
                                                residentsError = ""
                                                Task {
                                                    defer { processingResidentID = nil }
                                                    do {
                                                        try await store.updateResidentApproval(
                                                            residentID: resident.id,
                                                            approve: false
                                                        )
                                                    } catch {
                                                        residentsError = error.localizedDescription
                                                    }
                                                }
                                            }
                                            .buttonStyle(.bordered)
                                            .tint(.red)
                                            .disabled(processingResidentID != nil)
                                            if processingResidentID == resident.id {
                                                ProgressView()
                                            }
                                        }
                                        .padding(.top, 8)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                if isLoadingResidents {
                                    ProgressView("Loading resident applications...")
                                }
                                if !residentsError.isEmpty {
                                    Text(residentsError)
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                    }
    }
}
