import SwiftUI

enum AdminPalette {
    static let ink = Color(red: 0.10, green: 0.14, blue: 0.26)
    static let muted = Color(red: 0.44, green: 0.49, blue: 0.60)
    static let purple = Color(red: 0.40, green: 0.32, blue: 0.87)
    static let background = Color(red: 0.965, green: 0.970, blue: 0.985)
    static let border = Color(red: 0.90, green: 0.92, blue: 0.95)
}

struct AdminPanelView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    dashboardHeader
                    dashboardOverview
                    Text("Manage building")
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundStyle(AdminPalette.ink)
                    NavigationLink { AdminMaintenanceView().environmentObject(store) } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "wrench.and.screwdriver")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(AdminPalette.purple)
                                .frame(width: 44, height: 44)
                                .background(AdminPalette.purple.opacity(0.10), in: RoundedRectangle(cornerRadius: 13))
                            Text("Maintenance Requests")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(AdminPalette.ink)
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(AdminPalette.muted)
                        }
                        .padding(14)
                        .background(.white, in: RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                    NavigationLink { AdminGymManagementView().environmentObject(store) } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(AdminPalette.purple)
                                .frame(width: 44, height: 44)
                                .background(AdminPalette.purple.opacity(0.10), in: RoundedRectangle(cornerRadius: 13))
                            Text("Gym Management")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(AdminPalette.ink)
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(AdminPalette.muted)
                        }
                        .padding(14)
                        .background(.white, in: RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                    NavigationLink { AdminResidentVerificationView().environmentObject(store) } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "person.crop.circle.badge.checkmark")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(AdminPalette.purple)
                                .frame(width: 44, height: 44)
                                .background(AdminPalette.purple.opacity(0.10), in: RoundedRectangle(cornerRadius: 13))
                            Text("Resident Verification")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(AdminPalette.ink)
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(AdminPalette.muted)
                        }
                        .padding(14)
                        .background(.white, in: RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                    NavigationLink { AdminAnnouncementsView().environmentObject(store) } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "megaphone")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(AdminPalette.purple)
                                .frame(width: 44, height: 44)
                                .background(AdminPalette.purple.opacity(0.10), in: RoundedRectangle(cornerRadius: 13))
                            Text("Announcements")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(AdminPalette.ink)
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(AdminPalette.muted)
                        }
                        .padding(14)
                        .background(.white, in: RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                    NavigationLink { AdminEventsView().environmentObject(store) } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "calendar")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(AdminPalette.purple)
                                .frame(width: 44, height: 44)
                                .background(AdminPalette.purple.opacity(0.10), in: RoundedRectangle(cornerRadius: 13))
                            Text("Manage Events")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(AdminPalette.ink)
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(AdminPalette.muted)
                        }
                        .padding(14)
                        .background(.white, in: RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 24)
            }
            .background(AdminPalette.background.ignoresSafeArea())
            .navigationTitle("Admin Dashboard")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    private var dashboardHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "building.2.crop.circle.fill")
                .font(.system(size: 35))
                .foregroundStyle(AdminPalette.purple)
                .frame(width: 54, height: 54)
                .background(.white, in: RoundedRectangle(cornerRadius: 17))
            VStack(alignment: .leading, spacing: 3) {
                Text("Admin Dashboard")
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .foregroundStyle(AdminPalette.ink)
                Text("Manage your community")
                    .font(.system(size: 13))
                    .foregroundStyle(AdminPalette.muted)
            }
            Spacer(minLength: 0)
        }
    }
    private var dashboardOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Building Overview")
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(AdminPalette.ink)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                metric("Active Chats", store.chatThreads.count, "bubble.left.and.bubble.right.fill", .blue)
                metric("Upcoming Events", store.events.filter { !$0.isCancelled && $0.date >= Date() }.count, "calendar", AdminPalette.purple)
                metric("Open Requests", store.maintenanceRequests.count, "wrench.and.screwdriver.fill", .orange)
                metric("Shared Items", store.items.count, "shippingbox.fill", .green)
            }
        }
    }
    private func metric(_ label: String, _ count: Int, _ symbol: String, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 38, height: 38)
                .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
            Text("\(count)")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(AdminPalette.ink)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AdminPalette.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(AdminPalette.border))
    }
}
