import SwiftUI

import FirebaseAuth



private enum BorrowUI {

    static let purple = Color(red: 0.46, green: 0.40, blue: 0.96)

    static let navy = Color(red: 0.12, green: 0.17, blue: 0.28)

    static let bg = Color(red: 0.97, green: 0.97, blue: 0.99)

    static let muted = Color(red: 0.39, green: 0.44, blue: 0.53)

    static let white = Color.white

}



struct BorrowItemDetailView: View {

    @EnvironmentObject private var store: AppStore

    @Environment(\.dismiss) private var dismiss

    let item: SharedItem

    @State private var showForm = false

    private var mine: Bool { item.ownerUID == Auth.auth().currentUser?.uid }



    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(alignment: .leading, spacing: 20) {

                    hero

                    VStack(alignment: .leading, spacing: 10) {

                        Text(item.name)

                            .font(.system(size: 29, weight: .bold, design: .rounded))

                            .foregroundStyle(BorrowUI.navy)

                        Label(item.availability, systemImage: "calendar.badge.clock")

                            .font(.system(size: 13, weight: .semibold))

                            .foregroundStyle(BorrowUI.purple)

                            .padding(.horizontal, 13).padding(.vertical, 9)

                            .background(BorrowUI.purple.opacity(0.09), in: Capsule())

                    }

                    BorrowSurface {

                        VStack(alignment: .leading, spacing: 11) {

                            BorrowSectionTitle(title: "About this item", icon: "text.alignleft")

                            Text(item.detail.isEmpty ? "No description provided." : item.detail)

                                .font(.system(size: 15)).foregroundStyle(BorrowUI.navy)

                                .fixedSize(horizontal: false, vertical: true)

                        }

                    }

                    BorrowSurface {

                        HStack(spacing: 13) {

                            Image(systemName: "person.crop.circle.fill")

                                .font(.system(size: 34)).foregroundStyle(BorrowUI.purple)

                                .frame(width: 48, height: 48)

                                .background(BorrowUI.purple.opacity(0.09), in: RoundedRectangle(cornerRadius: 15))

                            VStack(alignment: .leading, spacing: 4) {

                                Text("SHARED BY").font(.system(size: 10, weight: .bold)).tracking(1.1)

                                    .foregroundStyle(BorrowUI.muted)

                                Text(item.ownerName).font(.system(size: 16, weight: .semibold))

                                    .foregroundStyle(BorrowUI.navy)

                                if !item.ownerUnit.isEmpty {

                                    Text("Unit \(item.ownerUnit)").font(.system(size: 12))

                                        .foregroundStyle(BorrowUI.muted)

                                }

                            }

                            Spacer()

                        }

                    }

                    if mine {

                        BorrowInfoBanner(message: "This is your listing.", icon: "checkmark.shield")

                    } else {

                        Button { showForm = true } label: {

                            HStack(spacing: 10) {

                                Image(systemName: "hand.raised.fingers.spread.fill")

                                Text(item.status == .needed ? "Offer to Lend" : "Request to Borrow")

                                Spacer()

                                Image(systemName: "arrow.right")

                            }

                        }

                        .buttonStyle(BorrowPrimaryButtonStyle())

                    }

                }

