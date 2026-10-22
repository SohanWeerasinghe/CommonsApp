//
//  NewItemView.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 26/9/2026.
//
import SwiftUI
import PhotosUI
import UIKit
struct NewItemView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var detail = ""
    @State private var status: SharedItem.Status = .lending
    @State private var availability = "Available now"
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var photoPreview: UIImage?
    @State private var isLoadingPhoto = false
    let availabilityOptions = ["Available now", "Weekends only"]
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Theme.wallBackgroundTop, Theme.wallBackgroundBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Lending / Needed selection
                        HStack(spacing: 12) {
                            TypeButton(
                                icon: "arrow.up",
                                title: "I'm Lending",
                                isSelected: status == .lending
                            ) {
                                status = .lending
                            }
                            TypeButton(
                                icon: "arrow.down",
                                title: "I Need",
                                isSelected: status == .needed
                            ) {
                                status = .needed
                            }
                        }
                        // Item name
                        VStack(alignment: .leading, spacing: 8) {
                            FieldLabel(text: "ITEM NAME")
                            TextField("e.g. Power Drill", text: $name)
                                .font(Theme.ui(15))
                                .foregroundStyle(Theme.appNavy)
                                .padding(.horizontal, 16)
                                .frame(height: 52)
                                .background(Theme.card)
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Theme.appBorder, lineWidth: 1)
                                }
                        }
                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            FieldLabel(text: "DESCRIPTION")
                            TextField("Cordless, with bits, brand new", text: $detail, axis: .vertical)
                                .font(Theme.ui(15))
                                .foregroundStyle(Theme.appNavy)
                                .lineLimit(3...5)
                                .padding(16)
                                .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
                                .background(Theme.card)
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Theme.appBorder, lineWidth: 1)
                                }
                        }
                        // Availability
                        VStack(alignment: .leading, spacing: 10) {
                            FieldLabel(text: "AVAILABILITY")
                            HStack(spacing: 10) {
                                ForEach(availabilityOptions, id: \.self) { option in
                                    Button {
                                        availability = option
                                    } label: {
                                        Text(option)
                                            .font(Theme.ui(12, weight: .semibold))
                                            .foregroundStyle(
                                                availability == option ? Theme.card : Theme.appMuted
                                            )
                                            .padding(.horizontal, 16)
                                            .frame(height: 36)
                                            .background(
                                                availability == option ? Theme.appPurple : Theme.card
                                            )
                                            .clipShape(Capsule())
                                            .overlay {
                                                if availability != option {
                                                    Capsule()
                                                        .stroke(Theme.appBorder, lineWidth: 1)
                                                }
                                            }
                                    }
                                    .buttonStyle(.plain)
                                }
                                Spacer()
                            }
                        }
                        // Optional listing photo
                        VStack(alignment: .leading, spacing: 8) {
                            FieldLabel(text: "PHOTO")
                            if let photoPreview {
                                Image(uiImage: photoPreview)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity)
                                    .frame(maxHeight: 230)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                HStack(spacing: 12) {
                                    Image(systemName: "photo.badge.plus")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(Theme.appPurple)
                                    Text(photoData == nil ? "Add a photo (optional)" : "Replace photo")
                                        .font(Theme.ui(14, weight: .semibold))
                                        .foregroundStyle(Theme.appNavy)
                                    Spacer()
                                    if isLoadingPhoto { ProgressView() }
                                }
                                .padding(16)
                                .background(Theme.card)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.appBorder, lineWidth: 1))
                            }
                            .disabled(isSaving || isLoadingPhoto)
                            if photoData != nil {
                                Button("Remove photo", role: .destructive) {
                                    selectedPhoto = nil
                                    photoData = nil
                                    photoPreview = nil
                                }
                                .font(Theme.ui(13, weight: .semibold))
                                .disabled(isSaving)
                            }
                        }
                        // Post button
                        Button {
                            addItem()
                        } label: {
                            Text("Post to Building")
                                .font(Theme.ui(15, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(name.isEmpty ? Theme.appMuted : Theme.appPurple)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving || isLoadingPhoto)
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
            }
            .alert("Unable to publish item", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } })) {
                Button("OK", role: .cancel) { saveError = nil }
            } message: { Text(saveError ?? "") }
            .onChange(of: selectedPhoto) { _, item in
                Task { await loadSelectedPhoto(item) }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(Theme.ui(14, weight: .semibold))
                    .foregroundStyle(Theme.appNavy)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        addItem()
                    }
                    .font(Theme.ui(14, weight: .bold))
                    .foregroundStyle(name.isEmpty ? Theme.appMuted : Theme.appPurple)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving || isLoadingPhoto)
                }
            }
        }
    }
    @MainActor
    private func loadSelectedPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        isLoadingPhoto = true
        defer { isLoadingPhoto = false }
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                throw NSError(domain: "CommonsApp.Items", code: 400,
                              userInfo: [NSLocalizedDescriptionKey: "Unable to read the selected photo."])
            }
            let scale = min(1, 900 / max(image.size.width, image.size.height))
            let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            let renderer = UIGraphicsImageRenderer(size: size)
            let resized = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: size))
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
                throw NSError(domain: "CommonsApp.Items", code: 413,
                              userInfo: [NSLocalizedDescriptionKey: "Photo is too large. Choose a smaller image."])
            }
            photoData = compressed
            photoPreview = UIImage(data: compressed)
        } catch {
            photoData = nil
            photoPreview = nil
            saveError = error.localizedDescription
        }
    }
    func addItem() {
        guard !isSaving else { return }
        isSaving = true
        Task { @MainActor in
            defer { isSaving = false }
            do {
                try await store.publishSharedItem(name: name, detail: detail,
                                                   status: status, availability: availability, photoData: photoData)
                dismiss()
            } catch {
                saveError = error.localizedDescription
            }
        }
    }
}
private struct TypeButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .semibold))
                Text(title)
                    .font(Theme.ui(13, weight: .bold))
            }
            .foregroundStyle(isSelected ? Theme.card : Theme.appNavy)
            .frame(maxWidth: .infinity)
            .frame(height: 86)
            .background(isSelected ? Theme.appPurple : Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay {
                if !isSelected {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Theme.appBorder, lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
private struct FieldLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(Theme.ui(10, weight: .bold))
            .foregroundStyle(Theme.appMuted)
    }
}
#Preview {
    NewItemView()
        .environmentObject(AppStore())
}
