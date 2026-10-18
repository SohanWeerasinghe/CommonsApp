import SwiftUI
import FirebaseAuth
import FirebaseFirestore

private struct DirectoryResident: Identifiable {
    let id: String
    let name: String
    let unit: String
}

struct NewChatView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var residents: [DirectoryResident] = []
    @State private var searchText = ""
    @State private var isLoading = true
    @State private var selectedUID: String?
    @State private var errorMessage: String?
    @State private var createdThread: ChatThread?

    private var filteredResidents: [DirectoryResident] {
        guard !searchText.isEmpty else { return residents }
        return residents.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.unit.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Theme.appMuted)

                    TextField("Search residents...", text: $searchText)
                        .font(Theme.ui(14))
                }
                .padding(16)
                .background(Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 16)

                if isLoading {
                    ProgressView("Loading residents...")
                        .padding(.top, 40)
                } else if residents.isEmpty {
                    ContentUnavailableView(
                        "No residents found",
                        systemImage: "person.2",
                        description: Text("No other approved residents are available.")
                    )
                } else {
                    List(filteredResidents) { resident in
                        Button {
                            Task { await startChat(with: resident) }
                        } label: {
                            HStack(spacing: 12) {
                                UnitBadge(unit: resident.unit, size: 44)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(resident.name)
                                        .font(Theme.ui(15, weight: .semibold))
                                        .foregroundStyle(Theme.appNavy)

                                    if !resident.unit.isEmpty {
                                        Text(resident.unit)
                                            .font(Theme.ui(12))
                                            .foregroundStyle(Theme.appMuted)
                                    }
                                }

                                Spacer()

                                if selectedUID == resident.id {
                                    ProgressView()
                                } else {
                                    Image(systemName: "bubble.left")
                                        .foregroundStyle(Theme.appPurple)
                                }
                            }
                        }
                        .disabled(selectedUID != nil)
                        .listRowBackground(Theme.card)
                    }
                    .scrollContentBackground(.hidden)
                }

                Spacer(minLength: 0)
            }
            .background(
                LinearGradient(
                    colors: [Theme.wallBackgroundTop, Theme.wallBackgroundBottom],
                    startPoint: .top,
                    endPoint: .bottom
                ).ignoresSafeArea()
            )
            .navigationTitle("New Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task { await loadResidents() }
            .alert(
                "Unable to start chat",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )
            ) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .navigationDestination(item: $createdThread) { thread in
                ChatDetailView(thread: thread)
            }
        }
    }

    @MainActor
    private func loadResidents() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let snapshot = try await Firestore.firestore()
                .collection("residentDirectory")
                .getDocuments()

            let currentUID = Auth.auth().currentUser?.uid

            residents = snapshot.documents.compactMap { document in
                guard document.documentID != currentUID else { return nil }

                let data = document.data()
                guard let name = data["name"] as? String,
                      !name.isEmpty else { return nil }

                return DirectoryResident(
                    id: document.documentID,
                    name: name,
                    unit: data["unit"] as? String ?? ""
                )
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func startChat(with resident: DirectoryResident) async {
        selectedUID = resident.id
        defer { selectedUID = nil }

        do {
            let chatId = try await store.createChat(with: resident.id)

            let existing = store.chatThreads.first {
                $0.firestoreId == chatId
            }

            createdThread = existing ?? ChatThread(
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
