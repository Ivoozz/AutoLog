import Foundation
import ActivityKit
import Combine

public final class LiveActivityManager: ObservableObject {
    public static let shared = LiveActivityManager()

    private var currentActivity: Activity<AutoLogActivityAttributes>?

    private init() {}

    public func startLiveActivity(
        vehicleName: String,
        licensePlate: String,
        startAddress: String,
        tripType: TripType,
        startTime: Date
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities zijn niet ingeschakeld door gebruiker.")
            return
        }

        // End any orphaned previous activity first
        endLiveActivity()

        let attributes = AutoLogActivityAttributes(tripId: UUID().uuidString)
        let initialContentState = AutoLogActivityAttributes.ContentState(
            distanceKm: 0.0,
            currentSpeedKmH: 0.0,
            tripTypeDisplayName: tripType.displayName,
            tripTypeShortLabel: tripType.shortLabel,
            isBusiness: tripType == .workBusiness,
            startAddress: startAddress,
            vehicleName: vehicleName,
            licensePlate: licensePlate,
            startTime: startTime
        )

        do {
            let activity = try Activity<AutoLogActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: initialContentState, staleDate: nil),
                pushType: nil
            )
            self.currentActivity = activity
            print("Live Activity gestart met ID: \(activity.id)")
        } catch {
            print("Kon Live Activity niet starten: \(error.localizedDescription)")
        }
    }

    public func updateLiveActivity(
        distanceKm: Double,
        currentSpeedKmH: Double,
        tripType: TripType,
        startAddress: String,
        vehicleName: String,
        licensePlate: String,
        startTime: Date
    ) {
        guard let activity = currentActivity else { return }

        let updatedContentState = AutoLogActivityAttributes.ContentState(
            distanceKm: distanceKm,
            currentSpeedKmH: currentSpeedKmH,
            tripTypeDisplayName: tripType.displayName,
            tripTypeShortLabel: tripType.shortLabel,
            isBusiness: tripType == .workBusiness,
            startAddress: startAddress,
            vehicleName: vehicleName,
            licensePlate: licensePlate,
            startTime: startTime
        )

        Task {
            await activity.update(
                ActivityContent<AutoLogActivityAttributes.ContentState>(
                    state: updatedContentState,
                    staleDate: nil
                )
            )
        }
    }

    public func endLiveActivity() {
        guard let activity = currentActivity else {
            // Check for any running activities and end them
            for act in Activity<AutoLogActivityAttributes>.activities {
                Task {
                    await act.end(nil, dismissalPolicy: .immediate)
                }
            }
            return
        }

        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            self.currentActivity = nil
        }
    }
}