                .padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 34)

            }

            .background(BorrowUI.bg.ignoresSafeArea())

            .navigationTitle("Item Details").navigationBarTitleDisplayMode(.inline)

            .toolbar {

                ToolbarItem(placement: .principal) {

                    Text("Item Details").font(.system(size: 16, weight: .bold, design: .rounded))

                        .foregroundStyle(BorrowUI.navy)

                }

                ToolbarItem(placement: .topBarTrailing) {

                    Button { dismiss() } label: { BorrowCloseIcon() }

                }

            }

            .toolbarColorScheme(.light, for: .navigationBar)

            .sheet(isPresented: $showForm) { BorrowRequestFormView(item: item) }

        }

        .tint(BorrowUI.purple)

        .environment(\.colorScheme, .light)

        .preferredColorScheme(.light)

    }



    private var hero: some View {

        ZStack {

            RoundedRectangle(cornerRadius: 26, style: .continuous)

                .fill(LinearGradient(colors: [BorrowUI.purple.opacity(0.17), BorrowUI.purple.opacity(0.055)],

                                     startPoint: .topLeading, endPoint: .bottomTrailing))

            Circle().fill(.white.opacity(0.40)).frame(width: 155, height: 155).offset(x: 110, y: -60)

            Circle().stroke(BorrowUI.purple.opacity(0.13), lineWidth: 2)

                .frame(width: 195, height: 195).offset(x: -125, y: 95)

            Image(systemName: "shippingbox.fill")

                .font(.system(size: 76, weight: .ultraLight))

                .foregroundStyle(BorrowUI.purple)

        }

        .frame(height: 205).clipped()

        .overlay(alignment: .topLeading) {

            Label("COMMUNITY SHARE", systemImage: "sparkles")

                .font(.system(size: 10, weight: .bold, design: .rounded)).tracking(1.2)

                .foregroundStyle(BorrowUI.purple)

                .padding(.horizontal, 12).padding(.vertical, 8)

                .background(.white.opacity(0.86), in: Capsule())

                .padding(16)

        }

    }

}



struct BorrowRequestFormView: View {

    @EnvironmentObject private var store: AppStore

    @Environment(\.dismiss) private var dismiss

    let item: SharedItem

    @State private var startDate = Date()

    @State private var endDate = Date()

    @State private var note = ""

    @State private var busy = false

    @State private var errorText: String?



    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(alignment: .leading, spacing: 20) {

                    VStack(alignment: .leading, spacing: 6) {

                        Text(item.status == .needed ? "Offer your item" : "Borrow this item")

                            .font(.system(size: 29, weight: .bold, design: .rounded))

                            .foregroundStyle(BorrowUI.navy)

                        Text(item.status == .needed ? "Propose collection and return dates to the resident who needs this item." : "Choose your dates and send a request to the owner.")

                            .font(.subheadline).foregroundStyle(BorrowUI.muted)

                    }

                    .padding(.top, 12)

                    BorrowSurface {

                        HStack(spacing: 13) {

                            Image(systemName: "shippingbox.fill")

                                .font(.system(size: 23)).foregroundStyle(BorrowUI.purple)

                                .frame(width: 54, height: 54)

                                .background(BorrowUI.purple.opacity(0.10), in: RoundedRectangle(cornerRadius: 16))

                            VStack(alignment: .leading, spacing: 5) {

                                Text("YOUR SELECTED ITEM")

                                    .font(.system(size: 10, weight: .bold)).tracking(1.0)

                                    .foregroundStyle(BorrowUI.muted)

                                Text(item.name)

                                    .font(.system(size: 17, weight: .bold, design: .rounded))

                                    .foregroundStyle(BorrowUI.navy)

                            }

                            Spacer(minLength: 0)

                        }

                    }

                    BorrowSurface {

                        VStack(alignment: .leading, spacing: 17) {

                            BorrowSectionTitle(title: "Borrowing dates", icon: "calendar")

                            DatePicker("Collect on", selection: $startDate, in: Date()..., displayedComponents: .date)

                                .font(.system(size: 15, weight: .medium))

                                .foregroundStyle(BorrowUI.navy)

                            Rectangle().fill(BorrowUI.navy.opacity(0.08)).frame(height: 1)

                            DatePicker("Return by", selection: $endDate, in: startDate..., displayedComponents: .date)

                                .font(.system(size: 15, weight: .medium))

                                .foregroundStyle(BorrowUI.navy)

                        }

                    }

                    BorrowSurface {

                        VStack(alignment: .leading, spacing: 12) {

                            BorrowSectionTitle(title: item.status == .needed ? "Note to requester" : "Note to owner", icon: "text.bubble")

                            ZStack(alignment: .topLeading) {

                                if note.isEmpty {

                                    Text("Any collection details? (optional)")

                                        .font(.system(size: 14)).foregroundStyle(BorrowUI.muted.opacity(0.7))

                                        .padding(.horizontal, 13).padding(.top, 14)

                                }

                                TextEditor(text: $note)

                                    .font(.system(size: 14))

                                    .foregroundStyle(BorrowUI.navy)

                                    .scrollContentBackground(.hidden)

                                    .padding(8)

                                    .frame(height: 104)

                            }

                            .background(BorrowUI.bg, in: RoundedRectangle(cornerRadius: 14))

                            Text("\(note.count)/500 characters")

                                .font(.system(size: 11))

                                .foregroundStyle(note.count > 500 ? .red : BorrowUI.muted)

                                .frame(maxWidth: .infinity, alignment: .trailing)

                        }

                    }

                    BorrowInfoBanner(message: item.status == .needed ? "The resident who needs the item will review your offer before collection." : "The owner will review your request before collection is confirmed.", icon: "checkmark.shield")

                    Button {

                        guard !busy else { return }

                        busy = true

                        Task { @MainActor in

                            defer { busy = false }

                            do {

                                try await store.submitBorrowRequest(for: item,

                                    startDate: startDate, endDate: endDate, note: note)

                                dismiss()

                            } catch { errorText = error.localizedDescription }

                        }

                    } label: {

                        HStack(spacing: 10) {

                            if busy { ProgressView().tint(.white) }

                            else { Image(systemName: "paperplane.fill") }

                            Text(busy ? "Submitting…" : (item.status == .needed ? "Send Offer" : "Submit Request"))

                            Spacer()

                            Image(systemName: "arrow.right")

                        }

                    }

                    .buttonStyle(BorrowPrimaryButtonStyle())

                    .disabled(busy || endDate < startDate || note.count > 500)

                    .opacity(busy || endDate < startDate || note.count > 500 ? 0.55 : 1)

                }

