import SwiftUI

private enum WallStyle {
    static let navy = Color(red: 0.11, green: 0.16, blue: 0.27)
    static let purple = Color(red: 0.46, green: 0.40, blue: 0.94)
    static let muted = Color(red: 0.46, green: 0.50, blue: 0.59)
    static let canvas = Color(red: 0.97, green: 0.97, blue: 0.99)
    static let line = Color(red: 0.89, green: 0.90, blue: 0.94)
    static let soft = Color(red: 0.94, green: 0.93, blue: 1.0)
}

struct BuildingWallView: View {
    @EnvironmentObject var store: AppStore
    @State private var showNewPost = false

    var body: some View {
        ZStack {
            WallStyle.canvas.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    BuildingWallHeader()
                    RooftopEventCard(cardWidth: 0)
                    if !store.pinnedAnnouncementText.isEmpty {
                        pinnedCard
                    }
                    LatestPostSection { showNewPost = true }
                    LendingPreviewCard()
                    UpcomingEventSection()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
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

    private var pinnedCard: some View {
        HStack(alignment: .top, spacing: 13) {
            Image(systemName: "pin.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(WallStyle.purple)
                .frame(width: 40, height: 40)
                .background(WallStyle.soft, in: RoundedRectangle(cornerRadius: 13))
            VStack(alignment: .leading, spacing: 7) {
                Text("PINNED ANNOUNCEMENT")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(WallStyle.purple)
                Text(store.pinnedAnnouncementText)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(WallStyle.navy)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(17)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(WallStyle.line, lineWidth: 1))
    }
}

struct BuildingWallHeader: View {
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("24 ASHCROFT LANE")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.4)
                    .foregroundStyle(WallStyle.muted)
                Text("Your community")
                    .font(.system(size: 29, weight: .bold, design: .rounded))
                    .foregroundStyle(WallStyle.navy)
                Text("Discover what's happening around you")
                    .font(.system(size: 12))
                    .foregroundStyle(WallStyle.muted)
            }
            Spacer(minLength: 4)
            Image(systemName: "building.2.crop.circle.fill")
                .font(.system(size: 31))
                .foregroundStyle(WallStyle.purple)
                .frame(width: 52, height: 52)
                .background(WallStyle.soft, in: Circle())
        }
    }
}

struct RooftopEventCard: View {
    let cardWidth: CGFloat
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            GeometryReader { geo in
                Image("RooftopSupper")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
            LinearGradient(colors: [.black.opacity(0.03), .black.opacity(0.12), .black.opacity(0.83)], startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 12) {
                Label("COMMUNITY HIGHLIGHT", systemImage: "sparkles")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.42), in: Capsule())
                Spacer()
                Text("Rooftop supper")
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                HStack(alignment: .center) {
                    Label("Tonight · 7:00 PM", systemImage: "calendar")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.95))
                    Spacer()
                    Text("18 joining")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 7)
                        .background(.white.opacity(0.22), in: Capsule())
                }
            }
            .padding(19)
        }
        .frame(height: 240)
        .clipShape(RoundedRectangle(cornerRadius: 26))
    }
}

struct LatestPostSection: View {
    @EnvironmentObject var store: AppStore
    let addPost: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Community feed")
                        .font(.system(size: 21, weight: .bold, design: .rounded))
                        .foregroundStyle(WallStyle.navy)
                    Text("Updates from your neighbours")
                        .font(.system(size: 12))
                        .foregroundStyle(WallStyle.muted)
                }
                Spacer()
                Button(action: addPost) {
                    Label("Post", systemImage: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .frame(height: 39)
                        .background(WallStyle.purple, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            let posts = store.posts.filter { !$0.isPinned }
            if posts.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 29))
                        .foregroundStyle(WallStyle.purple)
                    Text("No posts yet")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(WallStyle.navy)
                    Text("Be the first to share an update with your community.")
                        .font(.system(size: 12))
                        .foregroundStyle(WallStyle.muted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 35)
                .background(.white, in: RoundedRectangle(cornerRadius: 22))
            } else {
                ForEach(posts) { post in LatestPostCard(post: post) }
            }
        }
    }
}

struct LatestPostCard: View {
    let post: Post
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 11) {
                Text(String(post.authorName.prefix(1)).uppercased())
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(WallStyle.purple, in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text(post.authorUnit.isEmpty ? post.authorName : "\(post.authorName) · \(post.authorUnit)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(WallStyle.navy)
                        .lineLimit(1)
                    Text(post.timestamp, style: .relative)
                        .font(.system(size: 11))
                        .foregroundStyle(WallStyle.muted)
                }
                Spacer(minLength: 5)
                Text(post.category.rawValue.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(WallStyle.purple)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(WallStyle.soft, in: Capsule())
            }
            Text(post.text)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(WallStyle.navy)
                .fixedSize(horizontal: false, vertical: true)
            Rectangle().fill(WallStyle.line).frame(height: 1)
            HStack(spacing: 17) {
                Label("\(post.likeCount) reactions", systemImage: "heart")
                Label("\(post.replyCount) replies", systemImage: "bubble.right")
                Spacer()
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(WallStyle.muted)
        }
        .padding(17)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(WallStyle.line, lineWidth: 1))
    }
}

struct LendingPreviewCard: View {
    var body: some View {
        HStack(spacing: 14) {
            DynamicImagePlaceholder(systemImage: "wrench.adjustable")
                .frame(width: 90, height: 94)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            VStack(alignment: .leading, spacing: 7) {
                Text("NEIGHBOURHOOD SHARING")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(0.7)
                    .foregroundStyle(WallStyle.purple)
                Text("Cordless drill")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(WallStyle.navy)
                Text("Noah · 4A · Until Sunday")
                    .font(.system(size: 11))
                    .foregroundStyle(WallStyle.muted)
                Text("AVAILABLE TO BORROW")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color(red: 0.14, green: 0.57, blue: 0.43))
            }
            Spacer(minLength: 0)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(WallStyle.line, lineWidth: 1))
    }
}

struct DynamicImagePlaceholder: View {
    let systemImage: String
    var body: some View {
        ZStack {
            LinearGradient(colors: [WallStyle.soft, Color(red: 0.89, green: 0.93, blue: 1)], startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: systemImage)
                .font(.system(size: 29, weight: .medium))
                .foregroundStyle(WallStyle.purple)
        }
    }
}

struct UpcomingEventSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Coming up")
                .font(.system(size: 21, weight: .bold, design: .rounded))
                .foregroundStyle(WallStyle.navy)
            HStack(spacing: 13) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(WallStyle.purple)
                    .frame(width: 48, height: 48)
                    .background(WallStyle.soft, in: RoundedRectangle(cornerRadius: 15))
                VStack(alignment: .leading, spacing: 5) {
                    Text("Residents meeting")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(WallStyle.navy)
                    Text("Tomorrow · 6:30 PM")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(WallStyle.purple)
                    Text("Community Room")
                        .font(.system(size: 11))
                        .foregroundStyle(WallStyle.muted)
                }
                Spacer()
            }
            .padding(15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white, in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(WallStyle.line, lineWidth: 1))
        }
    }
}

#Preview {
    NavigationStack {
        BuildingWallView().environmentObject(AppStore())
    }
}
