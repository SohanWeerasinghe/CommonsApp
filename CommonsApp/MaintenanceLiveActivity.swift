import ActivityKit
import WidgetKit
import SwiftUI
// MARK: - Maintenance Live Activity widget
struct MaintenanceLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MaintenanceActivityAttributes.self) { context in
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Maintenance request", systemImage: "wrench.and.screwdriver.fill")
                        .font(.caption.weight(.semibold))
                    Spacer()
                    Text("\(min(context.state.stage + 1, 4))/4")
                        .font(.caption.monospacedDigit())
                }
                Text(context.attributes.title)
                    .font(.headline)
                    .lineLimit(2)
                Text(stageName(context.state.stage))
                    .font(.subheadline.weight(.medium))
                ProgressView(value: Double(min(max(context.state.stage + 1, 1), 4)), total: 4)
                    .tint(.blue)
                Text("Updated \(context.state.updatedAt, style: .time)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .activityBackgroundTint(Color(.systemBackground))
            .widgetURL(URL(string: "commonsapp://maintenance"))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .foregroundStyle(.blue)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(min(context.state.stage + 1, 4))/4")
                        .font(.caption.bold())
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.title)
                        .font(.headline)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 5) {
                        Text(stageName(context.state.stage))
                        ProgressView(value: Double(min(max(context.state.stage + 1, 1), 4)), total: 4)
                            .tint(.blue)
                    }
                }
            } compactLeading: {
                Image(systemName: "wrench.fill")
            } compactTrailing: {
                Text("\(min(context.state.stage + 1, 4))/4")
            } minimal: {
                Image(systemName: "wrench.fill")
            }
            .widgetURL(URL(string: "commonsapp://maintenance"))
        }
    }
    // MARK: - Existing Firestore stages
    private func stageName(_ stage: Int) -> String {
        switch stage {
        case 0: return "Submitted"
        case 1: return "Assigned"
        case 2: return "On the Way"
        case 3: return "Complete"
        default: return "Status unavailable"
        }
    }
}