                .padding(.horizontal, 20).padding(.bottom, 34)

            }

            .background(BorrowUI.bg.ignoresSafeArea())

            .navigationTitle("Request to Borrow").navigationBarTitleDisplayMode(.inline)

            .toolbar {

                ToolbarItem(placement: .principal) {

                    Text("Request to Borrow").font(.system(size: 16, weight: .bold, design: .rounded))

                        .foregroundStyle(BorrowUI.navy)

                }

                ToolbarItem(placement: .topBarTrailing) {

                    Button { dismiss() } label: { BorrowCloseIcon() }

                }

            }

            .toolbarColorScheme(.light, for: .navigationBar)

            .alert("Request failed", isPresented: Binding(get: { errorText != nil },

                set: { if !$0 { errorText = nil } })) {

                Button("OK", role: .cancel) { errorText = nil }

            } message: { Text(errorText ?? "") }

        }

        .tint(BorrowUI.purple)

        .environment(\.colorScheme, .light)

        .preferredColorScheme(.light)

    }

}



private struct BorrowSectionTitle: View {

    let title: String

    let icon: String

    var body: some View {

        Label(title, systemImage: icon)

            .font(.system(size: 15, weight: .bold, design: .rounded))

            .foregroundStyle(BorrowUI.navy)

    }

}



private struct BorrowCloseIcon: View {

    var body: some View {

        Image(systemName: "xmark")

            .font(.system(size: 12, weight: .bold))

            .foregroundStyle(BorrowUI.navy)

            .frame(width: 32, height: 32)

            .background(.white, in: Circle())

    }

}



private struct BorrowInfoBanner: View {

    let message: String

    let icon: String

    var body: some View {

        HStack(alignment: .top, spacing: 10) {

            Image(systemName: icon).foregroundStyle(BorrowUI.purple)

            Text(message).font(.system(size: 13)).foregroundStyle(BorrowUI.muted)

                .fixedSize(horizontal: false, vertical: true)

        }

        .padding(15)

        .frame(maxWidth: .infinity, alignment: .leading)

        .background(BorrowUI.purple.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))

    }

}



private struct BorrowPrimaryButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {

        configuration.label

            .font(.system(size: 16, weight: .bold, design: .rounded))

            .foregroundStyle(.white)

            .padding(.horizontal, 20)

            .frame(maxWidth: .infinity, minHeight: 56)

            .background(BorrowUI.purple, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            .shadow(color: BorrowUI.purple.opacity(0.20), radius: 11, y: 5)

            .opacity(configuration.isPressed ? 0.85 : 1)

    }

}



