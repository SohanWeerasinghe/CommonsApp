//
//  ProfilePhotoStore.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 22/10/2026.
//

import Foundation
import UIKit
import FirebaseAuth
import FirebaseFirestore

// Profile photos are small JPEGs stored separately from resident account data.
enum ProfilePhotoStore {
    static let maximumBytes = 40 * 1024
    static let maximumDimension: CGFloat = 256

    static func prepare(_ image: UIImage) throws -> String {
        let originalSize = image.size
        guard originalSize.width > 0, originalSize.height > 0 else {
            throw photoError("Invalid image.")
        }
        let scale = min(1, maximumDimension / max(originalSize.width, originalSize.height))
        let size = CGSize(width: max(1, floor(originalSize.width * scale)),
                          height: max(1, floor(originalSize.height * scale)))
        let renderer = UIGraphicsImageRenderer(size: size)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        for quality in [0.75, 0.6, 0.45, 0.3, 0.2] {
            if let data = resized.jpegData(compressionQuality: quality),
               data.count <= maximumBytes {
                return data.base64EncodedString()
            }
        }
        throw photoError("This photo could not be compressed below 40 KB. Try another image.")
    }

    static func decode(_ base64: String) -> UIImage? {
        guard let data = Data(base64Encoded: base64), data.count <= maximumBytes else { return nil }
        return UIImage(data: data)
    }

    static func load() async throws -> UIImage? {
        guard let uid = Auth.auth().currentUser?.uid else { throw photoError("Please sign in.") }
        let snapshot = try await Firestore.firestore().collection("residentProfilePhotos")
            .document(uid).getDocument()
        guard let base64 = snapshot.data()?["imageBase64"] as? String else { return nil }
        return decode(base64)
    }

    static func save(_ image: UIImage) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { throw photoError("Please sign in.") }
        let base64 = try prepare(image)
        try await Firestore.firestore().collection("residentProfilePhotos")
            .document(uid).setData([
                "imageBase64": base64,
                "ownerUID": uid,
                "updatedAt": FieldValue.serverTimestamp()
            ])
    }

    static func remove() async throws {
        guard let uid = Auth.auth().currentUser?.uid else { throw photoError("Please sign in.") }
        try await Firestore.firestore().collection("residentProfilePhotos")
            .document(uid).delete()
    }

    private static func photoError(_ message: String) -> NSError {
        NSError(domain: "CommonsApp.ProfilePhoto", code: 400,
                userInfo: [NSLocalizedDescriptionKey: message])
    }
}
