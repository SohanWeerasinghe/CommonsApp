//
//  EditProfileView.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 22/10/2026.
//

import SwiftUI
import PhotosUI
import FirebaseAuth

struct EditProfileView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var phone = ""
    @State private var showUnit = true
    @State private var isSaving = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profilePhoto: UIImage?
    @State private var pendingPhoto: UIImage?
    @State private var removePhoto = false
    @State private var isLoadingPhoto = false

    private let purple = Color(red: 0.43, green: 0.36, blue: 0.91)
    private let background = Color(red: 0.965, green: 0.963, blue: 0.985)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("YOUR PROFILE")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(purple)
                    Text("Personal details")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text("Keep your resident information up to date.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 12) {
                    Group {
                        if let image = removePhoto ? nil : (pendingPhoto ?? profilePhoto) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(purple.opacity(0.65))
                                .padding(14)
                        }
                    }
                    .frame(width: 112, height: 112)
                    .background(background)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(purple.opacity(0.15), lineWidth: 2))

                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("Choose profile picture", systemImage: "camera")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(purple)
                    }
                    .disabled(isSaving)

                    if (profilePhoto != nil || pendingPhoto != nil) && !removePhoto {
                        Button("Remove picture", role: .destructive) {
                            pendingPhoto = nil
                            selectedPhoto = nil
                            removePhoto = true
                        }
                        .font(.subheadline)
                        .disabled(isSaving)
                    }
                    Text("One photo, up to 256 × 256 pixels and 40 KB after compression.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    if isLoadingPhoto { ProgressView() }
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(.white, in: RoundedRectangle(cornerRadius: 22))

                VStack(alignment: .leading, spacing: 17) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("Full name").font(.subheadline.weight(.semibold))
                        TextField("Full name", text: $name)
                            .textContentType(.name)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .padding(13)
                            .background(background, in: RoundedRectangle(cornerRadius: 12))
                    }
                    VStack(alignment: .leading, spacing: 7) {
                        Text("Phone number").font(.subheadline.weight(.semibold))
                        TextField("Phone number", text: $phone)
                            .textContentType(.telephoneNumber)
                            .keyboardType(.phonePad)
                            .padding(13)
                            .background(background, in: RoundedRectangle(cornerRadius: 12))
                    }
                    VStack(alignment: .leading, spacing: 7) {
                        Text("Email address").font(.subheadline.weight(.semibold))
                        Text(Auth.auth().currentUser?.email ?? store.pendingEmail)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(13)
                            .background(background, in: RoundedRectangle(cornerRadius: 12))
                        Text("Your sign-in email cannot be changed here.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 7) {
                        Text("Apartment / Unit").font(.subheadline.weight(.semibold))
                        Text(store.currentResident.unit)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(13)
                            .background(background, in: RoundedRectangle(cornerRadius: 12))
                        Text("Your unit is managed by building administration.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding(18)
                .background(.white, in: RoundedRectangle(cornerRadius: 22))

                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Show unit to neighbours", isOn: $showUnit)
                        .font(.subheadline.weight(.semibold))
                        .tint(purple)
                    Text("Choose whether your apartment number is shown to other residents where supported.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(18)
                .background(.white, in: RoundedRectangle(cornerRadius: 22))

                Button {
                    Task { await save() }
                } label: {
                    HStack {
                        if isSaving { ProgressView().tint(.white) }
                        Text(isSaving ? "Saving..." : "Save Changes")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(purple, in: RoundedRectangle(cornerRadius: 16))
                }
                .disabled(isSaving || isLoadingPhoto || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(20)
        }
        .background(background.ignoresSafeArea())
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
                    .disabled(isSaving)
            }
        }
        .onAppear {
            name = store.currentResident.name
            phone = store.currentResident.phone
            showUnit = store.currentResident.showUnitToNeighbors
        }
        .task {
            isLoadingPhoto = true
            defer { isLoadingPhoto = false }
            do { profilePhoto = try await ProfilePhotoStore.load() }
            catch { show(error) }
        }
        .onChange(of: selectedPhoto) { _, photo in
            guard let photo else { return }
            Task {
                do {
                    guard let data = try await photo.loadTransferable(type: Data.self),
                          let image = UIImage(data: data) else {
                        throw NSError(domain: "CommonsApp.ProfilePhoto", code: 400,
                                      userInfo: [NSLocalizedDescriptionKey: "Unable to read selected image."])
                    }
                    _ = try ProfilePhotoStore.prepare(image)
                    pendingPhoto = image
                    removePhoto = false
                } catch { show(error) }
            }
        }
        .alert("Unable to Save", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    @MainActor
    private func save() async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            // Save the photo first. The existing profile update remains unchanged.
            if removePhoto {
                try await ProfilePhotoStore.remove()
            } else if let pendingPhoto {
                try await ProfilePhotoStore.save(pendingPhoto)
            }
            try await store.updateResidentPersonalDetails(name: name, phone: phone, showUnit: showUnit)
            dismiss()
        } catch { show(error) }
    }

    @MainActor
    private func show(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }
}