// MARK: - Shared borrowing presentation

private struct BorrowStatusPill: View {

    let status: BorrowRequest.Status

    private var tint: Color {

        switch status {

        case .returned: return Color(red: 0.10, green: 0.54, blue: 0.39)

        case .declined, .cancelled: return Color(red: 0.71, green: 0.29, blue: 0.33)

        case .pending: return Color(red: 0.64, green: 0.40, blue: 0.12)

        default: return BorrowUI.purple

        }

    }

    var body: some View {

        HStack(spacing: 5) {

            Circle().fill(tint).frame(width: 6, height: 6)

            Text(status.label).font(.system(size: 12, weight: .semibold))

        }

        .foregroundStyle(tint)

        .padding(.horizontal, 11).padding(.vertical, 7)

        .background(tint.opacity(0.10), in: Capsule())

    }

}



private struct BorrowSurface<Content: View>: View {

    let content: Content

    init(@ViewBuilder content: () -> Content) {

        self.content = content()

    }

    var body: some View {

        content

            .padding(18)

            .frame(maxWidth: .infinity, alignment: .leading)

            .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)

                .stroke(BorrowUI.navy.opacity(0.055), lineWidth: 1))

            .shadow(color: BorrowUI.navy.opacity(0.045), radius: 14, y: 5)

    }

}



struct BorrowRequestsView: View {

    @EnvironmentObject private var store: AppStore

    @Environment(\.dismiss) private var dismiss

    @State private var tab = 0

    @State private var selected: BorrowRequest?

    private var uid: String { Auth.auth().currentUser?.uid ?? "" }

    private let tabs = ["Borrowing", "Incoming", "History"]



    private var visible: [BorrowRequest] {

        store.borrowRequests.filter { request in

            switch tab {

            case 0: return (request.isNeededOffer ? request.ownerUID : request.borrowerUID) == uid && !request.status.isHistory

            case 1: return (request.isNeededOffer ? request.borrowerUID : request.ownerUID) == uid && !request.status.isHistory

            default: return request.status.isHistory

            }

        }

    }

    private var subtitle: String {

        switch tab {

        case 0: return "Track items you've requested from neighbours."

        case 1: return "Manage requests for items you're sharing."

        default: return "A record of your completed and closed requests."

        }

    }

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(alignment: .leading, spacing: 22) {

                    VStack(alignment: .leading, spacing: 7) {

                        HStack(spacing: 9) {

                            Image(systemName: "shippingbox.fill")

                                .font(.system(size: 13, weight: .bold))

                                .foregroundStyle(BorrowUI.purple)

                            Text("LEND & BORROW")

                                .font(.system(size: 11, weight: .bold, design: .rounded))

                                .tracking(1.8).foregroundStyle(BorrowUI.purple)

                        }

                        Text("My Requests")

                            .font(.system(size: 32, weight: .bold, design: .rounded))

                            .foregroundStyle(BorrowUI.navy)

                        Text("Everything you're borrowing and lending, in one place.")

                            .font(.subheadline).foregroundStyle(BorrowUI.muted)

                            .fixedSize(horizontal: false, vertical: true)

                    }.padding(.top, 12)



                    HStack(spacing: 4) {

                        ForEach(0..<tabs.count, id: \.self) { index in

                            Button { withAnimation(.easeInOut(duration: 0.18)) { tab = index } } label: {

                                Text(tabs[index])

                                    .font(.system(size: 13, weight: .semibold))

                                    .foregroundStyle(tab == index ? BorrowUI.purple : BorrowUI.muted)

                                    .frame(maxWidth: .infinity)

                                    .padding(.vertical, 12)

                                    .background {

                                        if tab == index {

                                            RoundedRectangle(cornerRadius: 12, style: .continuous)

                                                .fill(.white)

                                                .shadow(color: BorrowUI.navy.opacity(0.07), radius: 5, y: 2)

                                        }

                                    }

                            }.buttonStyle(.plain)

                        }

                    }

                    .padding(5)

                    .background(Color(red: 0.92, green: 0.92, blue: 0.96),

                                in: RoundedRectangle(cornerRadius: 17, style: .continuous))



                    HStack(alignment: .firstTextBaseline) {

                        VStack(alignment: .leading, spacing: 5) {

                            Text(tabs[tab]).font(.system(size: 20, weight: .bold, design: .rounded))

                                .foregroundStyle(BorrowUI.navy)

                            Text(subtitle).font(.system(size: 13)).foregroundStyle(BorrowUI.muted)

                        }

                        Spacer(minLength: 8)

                        Text("\(visible.count)")

                            .font(.system(size: 13, weight: .bold, design: .rounded))

                            .foregroundStyle(BorrowUI.purple)

                            .padding(.horizontal, 12).padding(.vertical, 7)

                            .background(BorrowUI.purple.opacity(0.10), in: Capsule())

                    }



                    if let error = store.borrowRequestsError {

                        Label(error, systemImage: "wifi.exclamationmark")

                            .font(.footnote).foregroundStyle(Color(red: 0.70, green: 0.22, blue: 0.24))

                            .padding(14).frame(maxWidth: .infinity, alignment: .leading)

                            .background(Color.red.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))

                    }



