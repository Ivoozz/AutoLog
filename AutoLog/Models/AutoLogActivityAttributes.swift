import Foundation
import ActivityKit

public struct AutoLogActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var distanceKm: Double
        public var currentSpeedKmH: Double
        public var tripTypeDisplayName: String
        public var tripTypeShortLabel: String
        public var isBusiness: Bool
        public var startAddress: String
        public var vehicleName: String
        public var licensePlate: String
        public var startTime: Date

        public init(
            distanceKm: Double = 0.0,
            currentSpeedKmH: Double = 0.0,
            tripTypeDisplayName: String = "Zakelijk (Werk)",
            tripTypeShortLabel: String = "Zakelijk",
            isBusiness: Bool = true,
            startAddress: String = "Vertrekpunt",
            vehicleName: String = "Auto",
            licensePlate: String = "",
            startTime: Date = Date()
        ) {
            self.distanceKm = distanceKm
            self.currentSpeedKmH = currentSpeedKmH
            self.tripTypeDisplayName = tripTypeDisplayName
            self.tripTypeShortLabel = tripTypeShortLabel
            self.isBusiness = isBusiness
            self.startAddress = startAddress
            self.vehicleName = vehicleName
            self.licensePlate = licensePlate
            self.startTime = startTime
        }
    }

    public var tripId: String

    public init(tripId: String = UUID().uuidString) {
        self.tripId = tripId
    }
}
