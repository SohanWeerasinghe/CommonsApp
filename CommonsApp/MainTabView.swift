//
//  MainTabView.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 21/9/2026.
//
import SwiftUI
enum MainTab {
    case wall
    case share
    case events
    case chat
    case service
    case settings
}
struct MainTabView: View {
    @State private var selectedTab: MainTab = .wall
    @StateObject private var siriNavigation = SiriNavigation.shared
    var body: some View {
        selectedPage
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .onAppear {
                handleSiriNavigation()
            }
            .onChange(of: siriNavigation.requestedTab) { _, _ in
                handleSiriNavigation()
            }
    }
    private func handleSiriNavigation() {
        guard let tab = siriNavigation.requestedTab else {
            return
        }
        selectedTab = tab
        siriNavigation.requestedTab = nil
    }
    @ViewBuilder
    private var selectedPage: some View {
        switch selectedTab {
        case .wall:
            NavigationStack {
                BuildingWallView()
                    .rootTabBar(selectedTab: $selectedTab)
            }
        case .share:
            NavigationStack {
                LendBorrowView()
                    .rootTabBar(selectedTab: $selectedTab)
            }
        case .events:
            NavigationStack {
                EventCalendarView()
                    .rootTabBar(selectedTab: $selectedTab)
            }
        case .chat:
            NavigationStack {
                ChatListView()
                    .rootTabBar(selectedTab: $selectedTab)
            }
        case .service:
            NavigationStack {
                ServiceHubView()
                    .rootTabBar(selectedTab: $selectedTab)
            }
        case .settings:
            NavigationStack {
                SettingsView()
            }
        }
    }
}
struct CommonsBottomTabBar: View {
    @Binding var selectedTab: MainTab
    @Namespace private var selectionAnimation
    var body: some View {
        HStack(spacing: 2) {
            CommonsBottomTabItem(title: "Wall", icon: "house", isSelected: selectedTab == .wall, selectionAnimation: selectionAnimation) {
                select(.wall)
            }
            CommonsBottomTabItem(title: "Share", icon: "arrow.left.arrow.right", isSelected: selectedTab == .share, selectionAnimation: selectionAnimation) {
                select(.share)
            }
            CommonsBottomTabItem(title: "Events", icon: "circle.circle", isSelected: selectedTab == .events, selectionAnimation: selectionAnimation) {
                select(.events)
            }
            CommonsBottomTabItem(title: "Chat", icon: "sparkle", isSelected: selectedTab == .chat, selectionAnimation: selectionAnimation) {
                select(.chat)
            }
            CommonsBottomTabItem(title: "Service", icon: "line.3.horizontal", isSelected: selectedTab == .service, selectionAnimation: selectionAnimation) {
                select(.service)
            }
        }
        .padding(6)
        .frame(height: 66)
        .glassEffect(.regular, in: Capsule())
        .shadow(color: .black.opacity(0.10), radius: 14, x: 0, y: 5)
    }
    private func select(_ tab: MainTab) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
            selectedTab = tab
        }
    }
}
struct CommonsBottomTabItem: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let selectionAnimation: Namespace.ID
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                Text(title)
                    .font(Theme.ui(10, weight: .semibold))
            }
            .foregroundStyle(isSelected ? Theme.purple : Color.primary.opacity(0.7))
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background {
                if isSelected {
                    Capsule()
                        .fill(Theme.purple.opacity(0.12))
                        .matchedGeometryEffect(id: "selectedTab", in: selectionAnimation)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
private extension View {
    func rootTabBar(selectedTab: Binding<MainTab>) -> some View {
        self.safeAreaInset(edge: .bottom, spacing: 0) {
            CommonsBottomTabBar(selectedTab: selectedTab)
                .padding(.horizontal, 14)
                .padding(.bottom, 4)
        }
    }
}
#Preview {
    MainTabView()
}
