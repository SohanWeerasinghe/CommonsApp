// LendBorrowView.swift — CommonsApp professional lending marketplace
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import UIKit
private enum MarketStyle {
    static let purple = Color(red: 0.46, green: 0.40, blue: 0.96)
    static let navy = Color(red: 0.12, green: 0.17, blue: 0.28)
    static let muted = Color(red: 0.44, green: 0.49, blue: 0.60)
    static let background = Color(red: 0.975, green: 0.973, blue: 0.992)
    static let lavender = Color(red: 0.92, green: 0.91, blue: 1.0)
    static let border = Color(red: 0.90, green: 0.91, blue: 0.95)
    static let green = Color(red: 0.13, green: 0.57, blue: 0.42)
}
struct LendBorrowView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showNewItem = false
    @State private var showRequests = false
    @State private var selectedFilter = "All"
    @State private var searchText = ""
    private let filters = ["All", "Lending", "Needed"]
    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]
    private var visibleItems: [SharedItem] {
        store.items.filter { item in
            let isReserved = item.firestoreId.map { store.reservedSharedItemIds.contains($0) } ?? false
            let matchesFilter = selectedFilter == "All" ||
                (selectedFilter == "Lending" && item.status == .lending) ||
                (selectedFilter == "Needed" && item.status == .needed)
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let matchesSearch = query.isEmpty || item.name.localizedCaseInsensitiveContains(query) ||
                item.detail.localizedCaseInsensitiveContains(query)
            return matchesFilter && matchesSearch && !isReserved &&
                !(item.firestoreId.map { store.unpublishedSharedItemIds.contains($0) } ?? false)
        }
    }
    var body: some View {
        ZStack {
            MarketStyle.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 23) {
                    header
                    requestsShortcut
                    discoverySection
                    listingsSection
                    unpublishedListingsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 15)
                .padding(.bottom, 125)
            }
            .scrollIndicators(.hidden)
        }
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.light)
        .task { await MainActor.run { store.startSharedItemsListener() } }
        .sheet(isPresented: $showNewItem) { NewItemView() }
        .sheet(isPresented: $showRequests) { BorrowRequestsView() }
    }
    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("COMMUNITY SHARING", systemImage: "square.stack.3d.up")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(MarketStyle.purple)
                Spacer()
                Image(systemName: "person.2.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MarketStyle.purple)
                    .frame(width: 38, height: 38)
                    .background(MarketStyle.lavender, in: Circle())
            }
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Share more.\nOwn less.")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .tracking(-0.8)
                        .foregroundStyle(MarketStyle.navy)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Borrow and lend with your neighbours")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(MarketStyle.muted)
                }
                Spacer(minLength: 0)
                Button { showNewItem = true } label: {
                    Label("Add item", systemImage: "plus")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 15)
                        .frame(height: 43)
                        .background(MarketStyle.purple, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add a shared item")
            }
        }
    }
    private var requestsShortcut: some View {
        Button { showRequests = true } label: {
            HStack(spacing: 13) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(MarketStyle.purple)
                    .frame(width: 48, height: 48)
                    .background(MarketStyle.lavender, in: RoundedRectangle(cornerRadius: 15))
                VStack(alignment: .leading, spacing: 4) {
                    Text("My borrowing activity")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(MarketStyle.navy)
                    Text("Track requests, collections and returns")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(MarketStyle.muted)
                }
                Spacer(minLength: 3)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(MarketStyle.purple)
            }
            .padding(14)
            .background(.white, in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(MarketStyle.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
    private var discoverySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(MarketStyle.muted)
                TextField("Search items or descriptions", text: $searchText)
                    .font(.system(size: 14))
                    .foregroundStyle(MarketStyle.navy)
                    .tint(MarketStyle.purple)
                    .autocorrectionDisabled()
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(MarketStyle.muted)
                    }
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(.white, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(MarketStyle.border, lineWidth: 1))
            HStack(spacing: 9) {
                ForEach(filters, id: \.self) { filter in
                    Button { selectedFilter = filter } label: {
                        Text(filter == "All" ? "All items" : filter)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(selectedFilter == filter ? .white : MarketStyle.muted)
                            .padding(.horizontal, 17)
                            .frame(height: 37)
                            .background(selectedFilter == filter ? MarketStyle.purple : .white, in: Capsule())
                            .overlay(Capsule().stroke(selectedFilter == filter ? Color.clear : MarketStyle.border, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                Spacer(minLength: 0)
            }
        }
    }
    private var unpublishedListingsSection: some View {
        let owned = store.items.filter { item in
            item.ownerUID == Auth.auth().currentUser?.uid &&
            (item.firestoreId.map { store.unpublishedSharedItemIds.contains($0) } ?? false)
        }
        return Group {
            if !owned.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("My unpublished listings")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    ForEach(owned) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name).font(.headline)
                                Text("Hidden from neighbours").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Republish") {
                                guard let id = item.firestoreId else { return }
                                Task { try? await store.setSharedItemPublished(itemId: id, published: true) }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(14)
                        .background(.white, in: RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
        }
    }
    private var listingsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("Explore listings")
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundStyle(MarketStyle.navy)
                Spacer()
                Text("\(visibleItems.count) \(visibleItems.count == 1 ? "item" : "items")")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(MarketStyle.muted)
            }
            if let error = store.sharedItemsError {
                Label("Unable to load items: \(error)", systemImage: "exclamationmark.triangle")
                    .font(.system(size: 12))
                    .foregroundStyle(.red)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white, in: RoundedRectangle(cornerRadius: 15))
            }
            if visibleItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(MarketStyle.purple)
                        .frame(width: 76, height: 76)
                        .background(MarketStyle.lavender, in: RoundedRectangle(cornerRadius: 24))
                    Text(searchText.isEmpty ? "Nothing shared yet" : "No matching items")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(MarketStyle.navy)
                    Text(searchText.isEmpty ? "Be the first to add something your neighbours can borrow." : "Try another search or choose a different filter.")
                        .font(.system(size: 13))
                        .foregroundStyle(MarketStyle.muted)
                        .multilineTextAlignment(.center)
                    Button {
                        if !searchText.isEmpty || selectedFilter != "All" {
                            searchText = ""
                            selectedFilter = "All"
                        } else {
                            showNewItem = true
                        }
                    } label: {
                        Label(
                            !searchText.isEmpty || selectedFilter != "All"
                                ? "Show All Items"
                                : "Share an Item",
                            systemImage: !searchText.isEmpty || selectedFilter != "All"
                                ? "arrow.counterclockwise"
                                : "plus.circle.fill"
                        )
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .frame(height: 44)
                        .background(MarketStyle.purple, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 38)
                .padding(.horizontal, 20)
                .background(.white, in: RoundedRectangle(cornerRadius: 24))
            } else {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(visibleItems) { item in
                        MarketItemCard(item: item)
                    }
                }
            }
        }
    }
}
private struct SharedListingPhotoView: View {
    let photoId: String
    @State private var image: UIImage?
    @State private var loadFailed = false
    var body: some View {
        Group {
            if let image {
                GeometryReader { geometry in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                }
            } else if loadFailed {
                Image(systemName: "photo")
                    .font(.system(size: 30))
                    .foregroundStyle(MarketStyle.muted)
            } else {
                ProgressView()
            }
        }
        .task(id: photoId) {
            image = nil
            loadFailed = false
            do {
                let document = try await Firestore.firestore()
                    .collection("sharedItemPhotos")
                    .document(photoId)
                    .getDocument()
                guard let base64 = document.data()?["imageBase64"] as? String,
                      let data = Data(base64Encoded: base64),
                      let decoded = UIImage(data: data) else {
                    loadFailed = true
                    return
                }
                image = decoded
            } catch {
                loadFailed = true
            }
        }
    }
}
private struct MarketItemCard: View {
    let item: SharedItem
    @State private var showDetails = false
    private var itemIcon: String {
        let name = item.name.lowercased()
        if name.contains("drill") || name.contains("tool") { return "wrench.and.screwdriver.fill" }
        if name.contains("chair") { return "chair.fill" }
        if name.contains("cake") || name.contains("mixer") { return "birthday.cake.fill" }
        if name.contains("ladder") { return "figure.stairs" }
        if name.contains("tent") { return "tent.fill" }
        if name.contains("book") { return "books.vertical.fill" }
        return "shippingbox.fill"
    }
    private var isMine: Bool { item.ownerUID == Auth.auth().currentUser?.uid }
    var body: some View {
        Button { showDetails = true } label: {
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: 17)
                        .fill(LinearGradient(colors: [MarketStyle.lavender, Color(red: 0.94, green: 0.96, blue: 1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    if let photoId = item.photoId {
                        SharedListingPhotoView(photoId: photoId)
                            .clipShape(RoundedRectangle(cornerRadius: 17))
                    } else {
                        Image(systemName: itemIcon)
                            .font(.system(size: 38, weight: .light))
                            .foregroundStyle(MarketStyle.purple)
                    }
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(MarketStyle.navy)
                                .frame(width: 28, height: 28)
                                .background(.white.opacity(0.88), in: Circle())
                        }
                        Spacer()
                    }
                    .padding(10)
                }
                .frame(height: 137)
                HStack(spacing: 5) {
                    Circle()
                        .fill(item.status == .lending ? MarketStyle.green : MarketStyle.purple)
                        .frame(width: 6, height: 6)
                    Text(item.status == .lending ? "AVAILABLE" : "NEEDED")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .tracking(0.6)
                        .foregroundStyle(item.status == .lending ? MarketStyle.green : MarketStyle.purple)
                }
                .padding(.top, 14)
                Text(item.name)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(MarketStyle.navy)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, minHeight: 40, alignment: .topLeading)
                    .padding(.top, 6)
                Label(item.ownerUnit.isEmpty ? item.ownerName : "\(item.ownerName) · \(item.ownerUnit)", systemImage: "person.crop.circle")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(MarketStyle.muted)
                    .lineLimit(1)
                    .padding(.top, 4)
                Text(item.detail)
                    .font(.system(size: 11))
                    .foregroundStyle(MarketStyle.muted)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, minHeight: 34, alignment: .topLeading)
                    .padding(.top, 9)
                Spacer(minLength: 12)
                HStack {
                    Text(isMine ? "View listing" : item.status == .lending ? "View & request" : "View needed item")
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.right")
                }
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(MarketStyle.purple)
                .padding(.horizontal, 11)
                .frame(height: 37)
                .background(MarketStyle.lavender.opacity(0.75), in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(11)
            .frame(maxWidth: .infinity, minHeight: 318, alignment: .topLeading)
            .background(.white, in: RoundedRectangle(cornerRadius: 23))
            .overlay(RoundedRectangle(cornerRadius: 23).stroke(MarketStyle.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetails) { BorrowItemDetailView(item: item) }
    }
}
#Preview {
    NavigationStack {
        LendBorrowView().environmentObject(AppStore())
    }
}
