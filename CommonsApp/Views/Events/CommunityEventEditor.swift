import SwiftUI

private enum EventEditorTheme {
    static let purple = Color(red: 0.40, green: 0.32, blue: 0.87)
    static let ink = Color(red: 0.11, green: 0.15, blue: 0.26)
    static let muted = Color(red: 0.44, green: 0.49, blue: 0.59)
    static let background = Color(red: 0.965, green: 0.970, blue: 0.985)
}

struct CommunityEventEditor: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var showCancelConfirmation = false

    let existing: BuildingEvent?
    @State private var title: String
    @State private var description: String
    @State private var location: String
    @State private var start: Date
    @State private var end: Date
    @State private var allowsRSVP: Bool
    @State private var saving = false
    @State private var errorMessage: String?
    @FocusState private var fieldFocused: Bool

    init(existing: BuildingEvent?) {
        self.existing = existing
        let initialStart = existing?.date ?? Date().addingTimeInterval(3600)
        _title = State(initialValue: existing?.title ?? "")
        _description = State(initialValue: existing?.description ?? "")
        _location = State(initialValue: existing?.location ?? "")
        _start = State(initialValue: initialStart)
        _end = State(initialValue: existing?.endDate ?? initialStart.addingTimeInterval(3600))
        _allowsRSVP = State(initialValue: existing?.allowsRSVP ?? true)
    }

    private var valid: Bool {
        let name = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let place = location.trimmingCharacters(in: .whitespacesAndNewlines)
        return !name.isEmpty && name.count <= 100 && !place.isEmpty &&
            place.count <= 200 && description.count <= 2000 &&
            start > Date() && end > start
    }

    var body: some View {
        ZStack {
            EventEditorTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 14) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(EventEditorTheme.purple)
                            .frame(width: 58, height: 58)
                            .background(EventEditorTheme.purple.opacity(0.10), in: RoundedRectangle(cornerRadius: 18))
                        VStack(alignment: .leading, spacing: 5) {
                            Text(existing == nil ? "Bring your community together" : "Update event details")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(EventEditorTheme.ink)
                            Text("Plan and share an event with your residents.")
                                .font(.system(size: 12))
                                .foregroundStyle(EventEditorTheme.muted)
                        }
                    }
                    card("Event details", icon: "text.alignleft") {
                        VStack(alignment: .leading, spacing: 13) {
                            caption("EVENT TITLE *")
                            TextField("e.g. Community Movie Night", text: $title)
                                .textInputAutocapitalization(.words)
                                .focused($fieldFocused)
                                .eventEditorInput()
                            counter(title.count, maximum: 100)
                            caption("LOCATION *")
                            HStack(spacing: 9) {
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundStyle(EventEditorTheme.purple)
                                TextField("e.g. Rooftop Terrace", text: $location)
                            }
                            .eventEditorInput()
                            caption("DESCRIPTION")
                            TextField("Tell residents what to expect…", text: $description, axis: .vertical)
                                .lineLimit(4...7)
                                .eventEditorInput()
                            counter(description.count, maximum: 2000)
                        }
                    }
                    card("Date & time", icon: "clock") {
                        VStack(spacing: 13) {
                            DatePicker("Starts", selection: $start, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                                .onChange(of: start) { _, value in
                                    if end <= value { end = value.addingTimeInterval(3600) }
                                }
                            Divider()
                            DatePicker("Ends", selection: $end, in: start..., displayedComponents: [.date, .hourAndMinute])
                        }
                        .tint(EventEditorTheme.purple)
                        .font(.system(size: 14, weight: .medium))
                    }
                    card("Attendance", icon: "person.2") {
                        Toggle(isOn: $allowsRSVP) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Allow resident RSVP")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(EventEditorTheme.ink)
                                Text("Residents can confirm or withdraw attendance.")
                                    .font(.system(size: 12))
                                    .foregroundStyle(EventEditorTheme.muted)
                            }
                        }
                        .tint(EventEditorTheme.purple)

                        if let event = existing, !event.isCancelled {
                            Button(role: .destructive) {
                                showCancelConfirmation = true
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "calendar.badge.minus")
                                        .font(.system(size: 18))

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Cancel Event")
                                            .font(.system(size: 15, weight: .semibold))

                                        Text("Residents will see that this event is cancelled.")
                                            .font(.system(size: 12))
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundStyle(.red)
                                .padding(18)
                                .background(
                                    Color.red.opacity(0.06),
                                    in: RoundedRectangle(cornerRadius: 18)
                                )
                                .overlay {
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(Color.red.opacity(0.15))
                                }
                            }
                            .disabled(saving)
                        }
                    }
                    if let errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.red)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.red.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle(existing == nil ? "Create Event" : "Edit Event")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }.disabled(saving)
            }
            ToolbarItem(placement: .keyboard) {
                Button("Done") { fieldFocused = false }
            }
        }
        .confirmationDialog(
            "Cancel this event?",
            isPresented: $showCancelConfirmation,
            titleVisibility: .visible
        ) {
            Button("Cancel Event", role: .destructive) {
                guard let event = existing else { return }

                saving = true
                errorMessage = nil

                Task { @MainActor in
                    do {
                        try await store.cancelCommunityEvent(event)
                        dismiss()
                    } catch {
                        errorMessage = error.localizedDescription
                    }

                    saving = false
                }
            }
        } message: {
            Text("This event will be marked as cancelled. Residents will no longer be able to RSVP.")
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack {
                Button(action: save) {
                    HStack(spacing: 9) {
                        if saving { ProgressView().tint(.white) }
                        else { Image(systemName: existing == nil ? "calendar.badge.plus" : "checkmark.circle.fill") }
                        Text(saving ? "Saving…" : existing == nil ? "Create Event" : "Save Changes")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(EventEditorTheme.purple.opacity(valid && !saving ? 1 : 0.45),
                                in: RoundedRectangle(cornerRadius: 16))
                }
                .disabled(!valid || saving)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .background(.regularMaterial)
        }
    }

    private func caption(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .tracking(0.6)
            .foregroundStyle(EventEditorTheme.muted)
    }

    private func counter(_ count: Int, maximum: Int) -> some View {
        HStack {
            Spacer()
            Text("\(count)/\(maximum)")
                .font(.system(size: 11))
                .foregroundStyle(count > maximum ? .red : EventEditorTheme.muted)
        }
    }

    private func card<Content: View>(_ title: String, icon: String,
                                     @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(EventEditorTheme.purple)
                    .frame(width: 38, height: 38)
                    .background(EventEditorTheme.purple.opacity(0.09), in: RoundedRectangle(cornerRadius: 12))
                Text(title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(EventEditorTheme.ink)
            }
            content()
        }
        .padding(18)
        .background(.white, in: RoundedRectangle(cornerRadius: 21))
        .overlay(RoundedRectangle(cornerRadius: 21).stroke(Color.black.opacity(0.06)))
    }

    private func save() {
        guard valid && !saving else { return }
        fieldFocused = false
        saving = true
        errorMessage = nil
        Task { @MainActor in
            do {
                try await store.saveCommunityEvent(
                    existing: existing, title: title, description: description,
                    start: start, end: end, location: location, allowsRSVP: allowsRSVP
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            saving = false
        }
    }
}

private extension View {
    func eventEditorInput() -> some View {
        self.font(.system(size: 14))
            .foregroundStyle(EventEditorTheme.ink)
            .padding(13)
            .background(EventEditorTheme.background, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.07)))
    }
}
