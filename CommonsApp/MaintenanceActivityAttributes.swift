import ActivityKit
import Foundation
// MARK: - Shared Live Activity data
struct MaintenanceActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var stage: Int
        var updatedAt: Date
    }
    var requestId: String
    var residentId: String
    var title: String
}
