//
//  Item.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 21/9/2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
