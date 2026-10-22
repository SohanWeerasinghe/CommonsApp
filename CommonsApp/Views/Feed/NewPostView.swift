import SwiftUI
import PhotosUI
import UIKit
private enum PostComposerStyle {
    static let navy = Color(red: 0.11, green: 0.16, blue: 0.27)
    static let purple = Color(red: 0.46, green: 0.41, blue: 0.93)
    static let muted = Color(red: 0.46, green: 0.50, blue: 0.59)
    static let background = Color(red: 0.97, green: 0.97, blue: 0.99)
    static let border = Color(red: 0.89, green: 0.90, blue: 0.94)
}
struct NewPostView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var category: Post.Category = .news
    @State private var showAuthorName = true
    @State private var showAuthorUnit = false
    @State private var isSaving = false
    @State private var postError = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var photoPreview: UIImage?
    @State private var isLoadingPhoto = false
    private var canPublish: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        text.count <= 2000 && category != .announcement && !isSaving && !isLoadingPhoto
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    introduction
                    categorySection
                    composerSection
                    privacySection
                    photoInformation
                }
                .padding(.horizontal, 22)
                .padding(.top, 22)
                .padding(.bottom, 32)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(PostComposerStyle.background.ignoresSafeArea())
            .safeAreaInset(edge: .bottom, spacing: 0) {
                publishFooter
            }
            .navigationTitle("Create post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(PostComposerStyle.navy)
                }
            }
            .tint(PostComposerStyle.purple)
            .onChange(of: selectedPhoto) { _, item in
                Task { await loadSelectedPhoto(item) }
            }
            .preferredColorScheme(.light)
            .alert("Unable to Publish Post", isPresented: Binding(
                get: { !postError.isEmpty },
                set: { if !$0 { postError = "" } }
            )) {
                Button("OK", role: .cancel) { postError = "" }
            } message: {
                Text(postError)
            }
        }
    }
    private var introduction: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 23, weight: .semibold))
                .foregroundStyle(PostComposerStyle.purple)
                .frame(width: 54, height: 54)
                .background(PostComposerStyle.purple.opacity(0.11), in: RoundedRectangle(cornerRadius: 17))
            VStack(alignment: .leading, spacing: 5) {
                Text("Share with your neighbours")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(PostComposerStyle.navy)
                Text("An update, a question, or something worth sharing with your community.")
                    .font(.system(size: 13))
                    .foregroundStyle(PostComposerStyle.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading("POST CATEGORY", subtitle: "Choose the best fit for your update")
            HStack(spacing: 8) {
                ForEach(Post.Category.allCases, id: \.self) { option in
                    Button { category = option } label: {
                        Text(option.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .foregroundStyle(category == option ? .white : PostComposerStyle.navy)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(category == option ? PostComposerStyle.purple : .white,
                                        in: RoundedRectangle(cornerRadius: 14))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(category == option ? .clear : PostComposerStyle.border, lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            if category == .announcement {
                Label("Announcements are reserved for authorised publishing.", systemImage: "lock.shield")
                    .font(.system(size: 12))
                    .foregroundStyle(PostComposerStyle.muted)
            }
        }
    }
    private var composerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading("YOUR MESSAGE", subtitle: "What would you like to share?")
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topLeading) {
                    if text.isEmpty {
                        Text("Write something for your neighbours…")
                            .font(.system(size: 15))
                            .foregroundStyle(PostComposerStyle.muted.opacity(0.8))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 9)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $text)
                        .font(.system(size: 15))
                        .foregroundStyle(PostComposerStyle.navy)
                        .scrollContentBackground(.hidden)
                        .frame(height: 175)
                }
                HStack {
                    Text("Be kind and keep it relevant to your community.")
                        .font(.system(size: 11))
                        .foregroundStyle(PostComposerStyle.muted)
                    Spacer(minLength: 8)
                    Text("\(text.count)/2000")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(text.count > 2000 ? .red : PostComposerStyle.muted)
                }
            }
            .padding(16)
            .background(.white, in: RoundedRectangle(cornerRadius: 20))
            .overlay { RoundedRectangle(cornerRadius: 20).stroke(PostComposerStyle.border, lineWidth: 1) }
        }
    }
    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading("PRIVACY", subtitle: "Control what neighbours see")
            VStack(spacing: 0) {
                privacyRow(icon: "person.crop.circle", title: "Show my name",
                           subtitle: "Display your name alongside this post", isOn: $showAuthorName)
                Divider().padding(.leading, 54)
                privacyRow(icon: "house", title: "Show my apartment/unit",
                           subtitle: "Only available if enabled in your profile", isOn: $showAuthorUnit,
                           enabled: showAuthorName && store.currentResident.showUnitToNeighbors)
            }
            .padding(.horizontal, 16)
            .background(.white, in: RoundedRectangle(cornerRadius: 20))
            .overlay { RoundedRectangle(cornerRadius: 20).stroke(PostComposerStyle.border, lineWidth: 1) }
            if !showAuthorName {
                Label("Your post will appear as Anonymous User.", systemImage: "eye.slash")
                    .font(.system(size: 12))
                    .foregroundStyle(PostComposerStyle.muted)
            }
        }
    }
    private var photoInformation: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PHOTO ATTACHMENT")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(PostComposerStyle.navy)
            if let photoPreview {
                Image(uiImage: photoPreview)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            HStack(spacing: 12) {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label(photoData == nil ? "Choose photo" : "Replace photo",
                          systemImage: "photo.on.rectangle.angled")
                        .font(.system(size: 14, weight: .semibold))
                }
                .disabled(isSaving)
                if photoData != nil {
                    Button("Remove") {
                        selectedPhoto = nil
                        photoData = nil
                        photoPreview = nil
                    }
                    .disabled(isSaving)
                }
                if isLoadingPhoto { ProgressView() }
            }
            Text("One compressed JPEG photo per post.")
                .font(.system(size: 12))
                .foregroundStyle(PostComposerStyle.muted)
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).stroke(PostComposerStyle.border, lineWidth: 1) }
    }
    @MainActor
    private func loadSelectedPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        isLoadingPhoto = true
        postError = ""
        defer { isLoadingPhoto = false }
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                throw NSError(domain: "CommonsApp", code: 400,
                              userInfo: [NSLocalizedDescriptionKey: "Unable to read the selected photo."])
            }
            // Keep Base64 small enough for one Firestore document.
            let maxDimension: CGFloat = 900
            let scale = min(1, maxDimension / max(image.size.width, image.size.height))
            let targetSize = CGSize(width: image.size.width * scale,
                                    height: image.size.height * scale)
            let renderer = UIGraphicsImageRenderer(size: targetSize)
            let resized = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: targetSize))
            }
            var compressed: Data?
            for quality in [0.70, 0.55, 0.40, 0.28, 0.18] {
                if let candidate = resized.jpegData(compressionQuality: quality),
                   candidate.base64EncodedString().count <= 500_000 {
                    compressed = candidate
                    break
                }
            }
            guard let compressed else {
                throw NSError(domain: "CommonsApp", code: 413,
                              userInfo: [NSLocalizedDescriptionKey: "Photo is too large. Choose a smaller image."])
            }
            photoData = compressed
            photoPreview = UIImage(data: compressed)
        } catch {
            photoData = nil
            photoPreview = nil
            postError = error.localizedDescription
        }
    }
    private var publishFooter: some View {
        Button(action: publish) {
            HStack(spacing: 9) {
                if isSaving { ProgressView().tint(.white) }
                else { Image(systemName: "paperplane.fill") }
                Text(isSaving ? "Publishing…" : "Publish post")
            }
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(canPublish ? PostComposerStyle.purple : PostComposerStyle.muted.opacity(0.45),
                        in: RoundedRectangle(cornerRadius: 18))
        }
        .disabled(!canPublish)
        .padding(.horizontal, 22)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(.regularMaterial)
    }
    private func sectionHeading(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(PostComposerStyle.purple)
            Text(subtitle)
                .font(.system(size: 13))
                .foregroundStyle(PostComposerStyle.muted)
        }
    }
    private func privacyRow(icon: String, title: String, subtitle: String,
                            isOn: Binding<Bool>, enabled: Bool = true) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(PostComposerStyle.purple)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(PostComposerStyle.navy)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(PostComposerStyle.muted)
                }
            }
        }
        .tint(PostComposerStyle.purple)
        .disabled(!enabled)
        .padding(.vertical, 15)
    }
    private func publish() {
        guard canPublish else { return }
        isSaving = true
        postError = ""
        Task {
            do {
                try await store.saveResidentPostToFirestore(
                    text: text,
                    category: category,
                    showAuthorName: showAuthorName,
                    showAuthorUnit: showAuthorName && showAuthorUnit && store.currentResident.showUnitToNeighbors,
                    photoData: photoData
                )
                isSaving = false
                dismiss()
            } catch {
                postError = error.localizedDescription
                isSaving = false
            }
        }
    }
}
#Preview {
    NewPostView().environmentObject(AppStore())
}