                    if visible.isEmpty {

                        BorrowSurface {

                            VStack(spacing: 13) {

                                Image(systemName: tab == 2 ? "clock.arrow.circlepath" : "shippingbox")

                                    .font(.system(size: 30, weight: .medium))

                                    .foregroundStyle(BorrowUI.purple)

                                    .frame(width: 74, height: 74)

                                    .background(BorrowUI.purple.opacity(0.09), in: RoundedRectangle(cornerRadius: 23))

                                Text(tab == 2 ? "No history yet" : "Nothing here yet")

                                    .font(.system(size: 19, weight: .bold, design: .rounded))

                                    .foregroundStyle(BorrowUI.navy)

                                Text(tab == 0 ? "When you request an item, you'll be able to follow its progress here." :

                                     tab == 1 ? "Requests from neighbours will appear here when they ask to borrow your items." :

                                     "Completed, declined and cancelled requests will appear here.")

                                    .font(.subheadline).foregroundStyle(BorrowUI.muted)

                                    .multilineTextAlignment(.center)

                                    .fixedSize(horizontal: false, vertical: true)

                            }

                            .frame(maxWidth: .infinity)

                            .padding(.vertical, 36)

                            .padding(.horizontal, 8)

                        }

                    } else {

                        LazyVStack(spacing: 13) {

                            ForEach(visible) { request in

                                Button { selected = request } label: {

                                    BorrowSurface {

                                        VStack(alignment: .leading, spacing: 16) {

                                            HStack(alignment: .top, spacing: 12) {

                                                Image(systemName: "shippingbox.fill")

                                                    .font(.system(size: 20))

                                                    .foregroundStyle(BorrowUI.purple)

                                                    .frame(width: 49, height: 49)

                                                    .background(BorrowUI.purple.opacity(0.09),

                                                                in: RoundedRectangle(cornerRadius: 15))

                                                VStack(alignment: .leading, spacing: 6) {

                                                    Text(request.itemName)

                                                        .font(.system(size: 17, weight: .bold, design: .rounded))

                                                        .foregroundStyle(BorrowUI.navy)

                                                        .lineLimit(2)

                                                    Text("Requested by \(request.requesterName)")

                                                        .font(.system(size: 12))

                                                        .foregroundStyle(BorrowUI.muted)

                                                }

                                                Spacer(minLength: 0)

                                                BorrowStatusPill(status: request.status)

                                            }

                                            Rectangle().fill(BorrowUI.navy.opacity(0.07)).frame(height: 1)

                                            HStack(spacing: 8) {

                                                Image(systemName: "calendar").foregroundStyle(BorrowUI.purple)

                                                Text("\(request.startDate.formatted(date: .abbreviated, time: .omitted)) – \(request.endDate.formatted(date: .abbreviated, time: .omitted))")

                                                    .foregroundStyle(BorrowUI.muted)

                                                Spacer(minLength: 2)

                                                Image(systemName: "chevron.right")

                                                    .font(.system(size: 11, weight: .bold))

                                                    .foregroundStyle(BorrowUI.purple)

                                            }.font(.system(size: 12, weight: .medium))

                                        }

                                    }

                                }.buttonStyle(.plain)

                            }

                        }

                    }

                }

                .padding(.horizontal, 20).padding(.bottom, 32)

            }

            .background(BorrowUI.bg.ignoresSafeArea())

            .toolbar {

                ToolbarItem(placement: .topBarTrailing) {

                    Button { dismiss() } label: {

                        Image(systemName: "xmark").font(.system(size: 12, weight: .bold))

                            .foregroundStyle(BorrowUI.navy)

                            .frame(width: 32, height: 32)

                            .background(.white, in: Circle())

                    }

                }

            }

            .toolbarColorScheme(.light, for: .navigationBar)

            .sheet(item: $selected) { BorrowRequestDetailView(requestID: $0.id) }

            .onAppear { store.startBorrowRequestsListener() }

        }

        .tint(BorrowUI.purple)

        .environment(\.colorScheme, .light)

        .preferredColorScheme(.light)

    }

}



