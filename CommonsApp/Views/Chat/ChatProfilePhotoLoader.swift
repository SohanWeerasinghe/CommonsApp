//
//  Untitled.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 22/10/2026.
//

import Foundation
import UIKit
import FirebaseFirestore

// Small, shared memory cache avoids downloading the same Base64 avatar for each chat row.
enum ChatProfilePhotoLoader {
    private static let cache = NSCache<NSString, UIImage>()

    static func load(uid: String) async -> UIImage? {
        let key = uid as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }
        do {
            let document = try await Firestore.firestore()
                .collection("residentProfilePhotos")
                .document(uid)
                .getDocument()
            guard let encoded = document.data()?["imageBase64"] as? String,
                  let image = ProfilePhotoStore.decode(encoded) else {
                return nil
            }
            cache.setObject(image, forKey: key)
            return image
        } catch {
            return nil
        }
    }
}
