//
//  ChatListView.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 21/9/2026.
//

import SwiftUI

struct ChatListView: View {

    @EnvironmentObject var store: AppStore
    @State private var searchText = ""

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

                    // Header
                    ChatHeader()

                    // Search
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Theme.appMuted)

                        TextField("Search messages...", text: $searchText)
                            .font(Theme.ui(14))
                            .foregroundStyle(Theme.appNavy)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 48)
                    .background(Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Theme.appBorder, lineWidth: 1)
                    }
                    .padding(.top, 20)

                    let visibleThreads = filteredThreads()

                    if store.chatThreads.isEmpty {
                        AppEmptyState(
                            icon: "bubble.left.and.bubble.right",
                            title: "No messages yet",
                            message: "Message a neighbour from the Lend & Borrow screen."
                        )
                        .padding(.top, 60)

                    } else {
                        // Resident shortcuts
                        ResidentShortcuts(threads: store.chatThreads)
                            .padding(.top, 18)

                        Text("MESSAGES")
                            .font(Theme.ui(10, weight: .bold))
                            .foregroundStyle(Theme.appMuted)
                            .padding(.top, 26)
                            .padding(.bottom, 10)

                        if visibleThreads.isEmpty {
                            Text("No conversations found")
                                .font(Theme.ui(14))
                                .foregroundStyle(Theme.appMuted)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 40)

                        } else {
                            VStack(spacing: 10) {
                                ForEach(visibleThreads) { thread in
                                    NavigationLink {
                                        ChatDetailView(thread: thread)
                                    } label: {
                                        ThreadRow(thread: thread)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 125)
            }
            .scrollIndicators(.hidden)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    func filteredThreads() -> [ChatThread] {
        if searchText.isEmpty {
            return store.chatThreads
        }

        var results: [ChatThread] = []

        for thread in store.chatThreads {
            let nameMatches = thread.neighborName.localizedCaseInsensitiveContains(searchText)
            let unitMatches = thread.neighborUnit.localizedCaseInsensitiveContains(searchText)

            var messageMatches = false

            if let lastMessage = thread.lastMessage {
                messageMatches = lastMessage.text.localizedCaseInsensitiveContains(searchText)
            }

            if nameMatches || unitMatches || messageMatches {
                results.append(thread)
            }
        }

        return results
    }
}

private struct ChatHeader: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("24 ASHCROFT LANE")
                .font(Theme.ui(10, weight: .bold))
                .foregroundStyle(Theme.appMuted)

            Text("Chat")
                .font(Theme.display(28, weight: .bold))
                .foregroundStyle(Theme.appNavy)
        }
    }
}

private struct ResidentShortcuts: View {

    let threads: [ChatThread]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(threads.prefix(5)) { thread in
                    NavigationLink {
                        ChatDetailView(thread: thread)
                    } label: {
                        VStack(spacing: 6) {
                            UnitBadge(unit: thread.neighborUnit, size: 48)

                            Text(thread.neighborUnit)
                                .font(Theme.ui(10, weight: .semibold))
                                .foregroundStyle(Theme.appMuted)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct ThreadRow: View {

    let thread: ChatThread

    var body: some View {
        HStack(spacing: 12) {

            UnitBadge(unit: thread.neighborUnit, size: 48)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(thread.neighborName)
                        .font(Theme.ui(14, weight: .bold))
                        .foregroundStyle(Theme.appNavy)
                        .lineLimit(1)

                    Spacer()

                    if let lastMessage = thread.lastMessage {
                        Text(lastMessage.timestamp.relativeDescription)
                            .font(Theme.ui(9))
                            .foregroundStyle(Theme.appMuted)
                    }
                }

                if let note = thread.contextNote {
                    Text(note)
                        .font(Theme.ui(10, weight: .semibold))
                        .foregroundStyle(Theme.appPurple)
                        .lineLimit(1)
                }

                if let lastMessage = thread.lastMessage {
                    Text(lastMessage.text)
                        .font(Theme.ui(12))
                        .foregroundStyle(Theme.appMuted)
                        .lineLimit(1)
                } else {
                    Text("Start a conversation")
                        .font(Theme.ui(12))
                        .foregroundStyle(Theme.appMuted)
                }
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.appTertiary)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Theme.card.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(Theme.appBorder, lineWidth: 1)
        }
    }
}

#Preview {
    NavigationStack {
        ChatListView()
            .environmentObject(AppStore())
    }
}
