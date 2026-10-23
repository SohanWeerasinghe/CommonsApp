
import SwiftUI
import PhotosUI
import UIKit

struct NewMaintenanceRequestView: View {

    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var details = ""

    // MARK: - Photo Selection

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isSubmitting = false
    @State private var submissionError: String?

    // MARK: - AI Detection

    @State private var detections: [MaintenanceDetection] = []
    @State private var isAnalysing = false
    @State private var detectionError: String?

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
                    VStack(alignment: .leading, spacing: 20) {

                        // MARK: - Introduction

                        VStack(alignment: .leading, spacing: 6) {
                            Text("REPORT AN ISSUE")
                                .font(Theme.ui(10, weight: .bold))
                                .foregroundStyle(Theme.appMuted)
                                .tracking(1.2)

                            Text("What needs fixing?")
                                .font(Theme.display(25, weight: .bold))
                                .foregroundStyle(Theme.appNavy)

                            Text("Add a photo for on-device AI analysis. Only your reviewed request details are saved; the photo is not uploaded or shared with management.")
                                .font(Theme.ui(13))
                                .foregroundStyle(Theme.appMuted)
                                .lineSpacing(3)
                        }


                        // MARK: - Photo

                        VStack(alignment: .leading, spacing: 10) {
                            Text("ADD A PHOTO")
                                .font(Theme.ui(11, weight: .bold))
                                .foregroundStyle(Theme.appMuted)
                                .tracking(0.8)

                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                if selectedImage == nil {
                                    VStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(Theme.appPurpleSoft)
                                                .frame(width: 54, height: 54)

                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 21, weight: .semibold))
                                                .foregroundStyle(Theme.appPurple)
                                        }

                                        Text("Take or choose a photo")
                                            .font(Theme.ui(14, weight: .bold))
                                            .foregroundStyle(Theme.appNavy)

                                        Text("A clear photo helps identify the problem")
                                            .font(Theme.ui(11))
                                            .foregroundStyle(Theme.appMuted)

