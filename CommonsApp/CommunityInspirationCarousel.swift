//
//  CommunityInspirationCarousel.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 22/10/2026.
//

import Foundation
import SwiftUI
struct CommunityInspirationCarousel: View {
    @State private var selectedImage = 0
    private let imageNames = ["CommunityInspiration1", "CommunityInspiration2", "CommunityInspiration3", "CommunityInspiration4", "CommunityInspiration5", "CommunityInspiration6"]
    private let quotes = ["Make memories together", "A kinder neighbourhood makes a brighter tomorrow", "Small conversations build big communities", "A healthier community is a happier community", "Good neighbours make home feel special", "Different people, brighter days"]
    var body: some View {
        ZStack {
            Image(imageNames[selectedImage])
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 228)
                .clipped()
                .id(selectedImage)
                .transition(.opacity)
        }
        .frame(height: 228)
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .accessibilityLabel("Community inspiration: \(quotes[selectedImage])")
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
