//
//  PostDetailView.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 26/9/2026.
//

import SwiftUI

struct PostDetailView: View {

    @EnvironmentObject var store: AppStore
    let post: Post

    var body: some View {
        ZStack {
            Theme.paper.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // Full post card at the top
                    PlaqueCard {
                        VStack(alignment: .leading, spacing: 10) {

                            HStack(spacing: 10) {
                                UnitBadge(unit: post.authorUnit)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(post.authorName)
                                        .font(Theme.ui(14, weight: .semibold))
                                        .foregroundStyle(Theme.textPrimary)

                                    Text(post.timestamp.relativeDescription)
                                        .font(Theme.ui(11.5))
                                        .foregroundStyle(Theme.textMuted)
                                }

                                Spacer()
                                Pill(text: post.category.rawValue)
                            }

                            // Full text — no line limit here
                            Text(post.text)
                                .font(Theme.ui(14))
                                .foregroundStyle(Theme.textPrimary)

                            // Like button
                            Button {
                                store.toggleLike(post)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "heart")
                                    Text("\(post.likeCount) likes")
                                }
                                .font(Theme.ui(13))
                                .foregroundStyle(Theme.textMuted)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    // Replies section
                    SectionHeader(title: "Replies")
                        .padding(.horizontal, 16)

                    // Placeholder reply count message
                    Text("\(post.replyCount) replies from neighbours")
                        .font(Theme.ui(13))
                        .foregroundStyle(Theme.textMuted)
                        .padding(.horizontal, 16)
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PostDetailView(post: AppStore().posts[0])
    }
    .environmentObject(AppStore())
}
