import ActivityKit
import Foundation
// MARK: - Maintenance Live Activity manager
@MainActor
final class MaintenanceActivityManager {
    static let shared = MaintenanceActivityManager()
    private init() {}
    // Start a Live Activity after Firestore successfully saves a request.
    func start(requestId: String, residentId: String, title: String) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        guard !Activity<MaintenanceActivityAttributes>.activities.contains(where: { $0.attributes.requestId == requestId }) else { return }
        let attributes = MaintenanceActivityAttributes(requestId: requestId, residentId: residentId, title: title)
        let state = MaintenanceActivityAttributes.ContentState(stage: 0, updatedAt: Date())
        do {
            _ = try Activity.request(attributes: attributes, content: ActivityContent(state: state, staleDate: nil), pushType: nil)
        } catch {
            print("Could not start maintenance Live Activity: \(error.localizedDescription)")
        }
    }
    // Update only the signed-in resident's existing activities.
    func synchronize(requests: [MaintenanceRequest], residentId: String) async {
        let requestsById = Dictionary(uniqueKeysWithValues: requests.map { ($0.id.uuidString.lowercased(), $0) })
        for activity in Activity<MaintenanceActivityAttributes>.activities {
            guard activity.attributes.residentId == residentId else { continue }
            let id = activity.attributes.requestId
            guard let request = requestsById[id] else { continue }
            let state = MaintenanceActivityAttributes.ContentState(stage: request.stage.rawValue, updatedAt: Date())
            let content = ActivityContent(state: state, staleDate: nil)
            if request.stage == .complete {
                await activity.end(content, dismissalPolicy: .default)
            } else if activity.content.state.stage != state.stage {
                await activity.update(content)
            }
        }
    }
    // Prevent showing a previous resident's activity after sign-out.
    func endActivities(residentId: String) async {
        for activity in Activity<MaintenanceActivityAttributes>.activities {
            if activity.attributes.residentId == residentId {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}
