import SwiftUI

struct AdminEventsView: View {
    @EnvironmentObject var store: AppStore
    @State private var showCreateEvent = false
    @State private var editingEvent: BuildingEvent?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                eventsContent
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AdminPalette.background.ignoresSafeArea())
        .navigationTitle("Events")
        .navigationBarTitleDisplayMode(.inline)

        .sheet(isPresented: $showCreateEvent) {
            NavigationStack { CommunityEventEditor(existing: nil).environmentObject(store) }
        }
        .sheet(item: $editingEvent) { event in
            NavigationStack { CommunityEventEditor(existing: event).environmentObject(store) }
        }
    }
    private var eventsContent: some View {
        VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Manage Events")
                                    .font(.system(size: 19, weight: .bold, design: .rounded))
                                    .foregroundStyle(AdminPalette.ink)
                                Text("Create and manage community events")
                                    .font(.system(size: 12))
                                    .foregroundStyle(AdminPalette.muted)
                            }
                            Spacer(minLength: 0)
                            Button { showCreateEvent = true } label: {
                                Label("Create", systemImage: "plus")
                                    .font(.system(size: 13, weight: .semibold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 11)
                                    .foregroundStyle(.white)
                                    .background(AdminPalette.purple, in: Capsule())
                            }
                        }
                        if store.events.isEmpty {
                            VStack(spacing: 9) {
                                Image(systemName: "calendar.badge.plus")
                                    .font(.system(size: 28))
                                    .foregroundStyle(AdminPalette.purple)
                                Text("No events created yet")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(AdminPalette.ink)
                                Text("Create your first community event to get started.")
                                    .font(.system(size: 12))
                                    .foregroundStyle(AdminPalette.muted)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 28)
                            .background(.white, in: RoundedRectangle(cornerRadius: 20))
                        } else {
                            ForEach(store.events.sorted(by: { $0.date > $1.date })) { event in
                                HStack(alignment: .top, spacing: 12) {
                                    VStack(spacing: 3) {
                                        Text(event.date.formatted(.dateTime.month(.abbreviated)).uppercased())
                                            .font(.system(size: 10, weight: .bold))
                                        Text(event.date.formatted(.dateTime.day()))
                                            .font(.system(size: 24, weight: .bold, design: .rounded))
                                    }
                                    .foregroundStyle(AdminPalette.purple)
                                    .frame(width: 58, height: 64)
                                    .background(AdminPalette.purple.opacity(0.09), in: RoundedRectangle(cornerRadius: 14))
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(event.title)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(AdminPalette.ink)
                                        Label(event.location, systemImage: "mappin")
                                        Label(event.date.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                                        Label("\(event.attendeeCount) attending", systemImage: "person.2")
                                    }
                                    .font(.system(size: 11))
                                    .foregroundStyle(AdminPalette.muted)
                                    Spacer(minLength: 0)
                                    VStack(alignment: .trailing, spacing: 10) {
                                        
                                        TimelineView(.periodic(from: .now, by: 30)) { context in
                                            let isCompleted = !event.isCancelled && event.date <= context.date

                                            Text(
                                                event.isCancelled
                                                    ? "CANCELLED"
                                                    : isCompleted ? "COMPLETED" : "ACTIVE"
                                            )
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(
                                                event.isCancelled
                                                    ? Color.red
                                                    : isCompleted ? Color.gray : Color.green
                                            )
                                        }

                                        if !event.isCancelled && event.firestoreId != nil {
                                            Button { editingEvent = event } label: {
                                                Image(systemName: "pencil")
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundStyle(AdminPalette.purple)
                                                    .frame(width: 36, height: 36)
                                                    .background(AdminPalette.background, in: RoundedRectangle(cornerRadius: 11))
                                            }
                                            .accessibilityLabel("Edit \(event.title)")
                                        }
                                    }
                                }
                                .padding(14)
                                .background(.white, in: RoundedRectangle(cornerRadius: 19))
                                .overlay(RoundedRectangle(cornerRadius: 19).stroke(AdminPalette.border))
                            }
                        }
                    }
    }
}
