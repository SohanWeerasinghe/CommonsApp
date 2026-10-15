//
//  LendBorrowView.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 21/9/2026.
//

import SwiftUI

struct LendBorrowView: View {

    @EnvironmentObject var store: AppStore

    @State private var showNewItem = false
    @State private var selectedFilter = "All"
    @State private var searchText = ""

    let filters = ["All", "Lending", "Needed"]

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
                    LendBorrowHeader {
                        showNewItem = true
                    }

                    // Search field
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Theme.appMuted)

                        TextField("Search shared items", text: $searchText)
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

                    // Filter buttons
                    HStack(spacing: 8) {
                        ForEach(filters, id: \.self) { filter in
                            Button {
                                selectedFilter = filter
                            } label: {
                                Text(filter)
                                    .font(Theme.ui(12, weight: .semibold))
                                    .foregroundStyle(
                                        selectedFilter == filter ? Theme.card : Theme.appMuted
                                    )
                                    .padding(.horizontal, 18)
                                    .frame(height: 34)
                                    .background(
                                        selectedFilter == filter ? Theme.appPurple : Theme.card
                                    )
                                    .clipShape(Capsule())
                                    .overlay {
                                        if selectedFilter != filter {
                                            Capsule()
                                                .stroke(Theme.appBorder, lineWidth: 1)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }

                        Spacer()
                    }
                    .padding(.top, 14)

                    // Get filtered and searched items
                    let visibleItems = filteredItems()

                    if visibleItems.isEmpty {
                        AppEmptyState(icon: "shippingbox",title: "Nothing here yet",message: "Add something you can lend or something you need.")
                        .padding(.top, 60)

                    } else {
                        // Two-column item grid
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ],
                            spacing: 12
                        ) {
                            ForEach(visibleItems) { item in
                                SharedItemCard(item: item)
                            }
                        }
                        .padding(.top, 18)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 125)
            }
            .scrollIndicators(.hidden)
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showNewItem) {
            NewItemView()
        }
    }

    func filteredItems() -> [SharedItem] {

        var statusFilteredItems: [SharedItem] = []

        // First filter by Lending / Needed
        if selectedFilter == "Lending" {
            for item in store.items {
                if item.status == .lending {
                    statusFilteredItems.append(item)
                }
            }

        } else if selectedFilter == "Needed" {
            for item in store.items {
                if item.status == .needed {
                    statusFilteredItems.append(item)
                }
            }

        } else {
            statusFilteredItems = store.items
        }

        // If search is empty, return the filtered items
        if searchText.isEmpty {
            return statusFilteredItems
        }

        // Otherwise search by item name or description
        var searchResults: [SharedItem] = []

        for item in statusFilteredItems {
            let nameMatches = item.name.localizedCaseInsensitiveContains(searchText)
            let detailMatches = item.detail.localizedCaseInsensitiveContains(searchText)

            if nameMatches || detailMatches {
                searchResults.append(item)
            }
        }

        return searchResults
    }
}

private struct LendBorrowHeader: View {

    let addItem: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {

            Text("LEND & BORROW")
                .font(Theme.ui(10, weight: .bold))
                .foregroundStyle(Theme.appMuted)

            HStack {
                Text("Borrow nearby")
                    .font(Theme.display(28, weight: .bold))
                    .foregroundStyle(Theme.appNavy)

                Spacer()

                Button(action: addItem) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))

                        Text("Add")
                            .font(Theme.ui(12, weight: .bold))
                    }
                    .foregroundStyle(Theme.card)
                    .padding(.horizontal, 16)
                    .frame(height: 38)
                    .background(Theme.appPurple)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct SharedItemCard: View {

    @EnvironmentObject var store: AppStore

    let item: SharedItem

    @State private var navigateToChat = false
    @State private var chatThread: ChatThread? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Image placeholder
            // Later this can display the image URL returned by the database.
            DynamicImagePlaceholder(systemImage: itemIcon)
                .frame(maxWidth: .infinity)
                .frame(height: 125)
                .clipShape(RoundedRectangle(cornerRadius: 17))

            // Availability / status
            Text(item.status == .lending ? "AVAILABLE" : "NEEDED")
                .font(Theme.ui(8, weight: .bold))
                .foregroundStyle(
                    item.status == .lending ? Theme.appGreen : Theme.danger
                )
                .padding(.top, 12)

            // Item name
            Text(item.name)
                .font(Theme.display(15, weight: .bold))
                .foregroundStyle(Theme.appNavy)
                .lineLimit(1)
                .padding(.top, 4)

            // Owner
            Text("\(item.ownerName) · \(item.ownerUnit)")
                .font(Theme.ui(10))
                .foregroundStyle(Theme.appMuted)
                .lineLimit(1)
                .padding(.top, 4)

            // Item description
            Text(item.detail)
                .font(Theme.ui(10))
                .foregroundStyle(Theme.appMuted)
                .lineLimit(2)
                .frame(minHeight: 28, alignment: .top)
                .padding(.top, 7)

            Spacer(minLength: 10)

            // Request / Message button
            Button {
                let thread = store.requestItem(item)
                chatThread = thread
                navigateToChat = true
            } label: {
                Text(item.status == .lending ? "Request" : "Message")
                    .font(Theme.ui(11, weight: .bold))
                    .foregroundStyle(Theme.appPurple)
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)
                    .background(Theme.appPurpleSoft)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            // Navigate to the chat after requesting an item
            if let thread = chatThread {
                NavigationLink(
                    destination: ChatDetailView(thread: thread),
                    isActive: $navigateToChat
                ) {
                    EmptyView()
                }
                .hidden()
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 275, alignment: .top)
        .background(Theme.card.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(Theme.appBorder, lineWidth: 1)
        }
    }

    // These icons are only UI placeholders.
    // Later the real item image can come from the database.
    private var itemIcon: String {

        let lowerName = item.name.lowercased()

        if lowerName.contains("drill") {
            return "wrench.and.screwdriver"
        }

        if lowerName.contains("chair") {
            return "chair"
        }

        if lowerName.contains("cake") {
            return "birthday.cake"
        }

        if lowerName.contains("mixer") {
            return "birthday.cake"
        }

        if lowerName.contains("tool") {
            return "hammer"
        }

        if lowerName.contains("ladder") {
            return "figure.stairs"
        }

        if lowerName.contains("tent") {
            return "tent"
        }

        return "photo"
    }
}

#Preview {
    NavigationStack {
        LendBorrowView()
            .environmentObject(AppStore())
    }
}
