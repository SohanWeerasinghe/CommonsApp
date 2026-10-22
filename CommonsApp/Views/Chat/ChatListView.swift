//
//  ChatListView.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 21/9/2026.
//
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
private enum ChatStyle {
    static let background = Color(red: 0.972, green: 0.972, blue: 0.991)
    static let ink = Color(red: 0.13, green: 0.17, blue: 0.29)
    static let muted = Color(red: 0.48, green: 0.51, blue: 0.61)
    static let purple = Color(red: 0.43, green: 0.36, blue: 0.91)
    static let border = Color(red: 0.89, green: 0.89, blue: 0.94)
}
struct ChatListView: View {
    @EnvironmentObject var store: AppStore
    @State private var searchText = ""
    @State private var showingNewChat = false
    private var filteredThreads: [ChatThread] {
        guard !searchText.isEmpty else { return store.chatThreads }
        return store.chatThreads.filter { thread in
            thread.neighborName.localizedCaseInsensitiveContains(searchText)
            || thread.neighborUnit.localizedCaseInsensitiveContains(searchText)
            || (thread.lastMessage?.text.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    var body: some View {
        ZStack {
            ChatStyle.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    header
                    searchBar
                    if store.chatThreads.isEmpty {
                        emptyState
                    } else {
                        if searchText.isEmpty {
                            VStack(alignment: .leading, spacing: 14) {
                                sectionHeader("NEIGHBOURS", detail: "QUICK ACCESS")
                                ResidentShortcuts(threads: store.chatThreads)
                            }
                        }
                        VStack(alignment: .leading, spacing: 14) {
                            sectionHeader("MESSAGES", detail: "\(filteredThreads.count) conversations")
                            if filteredThreads.isEmpty {
                                searchEmptyState
                            } else {
                                LazyVStack(spacing: 10) {
                                    ForEach(filteredThreads) { thread in
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
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, 135)
            }
            .scrollIndicators(.hidden)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { store.startChatThreadsListener() }
        .sheet(isPresented: $showingNewChat) {
            NewChatSheet().environmentObject(store)
        }
    }
    private var header: some View {
        VStack(alignment: .leading, spacing: 19) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("YOUR COMMUNITY")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(2.1)
                        .foregroundStyle(ChatStyle.purple)
                    Text("Messages")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .tracking(-0.8)
                        .foregroundStyle(ChatStyle.ink)
                }
                Spacer()
                Button { showingNewChat = true } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 54, height: 54)
                        .background(ChatStyle.purple, in: RoundedRectangle(cornerRadius: 19))
                        .shadow(color: ChatStyle.purple.opacity(0.22), radius: 12, y: 6)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("New Chat")
            }
            HStack(spacing: 12) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(ChatStyle.purple)
                    .frame(width: 42, height: 42)
                    .background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Better together")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(ChatStyle.ink)
                    Text("A little hello goes a long way.")
                        .font(.system(size: 12))
                        .foregroundStyle(ChatStyle.muted)
                }
                Spacer(minLength: 0)
                Image(systemName: "sparkle")
                    .font(.system(size: 17))
                    .foregroundStyle(ChatStyle.purple.opacity(0.7))
            }
            .padding(14)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.92, green: 0.90, blue: 1.0), Color(red: 0.96, green: 0.95, blue: 1.0)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 21)
            )
        }
    }
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(ChatStyle.purple)
            TextField("Search conversations", text: $searchText)
                .font(.system(size: 14))
                .foregroundStyle(ChatStyle.ink)
                .tint(ChatStyle.purple)
                .autocorrectionDisabled()
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(ChatStyle.muted)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 17)
        .frame(height: 54)
        .background(.white, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(ChatStyle.border, lineWidth: 1))
    }
    private func sectionHeader(_ title: String, detail: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(ChatStyle.ink)
            Spacer()
            Text(detail)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(ChatStyle.muted)
        }
    }
    private var searchEmptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 26))
                .foregroundStyle(ChatStyle.purple)
            Text("No matching conversations")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(ChatStyle.ink)
            Text("Try searching another name, unit or message.")
                .font(.system(size: 12))
                .foregroundStyle(ChatStyle.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 35)
        .background(.white, in: RoundedRectangle(cornerRadius: 22))
    }
    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(ChatStyle.purple)
                .frame(width: 82, height: 82)
                .background(ChatStyle.purple.opacity(0.10), in: RoundedRectangle(cornerRadius: 27))
            Text("Every conversation starts somewhere")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(ChatStyle.ink)
                .multilineTextAlignment(.center)
            Text("Reach out to a neighbour and say hello.")
                .font(.system(size: 13))
                .foregroundStyle(ChatStyle.muted)
                .multilineTextAlignment(.center)
            Button { showingNewChat = true } label: {
                Label("Start a conversation", systemImage: "plus")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .frame(height: 46)
                    .background(ChatStyle.purple, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 37)
        .padding(.horizontal, 18)
        .background(.white, in: RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(ChatStyle.border))
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
                ChatStyle.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Find a neighbour")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundStyle(ChatStyle.ink)
                            Text("Choose an approved resident to start a conversation.")
                                .font(.system(size: 13))
                                .foregroundStyle(ChatStyle.muted)
                        }
                        .padding(.top, 12)
                        HStack(spacing: 11) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(ChatStyle.purple)
                            TextField("Search residents...", text: $searchText)
                                .font(.system(size: 14))
                                .foregroundStyle(ChatStyle.ink)
                                .autocorrectionDisabled()
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 52)
                        .background(.white, in: RoundedRectangle(cornerRadius: 17))
                        .overlay(RoundedRectangle(cornerRadius: 17).stroke(ChatStyle.border))
                        if loading {
                            ProgressView("Loading residents...")
                                .frame(maxWidth: .infinity)
                                .padding(.top, 35)
                        } else if filteredResidents.isEmpty {
                            AppEmptyState(icon: "person.2", title: "No residents found", message: "Try another name or unit.")
                                .padding(.top, 30)
                        } else {
                            Text("APPROVED RESIDENTS")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .tracking(1.4)
                                .foregroundStyle(ChatStyle.muted)
                            LazyVStack(spacing: 10) {
                                ForEach(filteredResidents) { resident in
                                    Button {
                                        Task { await startChat(with: resident) }
                                    } label: {
                                        HStack(spacing: 13) {
                                            ChatResidentAvatar(name: resident.name, unit: resident.unit, size: 48, residentUID: resident.id)
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(resident.name)
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundStyle(ChatStyle.ink)
                                                if !resident.unit.isEmpty {
                                                    Text(resident.unit)
                                                        .font(.system(size: 12))
                                                        .foregroundStyle(ChatStyle.muted)
                                                }
                                            }
                                            Spacer()
                                            if startingUID == resident.id {
                                                ProgressView()
                                            } else {
                                                Image(systemName: "arrow.up.right")
                                                    .font(.system(size: 13, weight: .semibold))
                                                    .foregroundStyle(ChatStyle.purple)
                                                    .frame(width: 32, height: 32)
                                                    .background(ChatStyle.purple.opacity(0.09), in: Circle())
                                            }
                                        }
                                        .padding(14)
                                        .background(.white, in: RoundedRectangle(cornerRadius: 19))
                                        .overlay(RoundedRectangle(cornerRadius: 19).stroke(ChatStyle.border))
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(startingUID != nil)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
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
            HStack(alignment: .top, spacing: 18) {
                ForEach(threads.prefix(8)) { thread in
                    NavigationLink { ChatDetailView(thread: thread) } label: {
                        VStack(spacing: 8) {
                            ChatResidentAvatar(name: thread.neighborName,
                                               unit: thread.neighborUnit, size: 60, residentUID: thread.neighborUID)
                                .overlay(Circle().stroke(.white, lineWidth: 2).padding(-3))
                            Text(thread.neighborName)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(ChatStyle.ink)
                                .lineLimit(1)
                                .frame(width: 78)
                            if !thread.neighborUnit.isEmpty {
                                Text(thread.neighborUnit)
                                    .font(.system(size: 10))
                                    .foregroundStyle(ChatStyle.muted)
                                    .lineLimit(1)
                            }
                        }
                        .frame(width: 80)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 3)
        }
    }
}
private struct ThreadRow: View {
    let thread: ChatThread
    var body: some View {
        HStack(spacing: 13) {
            ChatResidentAvatar(name: thread.neighborName, unit: thread.neighborUnit, size: 54, residentUID: thread.neighborUID)
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(thread.neighborName)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(ChatStyle.ink)
                        .lineLimit(1)
                    Spacer(minLength: 2)
                    if let last = thread.lastMessage {
                        Text(last.timestamp.chatRelativeDescription)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(ChatStyle.muted)
                    }
                }
                if let note = thread.contextNote, !note.isEmpty {
                    Text(note)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(ChatStyle.purple)
                        .lineLimit(1)
                }
                Text(thread.lastMessage?.text ?? "Tap to start a conversation")
                    .font(.system(size: 12))
                    .foregroundStyle(ChatStyle.muted)
                    .lineLimit(2)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(ChatStyle.purple.opacity(0.75))
                .padding(.leading, 2)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 17)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(ChatStyle.border, lineWidth: 1))
    }
}
#Preview {
    NavigationStack {
        ChatListView().environmentObject(AppStore())
    }
}
// Chat-specific avatar: retain the original unit badge where a unit is visible.
// Reusable chat avatar: show a resident photo when available, otherwise retain the original badge.
struct ChatResidentAvatar: View {
    let name: String
    let unit: String
    let size: CGFloat
    var residentUID: String? = nil
    @State private var photo: UIImage?
    var body: some View {
        Group {
            if let photo {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else if unit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
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
        .task(id: residentUID) {
            photo = nil
            guard let residentUID, !residentUID.isEmpty else { return }
            photo = await ChatProfilePhotoLoader.load(uid: residentUID)
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
