import SwiftUI

struct AdminAnnouncementsView: View {
    @EnvironmentObject var store: AppStore
    @State private var announcementText = ""
    @State private var didPin = false
    @State private var isSavingAnnouncement = false
    @State private var announcementError = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                announcementContent
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AdminPalette.background.ignoresSafeArea())
        .navigationTitle("Announcements")
        .navigationBarTitleDisplayMode(.inline)


    }
    private var announcementContent: some View {
        VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Pin Announcement")
                        PlaqueCard {
                            VStack(alignment: .leading, spacing: 14) {
                                // Current pinned announcement
                                if !store.pinnedAnnouncementText.isEmpty {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("CURRENTLY PINNED")
                                            .font(Theme.ui(10, weight: .semibold))
                                            .foregroundStyle(Theme.textMuted)
                                        Text(store.pinnedAnnouncementText)
                                            .font(Theme.ui(13))
                                            .foregroundStyle(Theme.textPrimary)
                                    }
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Theme.clay.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    Divider()
                                }
                                // New announcement text box
                                Text("NEW ANNOUNCEMENT")
                                    .font(Theme.ui(10, weight: .semibold))
                                    .foregroundStyle(Theme.textMuted)
                                TextEditor(text: $announcementText)
                                    .frame(height: 100)
                                    .padding(8)
                                    .scrollContentBackground(.hidden)
                                    .background(Theme.paper)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Theme.hairline, lineWidth: 1)
                                    )
                                // Pin button
                                Button {
                                    pinAnnouncement()
                                } label: {
                                    HStack(spacing: 8) {
                                        if isSavingAnnouncement {
                                            ProgressView()
                                        }
                                        Text(isSavingAnnouncement ? "Saving..." : "Pin to Building Wall")
                                    }
                                }
                                .buttonStyle(PrimaryButtonStyle())
                                .disabled(
                                    isSavingAnnouncement ||
                                    announcementText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                )
                                .opacity(
                                    isSavingAnnouncement ||
                                    announcementText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    ? 0.5 : 1
                                )
                                if !announcementError.isEmpty {
                                    Text(announcementError)
                                        .font(Theme.ui(12))
                                        .foregroundStyle(.red)
                                }
                                // Success confirmation
                                if didPin {
                                    HStack(spacing: 6) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Theme.sage)
                                        Text("Pinned to the Building Wall")
                                            .font(Theme.ui(13))
                                            .foregroundStyle(Theme.sage)
                                    }
                                }
                            }
                        }
                    }
    }
    func pinAnnouncement() {
        let text = announcementText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !text.isEmpty, !isSavingAnnouncement else { return }
        isSavingAnnouncement = true
        announcementError = ""
        didPin = false
        Task {
            defer {
                isSavingAnnouncement = false
            }
            do {
                try await store.saveAnnouncementToFirestore(text)
                // Preserve the existing Building Wall and widget behavior.
                store.pinAnnouncement(text)
                didPin = true
                announcementText = ""
            } catch {
                announcementError = error.localizedDescription
            }
        }
    }
}
