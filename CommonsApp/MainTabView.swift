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

    var body: some View {
        selectedPage
            .ignoresSafeArea(.keyboard, edges: .bottom)
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

    var body: some View {
        HStack(spacing: 0) {
            CommonsBottomTabItem(
                title: "Wall",
                icon: "house",
                isSelected: selectedTab == .wall
            ) {
                selectedTab = .wall
            }

            CommonsBottomTabItem(
                title: "Share",
                icon: "arrow.left.arrow.right",
                isSelected: selectedTab == .share
            ) {
                selectedTab = .share
            }

            CommonsBottomTabItem(
                title: "Events",
                icon: "circle.circle",
                isSelected: selectedTab == .events
            ) {
                selectedTab = .events
            }

            CommonsBottomTabItem(
                title: "Chat",
                icon: "sparkle",
                isSelected: selectedTab == .chat
            ) {
                selectedTab = .chat
            }

            CommonsBottomTabItem(
                title: "Service",
                icon: "line.3.horizontal",
                isSelected: selectedTab == .service
            ) {
                selectedTab = .service
            }
        }
        .padding(6)
        .frame(height: 62)
        .background(Theme.inkLight)
        .clipShape(Capsule())
        .shadow(
            color: Color.black.opacity(0.15),
            radius: 12,
            x: 0,
            y: 5
        )
    }
}

struct CommonsBottomTabItem: View {

    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))

                Text(title)
                    .font(Theme.ui(9, weight: .semibold))
            }
            .foregroundStyle(
                isSelected
                ? Theme.purple
                : Theme.textOnInkMuted
            )
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                isSelected
                ? Theme.card.opacity(0.12)
                : Color.clear
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private extension View {

    func rootTabBar(selectedTab: Binding<MainTab>) -> some View {
        self.safeAreaInset(edge: .bottom, spacing: 0) {
            CommonsBottomTabBar(selectedTab: selectedTab)
                .padding(.horizontal, 14)
                .padding(.bottom, 4)
                .background(Color.clear)
        }
    }
}

#Preview {
    MainTabView()
}
