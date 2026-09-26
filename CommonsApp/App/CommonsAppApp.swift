//
//  CommonsAppApp.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 21/9/2026.
//

import SwiftUI

@main
struct CommonsApp: App {

    // Create one AppStore for the whole app
    // @StateObject means it gets created once and never destroyed
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}