                                        Text("Choose Photo")
                                            .font(Theme.ui(12, weight: .bold))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 18)
                                            .frame(height: 36)
                                            .background(Theme.appPurple)
                                            .clipShape(Capsule())
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 190)
                                    .background(Theme.card)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(
                                                Theme.appPurple.opacity(0.25),
                                                style: StrokeStyle(lineWidth: 1.5, dash: [7])
                                            )
                                    }
                                } else {
                                    HStack(spacing: 10) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Theme.appGreen)

                                        Text("Photo selected")
                                            .font(Theme.ui(13, weight: .semibold))
                                            .foregroundStyle(Theme.appNavy)

                                        Spacer()

                                        Text("Change")
                                            .font(Theme.ui(12, weight: .bold))
                                            .foregroundStyle(Theme.appPurple)
                                    }
                                    .padding(.horizontal, 14)
                                    .frame(height: 48)
                                    .background(Theme.card)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Theme.appBorder, lineWidth: 1)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(
                                selectedImage == nil
                                    ? "Choose a maintenance issue photo"
                                    : "Change maintenance issue photo"
                            )
                            .accessibilityHint(
                                "Opens the photo library to select an image for on-device analysis"
                            )
                            .onChange(of: selectedPhoto) { _, newPhoto in
                                Task {
                                    await loadSelectedPhoto(newPhoto)
                                }
                            }
                        }


                        // MARK: - Issue Information

                        VStack(alignment: .leading, spacing: 6) {
                            Text("ISSUE INFORMATION")
                                .font(Theme.ui(10, weight: .bold))
                                .foregroundStyle(Theme.appMuted)
                                .tracking(1.2)

                            Text("Tell us what happened")
                                .font(Theme.display(19, weight: .bold))
                                .foregroundStyle(Theme.appNavy)
                        }


                        // MARK: - Issue Title

                        VStack(alignment: .leading, spacing: 8) {
                            Text("ISSUE TITLE")
                                .font(Theme.ui(11, weight: .bold))
                                .foregroundStyle(Theme.appMuted)

                            TextField("e.g. Kitchen faucet leak", text: $title)
                                .accessibilityLabel("Issue title")
                                .accessibilityHint("Enter a short description of the maintenance problem")
                                .font(Theme.ui(14))
                                .foregroundStyle(Theme.appNavy)
                                .padding(.horizontal, 14)
                                .frame(height: 52)
                                .background(Theme.card)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Theme.appBorder, lineWidth: 1)
                                }
                        }


                        // MARK: - Issue Description

                        VStack(alignment: .leading, spacing: 8) {
                            Text("DESCRIBE THE ISSUE")
                                .font(Theme.ui(11, weight: .bold))
                                .foregroundStyle(Theme.appMuted)

                            ZStack(alignment: .topLeading) {
                                if details.isEmpty {
                                    Text("Describe what you've noticed...")
                                        .font(Theme.ui(14))
                                        .foregroundStyle(Theme.appTertiary)
                                        .padding(.horizontal, 13)
                                        .padding(.vertical, 16)
                                        .allowsHitTesting(false)
                                }

                                TextEditor(text: $details)
                                    .accessibilityLabel("Issue details")
                                    .accessibilityHint("Describe the maintenance problem in more detail")
                                    .font(Theme.ui(14))
                                    .foregroundStyle(Theme.appNavy)
                                    .scrollContentBackground(.hidden)
                                    .padding(8)
                                    .frame(height: 120)
                                    .background(Color.clear)
                            }
                            .background(Theme.card)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Theme.appBorder, lineWidth: 1)
                            }
                        }

                        // MARK: Selected Image Preview

                        if let selectedImage {
                            VStack(alignment: .leading, spacing: 12) {

                                Text("SELECTED PHOTO")
                                    .font(
                                        Theme.ui(
                                            12,
                                            weight: .semibold
                                        )
                                    )
                                    .foregroundStyle(Theme.textMuted)

                                GeometryReader { geometry in
                                    let imageSize = selectedImage.size

                                    let scale = min(
                                        geometry.size.width / imageSize.width,
                                        geometry.size.height / imageSize.height
                                    )

                                    let displayedWidth = imageSize.width * scale
                                    let displayedHeight = imageSize.height * scale

                                    let offsetX = (geometry.size.width - displayedWidth) / 2
                                    let offsetY = (geometry.size.height - displayedHeight) / 2

                                    ZStack(alignment: .topLeading) {

                                        Image(uiImage: selectedImage)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(
                                                width: geometry.size.width,
                                                height: geometry.size.height
                                            )

                                        ForEach(detections) { detection in

                                            let box = detection.boundingBox

                                            let boxWidth = box.width * displayedWidth
                                            let boxHeight = box.height * displayedHeight

                                            let x = offsetX + box.minX * displayedWidth
                                            let y = offsetY + box.minY * displayedHeight

                                            let confidence = Int(detection.confidence * 100)

                                            Rectangle()
                                                .stroke(
                                                    Theme.sage,
                                                    lineWidth: 3
                                                )
                                                .frame(
                                                    width: boxWidth,
                                                    height: boxHeight
                                                )
                                                .position(
                                                    x: x + boxWidth / 2,
                                                    y: y + boxHeight / 2
                                                )

                                            Text("\(detection.label.capitalized) \(confidence)%")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundStyle(.white)
                                                .padding(.horizontal, 7)
                                                .padding(.vertical, 5)
                                                .background(Theme.appGreen)
                                                .clipShape(RoundedRectangle(cornerRadius: 5))
                                                .position(
                                                    x: min(x + 65, geometry.size.width - 70),
                                                    y: max(y - 12, 14)
                                                )
                                        }
                                    }
                                }
                                .aspectRatio(
                                    selectedImage.size.width / selectedImage.size.height,
                                    contentMode: .fit
                                )
                                .clipShape(
                                    RoundedRectangle(cornerRadius: 12)
                                )
                            }
                        }

                        // MARK: AI Detection Status

                        if isAnalysing {
                            HStack(spacing: 12) {
                                ProgressView()

                                Text("Analysing image with YOLO11n...")
                                    .font(Theme.ui(13))
                                    .foregroundStyle(Theme.textMuted)
                            }
                            .padding(14)
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )
                            .background(Theme.card)
                            .clipShape(
                                RoundedRectangle(cornerRadius: 10)
                            )
                        }

                        // MARK: Detection Error

                        if let detectionError {
                            Text(detectionError)
                                .font(Theme.ui(12))
                                .foregroundStyle(.red)
                                .padding(12)
                                .frame(
                                    maxWidth: .infinity,
                                    alignment: .leading
                                )
                                .background(.red.opacity(0.08))
                                .clipShape(
                                    RoundedRectangle(cornerRadius: 10)
                                )
                        }

                        // MARK: AI Detection Results

                        if selectedImage != nil && !isAnalysing
                            && detectionError == nil {

                            VStack(alignment: .leading, spacing: 12) {

                                HStack {
                                    Image(systemName: "sparkles")
                                        .foregroundStyle(Theme.sage)

                                    Text("AI IMAGE ANALYSIS")
                                        .font(
                                            Theme.ui(
                                                12,
                                                weight: .semibold
                                            )
                                        )
                                        .foregroundStyle(Theme.textMuted)
                                }

                                if detections.isEmpty {
                                    Text(
                                        "No objects detected above the confidence threshold."
                                    )
                                    .font(Theme.ui(12))
                                    .foregroundStyle(Theme.textMuted)
                                } else {
                                    ForEach(detections) { detection in
                                            HStack(spacing: 10) {
                                                ZStack {
                                                    Circle()
                                                        .fill(Theme.appGreenSoft)
                                                        .frame(width: 30, height: 30)

                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 11, weight: .bold))
                                                        .foregroundStyle(Theme.appGreen)
                                                }

                                                Text(detection.label.capitalized)
                                                    .font(Theme.ui(13, weight: .semibold))
                                                    .foregroundStyle(Theme.appNavy)

                                                Spacer()

                                                Text("\(Int(detection.confidence * 100))%")
                                                    .font(Theme.ui(12, weight: .bold))
                                                    .foregroundStyle(Theme.appGreen)
                                                    .padding(.horizontal, 9)
                                                    .padding(.vertical, 5)
                                                    .background(Theme.appGreenSoft)
                                                    .clipShape(Capsule())
                                            }
                                    }
                                }

                                Text(
                                    "Experimental object recognition. Verify all results manually."
                                )
                                .font(Theme.ui(11))
                                .foregroundStyle(Theme.textMuted)
                            }
                            .padding(14)
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )
                            .background(Theme.card)
                            .clipShape(
                                RoundedRectangle(cornerRadius: 10)
                            )
                        }

                        // MARK: Existing Information Box

                        HStack(spacing: 10) {
                            Image(systemName: "info.circle")
                                .foregroundStyle(Theme.brass)

                            Text(
                                "You will be notified as your\nrequest moves through each stage"
                            )
                            .font(Theme.ui(12))
                            .foregroundStyle(Theme.textMuted)
                        }
                        .padding(12)
                        .background(Theme.brass.opacity(0.08))
                        .clipShape(
                            RoundedRectangle(cornerRadius: 10)
                        )

                        if isSubmitting {
                            HStack(spacing: 12) {
                                ProgressView()
                                    .tint(Theme.appPurple)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Submitting your request")
                                        .font(Theme.ui(13, weight: .semibold))
                                        .foregroundStyle(Theme.appNavy)

                                    Text("Please wait while your request is saved.")
                                        .font(Theme.ui(11))
                                        .foregroundStyle(Theme.appMuted)
                                }

                                Spacer()
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                Theme.appPurpleSoft,
                                in: RoundedRectangle(cornerRadius: 14)
                            )
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Submitting maintenance request. Please wait.")
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("New Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isSubmitting ? "Submitting…" : "Submit") {
                        guard !isSubmitting else { return }
                        isSubmitting = true
                        submissionError = nil
                        Task { @MainActor in
                            do {
                                let photo = selectedImage?.jpegData(compressionQuality: 0.72)
                                try await store.submitMaintenanceRequest(
                                    title: title, details: details, photoData: photo)
                                dismiss()
                            } catch {
                                HapticManager.error()
                                submissionError = error.localizedDescription
                            }
                            isSubmitting = false
                        }
                    }
                    .disabled(
                        isSubmitting || isAnalysing ||
                        title.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty
                        ||
                        details.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty
                    )
                    .accessibilityLabel(
                        isSubmitting ? "Submitting maintenance request" : "Submit maintenance request"
                    )
                    .accessibilityHint(
                        isSubmitting
                            ? "Please wait while your request is saved"
                            : "Submits your maintenance request to building management"
                    )
                }
            }
        }
        .alert("Request not submitted", isPresented: Binding(
            get: { submissionError != nil },
            set: { if !$0 { submissionError = nil } }
        )) {
            Button("OK", role: .cancel) { submissionError = nil }
        } message: {
            Text(submissionError ?? "Unknown error")
        }
    }

    // MARK: - Load Photo

    @MainActor
    private func loadSelectedPhoto(
        _ photo: PhotosPickerItem?
    ) async {

        selectedImage = nil
        detections = []
        detectionError = nil
        isAnalysing = false

        guard let photo else {
            return
        }

        do {
            guard let data = try await photo.loadTransferable(
                type: Data.self
            ),
            let image = UIImage(data: data) else {
                detectionError = "Unable to load the selected photo."
                return
            }

            selectedImage = image
            isAnalysing = true

            // Run Core ML inference away from the UI thread.
            let result = await Task.detached(
                priority: .userInitiated
            ) {
                Result {
                    let service = try MaintenanceDetectionService()

                    return try service.detect(
                        image: image,
                        confidenceThreshold: 0.25
                    )
                }
            }.value

            switch result {
            case .success(let objects):
                detections = objects
                if let best = objects.max(by: { $0.confidence < $1.confidence }),
                   best.confidence >= 0.45 {
                    let issue = best.label.replacingOccurrences(of: "_", with: " ").capitalized
                    if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        title = issue
                    }
                    if details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        details = "Possible \(issue.lowercased()) detected in the photo. Please verify the issue and describe its location and severity."
                    }
                }

            case .failure(let error):
                detectionError = error.localizedDescription
            }

            isAnalysing = false

        } catch {
            detectionError = error.localizedDescription
            isAnalysing = false
        }
    }
}
