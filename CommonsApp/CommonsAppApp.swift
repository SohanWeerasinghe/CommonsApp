//
//  CommonsAppApp.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 21/9/2026.
//

import SwiftUI
import FirebaseCore

@main
struct CommonsApp: App {
    @StateObject private var store = AppStore()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}