struct BorrowRequestDetailView: View {

    @EnvironmentObject private var store: AppStore

    @Environment(\.dismiss) private var dismiss

    let requestID: String

    @State private var busy = false

    @State private var errorText: String?
    @State private var showReturnChoice = false

    private var request: BorrowRequest? { store.borrowRequests.first { $0.id == requestID } }

    private var uid: String { Auth.auth().currentUser?.uid ?? "" }

    private let steps = ["Pending", "Approved", "Collected", "Returned"]



    private func stepIndex(_ status: BorrowRequest.Status) -> Int {

        switch status {

        case .pending: return 0

        case .approved: return 1

        case .collected: return 2

        case .returned: return 3

        default: return -1

        }

    }



    var body: some View {

        NavigationStack {

            ScrollView {

                if let request {

                    detailContent(request)

                } else {

                    VStack(spacing: 12) {

                        Image(systemName: "tray").font(.largeTitle).foregroundStyle(BorrowUI.purple)

                        Text("Request no longer available")

                            .font(.headline).foregroundStyle(BorrowUI.navy)

                    }.frame(maxWidth: .infinity).padding(.top, 100)

                }

            }

            .background(BorrowUI.bg.ignoresSafeArea())

            .navigationTitle("Request details")

            .navigationBarTitleDisplayMode(.inline)

            .toolbar {

                ToolbarItem(placement: .principal) {

                    Text("Request details")

                        .font(.system(size: 16, weight: .bold, design: .rounded))

                        .foregroundStyle(BorrowUI.navy)

                }

                ToolbarItem(placement: .topBarTrailing) {

                    Button { dismiss() } label: {

                        Image(systemName: "xmark")

                            .font(.system(size: 12, weight: .bold))

                            .foregroundStyle(BorrowUI.navy)

                            .frame(width: 32, height: 32)

                            .background(.white, in: Circle())

                    }

                }

            }

            .toolbarColorScheme(.light, for: .navigationBar)

            .confirmationDialog("After confirming the return, keep this listing available?",
                isPresented: $showReturnChoice, titleVisibility: .visible) {
                Button("Keep Listing") { completeReturn(keepPublished: true) }
                Button("Unpublish Listing") { completeReturn(keepPublished: false) }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Unpublishing hides the listing from neighbours without deleting the item or borrowing history.")
            }
            .alert("Action failed", isPresented: Binding(get: { errorText != nil },

                set: { if !$0 { errorText = nil } })) {

                Button("OK", role: .cancel) { errorText = nil }

            } message: { Text(errorText ?? "") }

        }

        .tint(BorrowUI.purple)

        .environment(\.colorScheme, .light)

        .preferredColorScheme(.light)

    }



