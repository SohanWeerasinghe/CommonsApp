//
//  ChatListView.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 21/9/2026.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ChatListView: View {
    @EnvironmentObject var store: AppStore
    @State private var searchText = ""
    @State private var showingNewChat = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.wallBackgroundTop, Theme.wallBackgroundBottom], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        ChatHeader()
                        Spacer()
                        Button { showingNewChat = true } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 19, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 46, height: 46)
                                .background(Theme.appPurple)
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("New Chat")
                    }

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
                    .overlay { RoundedRectangle(cornerRadius: 16).stroke(Theme.appBorder, lineWidth: 1) }
                    .padding(.top, 20)

                    let visibleThreads = filteredThreads()
                    if store.chatThreads.isEmpty {
                        AppEmptyState(icon: "bubble.left.and.bubble.right", title: "No messages yet", message: "Tap + to find a neighbour and start a chat.")
                            .padding(.top, 60)
                    } else {
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
                                    NavigationLink { ChatDetailView(thread: thread) } label: {
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
        .onAppear { store.startChatThreadsListener() }
        .sheet(isPresented: $showingNewChat) {
            NewChatSheet()
                .environmentObject(store)
        }
    }

    private func filteredThreads() -> [ChatThread] {
        guard !searchText.isEmpty else { return store.chatThreads }
        return store.chatThreads.filter { thread in
            thread.neighborName.localizedCaseInsensitiveContains(searchText)
            || thread.neighborUnit.localizedCaseInsensitiveContains(searchText)
            || (thread.lastMessage?.text.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
}

private struct DirectoryResident: Identifiable {
    let id: String
    let name: String
    let unit: String
}

private struct NewChatSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var residents: [DirectoryResident] = []
    @State private var loading = true
    @State private var startingUID: String?
    @State private var errorMessage: String?
    @State private var selectedThread: ChatThread?

    private var filteredResidents: [DirectoryResident] {
        guard !searchText.isEmpty else { return residents }
        return residents.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
            || $0.unit.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Theme.wallBackgroundTop, Theme.wallBackgroundBottom], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Find a neighbour")
                                .font(Theme.display(24, weight: .bold))
                                .foregroundStyle(Theme.appNavy)
                            Text("Choose an approved resident to start a conversation.")
                                .font(Theme.ui(13))
                                .foregroundStyle(Theme.appMuted)
                        }
                        .padding(.top, 12)

                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(Theme.appMuted)
                            TextField("Search residents...", text: $searchText)
                                .font(Theme.ui(14))
                                .foregroundStyle(Theme.appNavy)
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 48)
                        .background(Theme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay { RoundedRectangle(cornerRadius: 16).stroke(Theme.appBorder, lineWidth: 1) }

                        if loading {
                            ProgressView("Loading residents...")
                                .frame(maxWidth: .infinity)
                                .padding(.top, 35)
                        } else if filteredResidents.isEmpty {
                            AppEmptyState(icon: "person.2", title: "No residents found", message: "Try another name or unit.")
                                .padding(.top, 30)
                        } else {
                            Text("APPROVED RESIDENTS")
                                .font(Theme.ui(10, weight: .bold))
                                .foregroundStyle(Theme.appMuted)
                            ForEach(filteredResidents) { resident in
                                Button {
                                    Task { await startChat(with: resident) }
                                } label: {
                                    HStack(spacing: 12) {
                                        ChatResidentAvatar(name: resident.name, unit: resident.unit, size: 48)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(resident.name)
                                                .font(Theme.ui(14, weight: .bold))
                                                .foregroundStyle(Theme.appNavy)
                                            if !resident.unit.isEmpty {
                                                Text(resident.unit)
                                                    .font(Theme.ui(12))
                                                    .foregroundStyle(Theme.appMuted)
                                            }
                                        }
                                        Spacer()
                                        if startingUID == resident.id {
                                            ProgressView()
                                        } else {
                                            Image(systemName: "bubble.left.and.bubble.right")
                                                .foregroundStyle(Theme.appPurple)
                                        }
                                    }
                                    .padding(14)
                                    .background(Theme.card.opacity(0.9))
                                    .clipShape(RoundedRectangle(cornerRadius: 18))
                                    .overlay { RoundedRectangle(cornerRadius: 18).stroke(Theme.appBorder, lineWidth: 1) }
                                }
                                .buttonStyle(.plain)
                                .disabled(startingUID != nil)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("New Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task { await loadResidents() }
            .alert("Chat error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .navigationDestination(isPresented: Binding(
                get: { selectedThread != nil },
                set: { if !$0 { selectedThread = nil } }
            )) {
                if let thread = selectedThread {
                    ChatDetailView(thread: thread)
                }
            }
        }
    }

    @MainActor
    private func loadResidents() async {
        loading = true
        defer { loading = false }
        do {
            let snapshot = try await Firestore.firestore().collection("residentDirectory").getDocuments()
            let myUID = Auth.auth().currentUser?.uid
            residents = snapshot.documents.compactMap { doc in
                guard doc.documentID != myUID,
                      let name = doc.data()["name"] as? String,
                      !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
                return DirectoryResident(id: doc.documentID, name: name, unit: doc.data()["unit"] as? String ?? "")
            }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func startChat(with resident: DirectoryResident) async {
        startingUID = resident.id
        defer { startingUID = nil }
        do {
            let chatId = try await store.createChat(with: resident.id)
            selectedThread = store.chatThreads.first(where: { $0.firestoreId == chatId }) ?? ChatThread(
                neighborName: resident.name,
                neighborUnit: resident.unit,
                contextNote: nil,
                messages: [],
                firestoreId: chatId,
                neighborUID: resident.id
            )
        } catch {
            errorMessage = error.localizedDescription
        }
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
                    NavigationLink { ChatDetailView(thread: thread) } label: {
                        VStack(spacing: 6) {
                            ChatResidentAvatar(name: thread.neighborName, unit: thread.neighborUnit, size: 48)
                            Text(thread.neighborUnit.isEmpty ? thread.neighborName : thread.neighborUnit)
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
            ChatResidentAvatar(name: thread.neighborName, unit: thread.neighborUnit, size: 48)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(thread.neighborName)
                        .font(Theme.ui(14, weight: .bold))
                        .foregroundStyle(Theme.appNavy)
                        .lineLimit(1)
                    Spacer()
                    if let lastMessage = thread.lastMessage {
                        Text(lastMessage.timestamp.chatRelativeDescription)
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
        .overlay { RoundedRectangle(cornerRadius: 18).stroke(Theme.appBorder, lineWidth: 1) }
    }
}

#Preview {
    NavigationStack {
        ChatListView().environmentObject(AppStore())
    }
}


// Chat-specific avatar: retain the original unit badge where a unit is visible.
struct ChatResidentAvatar: View {
    let name: String
    let unit: String
    let size: CGFloat

    var body: some View {
        Group {
            if unit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(String(name.split(separator: " ").prefix(2).compactMap(\.first)))
                    .font(.system(size: size * 0.27, weight: .bold))
                    .foregroundStyle(Theme.appPurple)
                    .frame(width: size, height: size)
                    .background(Theme.appPurple.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.25))
            } else {
                UnitBadge(unit: unit, size: size)
            }
        }
    }
}

extension Date {
    var chatRelativeDescription: String {
        let seconds = max(0, Date().timeIntervalSince(self))
        if seconds < 60 { return "Just now" }
        if seconds < 3600 { return "\(Int(seconds / 60))m ago" }
        if Calendar.current.isDateInYesterday(self) { return "Yesterday" }
        if seconds < 86400 { return "\(Int(seconds / 3600))h ago" }
        if seconds < 604800 { return "\(Int(seconds / 86400))d ago" }
        return formatted(date: .abbreviated, time: .omitted)
    }
}
