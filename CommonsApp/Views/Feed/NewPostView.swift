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
                }

                // Post button — top right
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        store.addPost(
                            text: text,
                            category: category,
                            hasPhoto: hasPhoto
                        )
                        dismiss()
                    }
                    // Only active when something is typed
                    .disabled(text.isEmpty)
                }
            }
        }
    }
}

#Preview {
    NewPostView().environmentObject(AppStore())
}