    private func detailContent(_ request: BorrowRequest) -> some View {

        VStack(alignment: .leading, spacing: 20) {

                        VStack(alignment: .leading, spacing: 15) {

                            HStack {

                                Label(request.isNeededOffer ? "OFFER TO LEND" : "BORROWING REQUEST", systemImage: "shippingbox.fill")

                                    .font(.system(size: 11, weight: .bold, design: .rounded))

                                    .tracking(1.0)

                                    .foregroundStyle(BorrowUI.purple)

                                Spacer()

                                BorrowStatusPill(status: request.status)

                            }

                            Text(request.itemName)

                                .font(.system(size: 31, weight: .bold, design: .rounded))

                                .foregroundStyle(BorrowUI.navy)

                            HStack(spacing: 9) {

                                Image(systemName: "person.crop.circle.fill")

                                    .font(.system(size: 21)).foregroundStyle(BorrowUI.purple)

                                VStack(alignment: .leading, spacing: 2) {

                                    Text(request.isNeededOffer ? "OFFERED BY" : "REQUESTED BY").font(.system(size: 10, weight: .bold))

                                        .tracking(1.0).foregroundStyle(BorrowUI.muted)

                                    Text(request.requesterName).font(.system(size: 14, weight: .semibold))

                                        .foregroundStyle(BorrowUI.navy)

                                }

                            }

                        }

                        .padding(22).frame(maxWidth: .infinity, alignment: .leading)

                        .background(

                            LinearGradient(colors: [.white, BorrowUI.purple.opacity(0.055)],

                                           startPoint: .topLeading, endPoint: .bottomTrailing),

                            in: RoundedRectangle(cornerRadius: 25, style: .continuous))

                        .overlay(RoundedRectangle(cornerRadius: 25).stroke(BorrowUI.purple.opacity(0.10)))



                        HStack(spacing: 12) {

                            dateCard("COLLECTION", date: request.startDate, icon: "calendar.badge.clock")

                            dateCard("RETURN BY", date: request.endDate, icon: "arrow.uturn.backward.circle")

                        }



                        BorrowSurface {

                            VStack(alignment: .leading, spacing: 18) {

                                HStack {

                                    Text("Request progress")

                                        .font(.system(size: 19, weight: .bold, design: .rounded))

                                        .foregroundStyle(BorrowUI.navy)

                                    Spacer()

                                    Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")

                                        .foregroundStyle(BorrowUI.purple)

                                }

                                if stepIndex(request.status) < 0 {

                                    Label("This request was \(request.status.label.lowercased()).",

                                          systemImage: "info.circle")

                                        .font(.subheadline).foregroundStyle(BorrowUI.muted)

                                }

                                ForEach(steps.indices, id: \.self) { index in

                                    let completed = stepIndex(request.status) >= index

                                    HStack(alignment: .top, spacing: 13) {

                                        VStack(spacing: 0) {

                                            Image(systemName: completed ? "checkmark.circle.fill" : "circle")

                                                .font(.system(size: 25, weight: .medium))

                                                .foregroundStyle(completed ? BorrowUI.purple : BorrowUI.muted.opacity(0.5))

                                            if index < steps.count - 1 {

                                                Rectangle()

                                                    .fill(completed && stepIndex(request.status) > index ? BorrowUI.purple.opacity(0.5) : BorrowUI.navy.opacity(0.10))

                                                    .frame(width: 2, height: 24)

                                                    .padding(.vertical, 4)

                                            }

                                        }

                                        VStack(alignment: .leading, spacing: 4) {

                                            Text(steps[index])

                                                .font(.system(size: 15, weight: completed ? .semibold : .medium))

                                                .foregroundStyle(completed ? BorrowUI.navy : BorrowUI.muted)

                                            if index == stepIndex(request.status) {

                                                Text("Current status")

                                                    .font(.system(size: 11, weight: .medium))

                                                    .foregroundStyle(BorrowUI.purple)

                                            }

                                        }.padding(.top, 3)

                                        Spacer()

                                    }

                                }

                            }

                        }



                        if !request.note.isEmpty {

                            BorrowSurface {

                                VStack(alignment: .leading, spacing: 10) {

                                    Label("Collection note", systemImage: "text.bubble")

                                        .font(.system(size: 16, weight: .bold))

                                        .foregroundStyle(BorrowUI.navy)

                                    Text(request.note).font(.subheadline).foregroundStyle(BorrowUI.muted)

                                }

                            }

                        }



                        if request.isNeededOffer && request.ownerUID == uid && request.status == .returned {
                            Button("Unpublish Needed Listing") {
                                busy = true
                                Task { @MainActor in
                                    defer { busy = false }
                                    do { try await store.setSharedItemPublished(itemId: request.itemId, published: false) }
                                    catch { errorText = error.localizedDescription }
                                }
                            }
                            .buttonStyle(.bordered)
                            .disabled(busy)
                        }

                        if request.ownerUID == uid || request.borrowerUID == uid {

                            VStack(spacing: 10) {

                                if request.ownerUID == uid {

                                    if request.status == .pending {

                                        action(request.isNeededOffer ? "Accept offer" : "Approve request", request, .approved, icon: "checkmark", primary: true)

                                        action(request.isNeededOffer ? "Decline offer" : "Decline request", request, .declined, icon: "xmark", primary: false)

                                    } else if request.status == .approved {

                                        action("Confirm collection", request, .collected, icon: "shippingbox", primary: true)

                                    } else if request.status == .collected && !request.isNeededOffer {

                                        Button { showReturnChoice = true } label: {
                                            Label("Confirm return", systemImage: "checkmark.circle")
                                                .frame(maxWidth: .infinity, minHeight: 54)
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .disabled(busy)

                                    }

                                }

                                if request.isNeededOffer && request.borrowerUID == uid && request.status == .collected {
                                    action("Confirm item returned", request, .returned, icon: "checkmark.circle", primary: true)
                                }
                                if request.borrowerUID == uid && (request.status == .pending || request.status == .approved) {

                                    action("Cancel request", request, .cancelled, icon: "xmark.circle", primary: false)

                                }

                            }

                        }

        }

        .padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 36)

    }



