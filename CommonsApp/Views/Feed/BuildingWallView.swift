import SwiftUI
import FirebaseFirestore
import UIKit
private enum WallStyle {
    static let navy = Theme.appNavy
    static let purple = Theme.appPurple
    static let muted = Theme.appMuted
    static let canvas = Theme.wallBackgroundBottom
    static let line = Theme.appBorder
    static let soft = Theme.appPurpleSoft
    static let card = Theme.card
    static let radius: CGFloat = 22
    static let horizontalPadding: CGFloat = 20
}
private struct WallSectionHeading: View {
    let title: String
    let subtitle: String?
    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(Theme.display(21, weight: .bold))
                .foregroundStyle(WallStyle.navy)
            if let subtitle {
                Text(subtitle)
                    .font(Theme.ui(12))
                    .foregroundStyle(WallStyle.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
private struct WallCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(WallStyle.card, in: RoundedRectangle(cornerRadius: WallStyle.radius))
            .overlay {
                RoundedRectangle(cornerRadius: WallStyle.radius)
                    .stroke(WallStyle.line, lineWidth: 1)
            }
    }
}
private extension View {
    func wallCard() -> some View { modifier(WallCardModifier()) }
}
struct BuildingWallView: View {
    @EnvironmentObject var store: AppStore
    @State private var showNewPost = false
    @State private var selectedSection: WallSection = .overview
    private enum WallSection: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case posts = "Posts"
        case sharing = "Sharing"
        case events = "Events"
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .overview: return "square.grid.2x2"
            case .posts: return "text.bubble"
            case .sharing: return "hand.raised"
            case .events: return "calendar"
            }
        }
    }
    var body: some View {
        ZStack {
            WallStyle.canvas.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    BuildingWallHeader()
                    sectionPicker
                    switch selectedSection {
                    case .overview:
                        if !store.pinnedAnnouncementText.isEmpty {
                            pinnedCard
                        }
                        RooftopEventCard(cardWidth: 0)
                        UpcomingEventSection()
                        LatestPostSection(maxPosts: 2, addPost: { showNewPost = true })
                        Button("View all community posts") {
                            selectedSection = .posts
                        }
                        .font(Theme.ui(13, weight: .bold))
                        .foregroundStyle(WallStyle.purple)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        LendingPreviewCard()
                    case .posts:
                        LatestPostSection(maxPosts: nil, addPost: { showNewPost = true })
                    case .sharing:
                        LendingPreviewCard()
                    case .events:
                        UpcomingEventSection()
                    }
                }
                .padding(.horizontal, WallStyle.horizontalPadding)
                .padding(.top, 18)
                .padding(.bottom, 140)
            }
            .scrollIndicators(.hidden)
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showNewPost) { NewPostView() }
        .onAppear {
            store.startAnnouncementListener()
            store.startResidentPostsListener()
        }
        .onDisappear {
            store.stopAnnouncementListener()
            store.stopResidentPostsListener()
        }
    }
    private var sectionPicker: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(WallSection.allCases) { section in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedSection = section
                            }
                        } label: {
                            Label(section.rawValue, systemImage: section.icon)
                                .font(Theme.ui(12, weight: .semibold))
                                .foregroundStyle(
                                    selectedSection == section
                                        ? Color.white
                                        : WallStyle.navy
                                )
                                .padding(.horizontal, 15)
                                .frame(height: 43)
                                .background(
                                    selectedSection == section
                                        ? WallStyle.purple
                                        : WallStyle.card,
                                    in: Capsule()
                                )
                                .overlay {
                                    Capsule()
                                        .stroke(
                                            selectedSection == section
                                                ? Color.clear
                                                : WallStyle.line,
                                            lineWidth: 1
                                        )
                                }
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(
                            selectedSection == section ? .isSelected : []
                        )
                    }
                }
                .frame(minWidth: geometry.size.width, alignment: .leading)
            }
            .frame(width: geometry.size.width)
            .contentMargins(.leading, 2, for: .scrollContent)
        }
        .frame(height: 43)
        .frame(maxWidth: .infinity)
        .accessibilityLabel("Community Wall sections")
    }
    private var pinnedCard: some View {
        HStack(alignment: .top, spacing: 13) {
            Image(systemName: "pin.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(WallStyle.purple)
                .frame(width: 44, height: 44)
                .background(WallStyle.soft, in: RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 7) {
                Text("FROM BUILDING MANAGEMENT")
                    .font(Theme.ui(10, weight: .bold))
                    .tracking(0.9)
                    .foregroundStyle(WallStyle.purple)
                Text(store.pinnedAnnouncementText)
                    .font(Theme.ui(14, weight: .medium))
                    .foregroundStyle(WallStyle.navy)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(17)
        .frame(maxWidth: .infinity, alignment: .leading)
        .wallCard()
        .accessibilityElement(children: .combine)
    }
}
struct BuildingWallHeader: View {
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 7) {
                Text("24 ASHCROFT LANE")
                    .font(Theme.ui(10, weight: .bold))
                    .tracking(1.3)
                    .foregroundStyle(WallStyle.purple)
                Text("Your community")
                    .font(Theme.display(30, weight: .bold))
                    .foregroundStyle(WallStyle.navy)
                    .minimumScaleFactor(0.8)
                    .lineLimit(2)
                Text("A little closer to home.")
                    .font(Theme.ui(13))
                    .foregroundStyle(WallStyle.muted)
            }
            Spacer(minLength: 0)
            Image(systemName: "building.2.crop.circle.fill")
                .font(.system(size: 28))
                .foregroundStyle(WallStyle.purple)
                .frame(width: 56, height: 56)
                .background(WallStyle.soft, in: RoundedRectangle(cornerRadius: 18))
                .accessibilityHidden(true)
        }
    }
}
struct RooftopEventCard: View {
    let cardWidth: CGFloat
    @State private var selectedImage = 0
    private let imageNames = ["CommunityInspiration1", "CommunityInspiration2", "CommunityInspiration3", "CommunityInspiration4", "CommunityInspiration5", "CommunityInspiration6"]
    private let quotes = ["Make memories together", "A kinder neighbourhood makes a brighter tomorrow", "Small conversations build big communities", "A healthier community is a happier community", "Good neighbours make home feel special", "Different people, brighter days"]
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            GeometryReader { geometry in
                Image(imageNames[selectedImage])
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .id(selectedImage)
                    .transition(.opacity)
            }
            LinearGradient(
                colors: [.black.opacity(0.08), .black.opacity(0.18), .black.opacity(0.83)],
                startPoint: .top,
                endPoint: .bottom
            )
            VStack(alignment: .leading, spacing: 10) {
                Label("COMMUNITY INSPIRATION", systemImage: "sparkles")
                    .font(Theme.ui(10, weight: .bold))
                    .tracking(0.7)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.38), in: Capsule())
                Spacer(minLength: 0)
                Text(quotes[selectedImage])
                    .font(Theme.display(27, weight: .bold))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Community Area · Lets Connect")
                    .font(Theme.ui(12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.92))
            }
            .foregroundStyle(.white)
            .padding(20)
        }
        .frame(height: 228)
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .accessibilityElement(children: .combine)
        .task {
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(15))
                } catch {
                    break
                }
                if Task.isCancelled { break }
                withAnimation(.easeInOut(duration: 0.8)) {
                    selectedImage = (selectedImage + 1) % imageNames.count
                }
            }
        }
    }
}
struct LatestPostSection: View {
    @EnvironmentObject var store: AppStore
    let maxPosts: Int?
    let addPost: () -> Void
    private var sortedPosts: [Post] {
        (store.posts.filter { !$0.isPinned } + store.eventNoticePosts)
            .sorted { $0.timestamp > $1.timestamp }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                WallSectionHeading("Community feed", subtitle: "Updates from your neighbours")
                Button(action: addPost) {
                    Label("Post", systemImage: "plus")
                        .font(Theme.ui(13, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .frame(minHeight: 44)
                        .background(WallStyle.purple, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Create a community post")
            }
            if sortedPosts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "text.bubble.fill")
                        .font(.system(size: 25))
                        .foregroundStyle(WallStyle.purple)
                        .frame(width: 60, height: 60)
                        .background(WallStyle.soft, in: RoundedRectangle(cornerRadius: 20))
                    Text("Your community starts here")
                        .font(Theme.ui(16, weight: .bold))
                        .foregroundStyle(WallStyle.navy)
                    Text("Share an update, a question, or something your neighbours should know.")
                        .font(Theme.ui(13))
                        .foregroundStyle(WallStyle.muted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("Create the first post", action: addPost)
                        .font(Theme.ui(13, weight: .bold))
                        .foregroundStyle(WallStyle.purple)
                        .padding(.top, 3)
                        .frame(minHeight: 44)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .wallCard()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(Array(sortedPosts.prefix(maxPosts ?? sortedPosts.count))) { post in
                        LatestPostCard(post: post)
                    }
                }
            }
        }
    }
}
private struct CommunityPostPhotoView: View {
    let photoId: String
    @State private var image: UIImage?
    @State private var loadFailed = false
    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            } else if loadFailed {
                Label("Photo unavailable", systemImage: "photo")
                    .font(Theme.ui(12))
                    .foregroundStyle(WallStyle.muted)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
            }
        }
        .task(id: photoId) {
            image = nil
            loadFailed = false
            do {
                let document = try await Firestore.firestore()
                    .collection("residentPostPhotos")
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
struct LatestPostCard: View {
    let post: Post
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .center, spacing: 11) {
                Text(String(post.authorName.prefix(1)).uppercased())
                    .font(Theme.ui(16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(WallStyle.purple, in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(post.authorUnit.isEmpty
                         ? post.authorName
                         : "\(post.authorName) · \(post.authorUnit)")
                        .font(Theme.ui(14, weight: .bold))
                        .foregroundStyle(WallStyle.navy)
                        .lineLimit(1)
                    Text(post.timestamp, style: .relative)
                        .font(Theme.ui(11))
                        .foregroundStyle(WallStyle.muted)
                }
                Spacer(minLength: 4)
            }
            Text(post.text)
                .font(Theme.ui(14))
                .foregroundStyle(WallStyle.navy)
                .fixedSize(horizontal: false, vertical: true)
            if let photoId = post.photoId {
                CommunityPostPhotoView(photoId: photoId)
            }
            HStack {
                Text(post.category.rawValue.uppercased())
                    .font(Theme.ui(10, weight: .bold))
                    .tracking(0.5)
                    .foregroundStyle(WallStyle.purple)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(WallStyle.soft, in: Capsule())
                Spacer(minLength: 0)
            }
            Rectangle()
                .fill(WallStyle.line)
                .frame(height: 1)
            HStack(spacing: 18) {
                Label("\(post.likeCount) reactions", systemImage: "heart")
                Label("\(post.replyCount) replies", systemImage: "bubble.right")
                Spacer(minLength: 0)
            }
            .font(Theme.ui(11, weight: .medium))
            .foregroundStyle(WallStyle.muted)
        }
        .padding(17)
        .frame(maxWidth: .infinity, alignment: .leading)
        .wallCard()
    }
}
struct LendingPreviewCard: View {
    @EnvironmentObject private var store: AppStore
    private var publishedItems: [SharedItem] {
        store.items.filter { item in
            guard let id = item.firestoreId else { return false }
            return !store.unpublishedSharedItemIds.contains(id)
                && !store.reservedSharedItemIds.contains(id)
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            WallSectionHeading(
                "Neighbourhood sharing",
                subtitle: "What your neighbours are lending and looking for"
            )
            if publishedItems.isEmpty {
                HStack(spacing: 14) {
                    DynamicImagePlaceholder(systemImage: "shippingbox")
                        .frame(width: 72, height: 76)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    VStack(alignment: .leading, spacing: 6) {
                        Text("No shared listings yet")
                            .font(Theme.ui(15, weight: .bold))
                            .foregroundStyle(WallStyle.navy)
                        Text("Neighbours' lending offers and borrowing needs will appear here.")
                            .font(Theme.ui(12))
                            .foregroundStyle(WallStyle.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .padding(14)
                .wallCard()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(Array(publishedItems.prefix(3))) { item in
                        HStack(alignment: .top, spacing: 14) {
                            DynamicImagePlaceholder(
                                systemImage: item.status == .lending
                                    ? "shippingbox"
                                    : "hand.raised"
                            )
                            .frame(width: 72, height: 76)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.status == .lending
                                     ? "AVAILABLE TO LEND"
                                     : "LOOKING TO BORROW")
                                    .font(Theme.ui(10, weight: .bold))
                                    .tracking(0.6)
                                    .foregroundStyle(WallStyle.purple)
                                Text(item.name)
                                    .font(Theme.ui(15, weight: .bold))
                                    .foregroundStyle(WallStyle.navy)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(item.detail)
                                    .font(Theme.ui(12))
                                    .foregroundStyle(WallStyle.muted)
                                    .lineLimit(2)
                                Text(item.ownerUnit.isEmpty
                                     ? item.ownerName
                                     : "\(item.ownerName) · \(item.ownerUnit)")
                                    .font(Theme.ui(11, weight: .medium))
                                    .foregroundStyle(WallStyle.muted)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .wallCard()
                    }
                }
            }
        }
    }
}
struct DynamicImagePlaceholder: View {
    let systemImage: String
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [WallStyle.soft, Color(red: 0.89, green: 0.93, blue: 1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: systemImage)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(WallStyle.purple)
        }
        .accessibilityHidden(true)
    }
}
struct UpcomingEventSection: View {
    @EnvironmentObject private var store: AppStore
    private var upcoming: [BuildingEvent] {
        store.events
            .filter { !$0.isCancelled && $0.date >= Date() }
            .sorted { $0.date < $1.date }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            WallSectionHeading("Coming up", subtitle: "What's happening in your building")
            if upcoming.isEmpty {
                HStack(spacing: 13) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 21))
                        .foregroundStyle(WallStyle.purple)
                        .frame(width: 48, height: 48)
                        .background(WallStyle.soft, in: RoundedRectangle(cornerRadius: 15))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("No upcoming events yet")
                            .font(Theme.ui(14, weight: .bold))
                            .foregroundStyle(WallStyle.navy)
                        Text("New community activities will appear here.")
                            .font(Theme.ui(12))
                            .foregroundStyle(WallStyle.muted)
                    }
                    Spacer(minLength: 0)
                }
                .padding(16)
                .wallCard()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(upcoming.prefix(3)) { event in
                        HStack(spacing: 13) {
                            if event.coverId != nil {
                                EventCoverImage(coverId: event.coverId).frame(width: 48, height: 48).clipShape(RoundedRectangle(cornerRadius: 15))
                            } else {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 20))
                                .foregroundStyle(WallStyle.purple)
                                .frame(width: 48, height: 48)
                                .background(WallStyle.soft, in: RoundedRectangle(cornerRadius: 15))
                            }
                            VStack(alignment: .leading, spacing: 5) {
                                Text(event.title)
                                    .font(Theme.ui(14, weight: .bold))
                                    .foregroundStyle(WallStyle.navy)
                                Text(event.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(Theme.ui(12, weight: .semibold))
                                    .foregroundStyle(WallStyle.purple)
                                Text(event.location)
                                    .font(Theme.ui(11))
                                    .foregroundStyle(WallStyle.muted)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .wallCard()
                    }
                }
            }
        }
    }
}
#Preview {
    NavigationStack {
        BuildingWallView()
            .environmentObject(AppStore())
    }
}
