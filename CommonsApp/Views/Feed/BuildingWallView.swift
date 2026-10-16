//
//  BuildingWallView.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 21/9/2026.
//

import SwiftUI

struct BuildingWallView: View {

    @EnvironmentObject var store: AppStore
    @State private var showNewPost = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "FBFAF7"), Color(hex: "F1F3F6")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    BuildingWallHeader()

                    RooftopEventCard()
                    if !store.pinnedAnnouncementText.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("PINNED ANNOUNCEMENT", systemImage: "pin.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color(hex: "6759BD"))

                            Text(store.pinnedAnnouncementText)
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "172034"))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.white.opacity(0.82))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay {
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(hex: "E0E3E8"), lineWidth: 1)
                        }
                        .padding(.top, 15)
                    }

                    LatestPostSection {
                        showNewPost = true
                    }
                    .padding(.top, 10)

                    LendingPreviewCard()
                        .padding(.top, 15)

                    UpcomingEventSection()
                        .padding(.top, 22)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 90)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)

        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showNewPost) {
            NewPostView()
        }
        .onAppear {
            store.startAnnouncementListener()
        }
        .onDisappear {
            store.stopAnnouncementListener()
        }
    }
}

struct BuildingWallHeader: View {
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 5) {
                Text("24 ASHCROFT LANE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color(hex: "818998"))

                Text("Good evening, Alex")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color(hex: "172034"))
            }

            Spacer()

            Text("AM")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color(hex: "6759BD"))
                .frame(width: 40, height: 40)
                .background(Color(hex: "ECE8FF"))
                .clipShape(Circle())
        }
        .padding(.horizontal, 4)
        .padding(.top, 3)
    }
}

struct RooftopEventCard: View {
    var body: some View {
        ZStack {
            Image("RooftopSupper")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 218)
                .clipped()

            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading) {
                HStack(spacing: 7) {
                    Circle()
                        .fill(Color(hex: "64E0B1"))
                        .frame(width: 8, height: 8)

                    Text("TONIGHT · 7:00 PM")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 12)
                .frame(height: 27)
                .background(Color(hex: "344D88").opacity(0.92))
                .clipShape(Capsule())

                Spacer()

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Rooftop supper")
                            .font(.system(size: 21, weight: .bold))
                            .foregroundStyle(.white)

                        Text("18 neighbours are joining")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.9))
                    }

                    Spacer()

                    Button("View event") {
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color(hex: "172034"))
                    .padding(.horizontal, 15)
                    .frame(height: 35)
                    .background(.white)
                    .clipShape(Capsule())
                }
            }
            .padding(13)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 218)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 4)
    }
}

struct LatestPostSection: View {
    let addPost: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text("Latest from Commons")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(hex: "172034"))

                Spacer()

                Button(action: addPost) {
                    HStack(spacing: 9) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .regular))

                        Text("Add post")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 15)
                    .frame(height: 34)
                    .background(Color(hex: "786EEA"))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 4)

            LatestPostCard()
        }
    }
}

struct LatestPostCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Text("M")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Color(hex: "746CE7"))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text("Maya · 7B")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(hex: "172034"))

                    Text("12 min ago")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "8A92A1"))
                }

                Spacer()

                Text("UPDATE")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color(hex: "3FA380"))
                    .padding(.horizontal, 13)
                    .frame(height: 24)
                    .background(Color(hex: "E8F8F2"))
                    .clipShape(Capsule())
            }

            Text("Courtyard lights are back")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color(hex: "172034"))
                .padding(.top, 15)

            Text("Thanks to everyone who reported it. The space\nfeels welcoming again tonight.")
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "7F8796"))
                .lineSpacing(4)
                .padding(.top, 7)

            HStack {
                Label("14 reactions", systemImage: "heart")

                Spacer()

                Text("12 replies")
            }
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(Color(hex: "7F8796"))
            .padding(.top, 7)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, minHeight: 150)
        .background(.white.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color(hex: "E0E3E8"), lineWidth: 1)
        }
    }
}

struct LendingPreviewCard: View {

    var body: some View {

        HStack(spacing: 16) {

            // Temporary image placeholder.
            // Later this area will display the item image
            // returned from the database/backend.
            DynamicImagePlaceholder(
                systemImage: "photo"
            )
            .frame(
                width: 87,
                height: 88
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 16
                )
            )

            VStack(
                alignment: .leading,
                spacing: 7
            ) {

                Text("LEND & BORROW")
                    .font(
                        .system(
                            size: 9,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(
                        Color(hex: "9A7425")
                    )

                Text("Cordless drill")
                    .font(
                        .system(
                            size: 15,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(
                        Theme.appNavy
                    )

                Text("Noah · 4A · Until Sunday")
                    .font(
                        .system(
                            size: 10
                        )
                    )
                    .foregroundStyle(
                        Theme.appMuted
                    )

                Text("BORROW")
                    .font(
                        .system(
                            size: 8,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(
                        Color(hex: "6858BD")
                    )
                    .padding(
                        .horizontal,
                        15
                    )
                    .frame(
                        height: 22
                    )
                    .background(
                        Color(hex: "EEEAFE")
                    )
                    .clipShape(
                        Capsule()
                    )
            }

            Spacer()
        }
        .padding(12)
        .frame(
            maxWidth: .infinity,
            minHeight: 112
        )
        .background(
            .white.opacity(0.82)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 24
            )
        )
        .overlay {

            RoundedRectangle(
                cornerRadius: 24
            )
            .stroke(
                Theme.appBorder,
                lineWidth: 1
            )
        }
    }
}
struct DynamicImagePlaceholder: View {

    let systemImage: String

    var body: some View {

        ZStack {

            LinearGradient(
                colors: [
                    Theme.purple.opacity(0.18),
                    Theme.info.opacity(0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: systemImage)
                .font(
                    .system(
                        size: 28,
                        weight: .medium
                    )
                )
                .foregroundStyle(
                    Theme.purple.opacity(0.65)
                )
        }
    }
}

struct UpcomingEventSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Coming up")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color(hex: "172034"))
                .padding(.horizontal, 4)

            HStack(spacing: 12) {
                Image(systemName: "circle.circle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: "6F61D0"))
                    .frame(width: 30, height: 30)
                    .background(Color(hex: "ECE8FF"))
                    .clipShape(RoundedRectangle(cornerRadius: 9))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Residents meeting")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color(hex: "172034"))

                    Text("Tomorrow · 6:30 PM · Community Room")
                        .font(.system(size: 9))
                        .foregroundStyle(Color(hex: "8A92A1"))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color(hex: "9AA1AE"))
            }
            .padding(.horizontal, 13)
        }
    }
}

#Preview {
    NavigationStack {
        BuildingWallView()
    }
}