    private func dateCard(_ title: String, date: Date, icon: String) -> some View {

        VStack(alignment: .leading, spacing: 10) {

            Image(systemName: icon).font(.system(size: 18)).foregroundStyle(BorrowUI.purple)

            Text(title).font(.system(size: 10, weight: .bold)).tracking(1.1)

                .foregroundStyle(BorrowUI.muted)

            Text(date.formatted(date: .abbreviated, time: .omitted))

                .font(.system(size: 14, weight: .semibold, design: .rounded))

                .foregroundStyle(BorrowUI.navy)

                .minimumScaleFactor(0.8).lineLimit(1)

        }

        .frame(maxWidth: .infinity, alignment: .leading)

        .padding(17)

        .background(.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

        .overlay(RoundedRectangle(cornerRadius: 20).stroke(BorrowUI.navy.opacity(0.055)))

    }



    private func completeReturn(keepPublished: Bool) {
        guard !busy, let request, request.status == .collected,
              request.ownerUID == uid else { return }
        busy = true
        Task { @MainActor in
            defer { busy = false }
            do {
                try await store.advanceBorrowRequest(request, to: .returned, keepPublished: keepPublished)
            } catch {
                errorText = error.localizedDescription
            }
        }
    }

    private func action(_ title: String, _ request: BorrowRequest, _ status: BorrowRequest.Status,

                        icon: String, primary: Bool) -> some View {

        Button {

            guard !busy else { return }

            busy = true

            Task { @MainActor in

                defer { busy = false }

                do { try await store.advanceBorrowRequest(request, to: status) }

                catch { errorText = error.localizedDescription }

            }

        } label: {

            HStack(spacing: 10) {

                if busy && primary { ProgressView().tint(.white) }

                else { Image(systemName: icon) }

                Text(title)

                Spacer()

                Image(systemName: "arrow.right").font(.system(size: 12, weight: .bold))

            }

            .font(.system(size: 15, weight: .semibold))

            .foregroundStyle(primary ? Color.white : BorrowUI.navy)

            .padding(.horizontal, 20).frame(height: 54)

            .background(primary ? BorrowUI.purple : Color.white,

                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            .overlay(RoundedRectangle(cornerRadius: 16)

                .stroke(primary ? Color.clear : BorrowUI.navy.opacity(0.10)))

        }

        .buttonStyle(.plain).disabled(busy)

    }

}
