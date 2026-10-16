//
//  NewPostView.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 21/9/2026.
//

import SwiftUI

struct NewPostView: View {

    @EnvironmentObject var store: AppStore

    // dismiss lets us close this sheet
    @Environment(\.dismiss) private var dismiss

    @State private var text = ""
    @State private var category: Post.Category = .news
    @State private var hasPhoto = false
    @State private var showAuthorName = true
    @State private var showAuthorUnit = false
    @State private var isSaving = false
    @State private var postError = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.paper.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {

                        // Category picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CATEGORY")
                                .font(Theme.ui(12, weight: .semibold))
                                .foregroundStyle(Theme.textMuted)

                            // Show all categories as buttons
                            HStack(spacing: 10) {
                                ForEach(Post.Category.allCases, id: \.self) { option in
                                    Button(option.rawValue) {
                                        category = option
                                    }
                                    .font(Theme.ui(12, weight: .semibold))
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .foregroundStyle(
                                        category == option ? Theme.ink : Theme.textMuted
                                    )
                                    .background(
                                        category == option ? Theme.brass : Theme.card
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Theme.hairline, lineWidth: 1)
                                    )
                                }
                            }
                        }

                        // Text input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("YOUR POST")
                                .font(Theme.ui(12, weight: .semibold))
                                .foregroundStyle(Theme.textMuted)

                            TextEditor(text: $text)
                                .foregroundColor(.gray)
                                .frame(height: 160)
                                .padding(8)
                                .scrollContentBackground(.hidden)
                                .background(Theme.card)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Theme.hairline, lineWidth: 1)
                                )
                        }
                        // Post privacy settings
                        VStack(alignment: .leading, spacing: 12) {

                            Text("POST PRIVACY")
                                .font(Theme.ui(12, weight: .semibold))
                                .foregroundStyle(Theme.textMuted)

                            Toggle(isOn: $showAuthorName) {
                                    Label("Show my name", systemImage: "person.crop.circle")
                                        .foregroundColor(.black)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(.primary)
                                }
                                .tint(.purple)

                                Divider()

                                Toggle(isOn: $showAuthorUnit) {
                                    Label("Show my apartment/unit", systemImage: "house")
                                        .foregroundColor(.black)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(.primary)
                                }
                                .tint(.purple)
                                .disabled(
                                    !showAuthorName ||
                                    !store.currentResident.showUnitToNeighbors
                                )

                            if !showAuthorName {
                                Text("Your post will appear as Anonymous User.")
                                    .font(Theme.ui(12))
                                    .foregroundStyle(Theme.textMuted)
                            }

                            if !store.currentResident.showUnitToNeighbors {
                                Text("Your profile privacy setting hides your apartment/unit.")
                                    .font(Theme.ui(12))
                                    .foregroundStyle(Theme.textMuted)
                            }
                        }
                        .tint(Theme.sage)
                        .padding(14)
                        .background(Theme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Theme.hairline, lineWidth: 1)
                        }

                        // Photo toggle button
                        Button {
                            hasPhoto.toggle()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: hasPhoto
                                      ? "checkmark.circle.fill"
                                      : "camera")
                                    .foregroundStyle(
                                        hasPhoto ? Theme.sage : Theme.textMuted
                                    )
                                Text(hasPhoto ? "Photo added" : "Add a photo")
                                    .font(Theme.ui(13))
                                    .foregroundStyle(Theme.textMuted)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.card)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Theme.hairline, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Cancel button — top left
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .alert(
                        "Unable to Publish Post",
                        isPresented: Binding(
                            get: { !postError.isEmpty },
                            set: { if !$0 { postError = "" } }
                        )
                    ) {
                        Button("OK", role: .cancel) {
                            postError = ""
                        }
                    } message: {
                        Text(postError)
                    }
                }

                // Post button — top right
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        guard !isSaving else { return }

                        isSaving = true
                        postError = ""

                        Task {
                            do {
                                try await store.saveResidentPostToFirestore(
                                    text: text,
                                    category: category,
                                    showAuthorName: showAuthorName,
                                    showAuthorUnit: showAuthorUnit
                                )

                                store.addPost(
                                    text: text,
                                    category: category,
                                    hasPhoto: false
                                )

                                isSaving = false
                                dismiss()
                            } catch {
                                postError = error.localizedDescription
                                isSaving = false
                            }
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Post")
                        }
                    }
                    .disabled(
                        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        || text.count > 2000
                        || category == .announcement
                        || isSaving
                    )
                }
            }
        }
    }
}

#Preview {
    NewPostView().environmentObject(AppStore())
}

