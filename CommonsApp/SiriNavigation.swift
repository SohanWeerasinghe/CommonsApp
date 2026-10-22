//
//  SiriNavigation.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 22/10/2026.
//

import SwiftUI
import Combine

@MainActor
final class SiriNavigation: ObservableObject {

    static let shared = SiriNavigation()

    @Published var requestedTab: MainTab?

    private init() {}

    func open(_ tab: MainTab) {
        requestedTab = tab
    }
}
