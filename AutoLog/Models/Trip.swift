import Foundation
import CoreLocation

public struct CoordinatePoint: Codable, Equatable {
    public let latitude: Double
    public let longitude: Double
    public let timestamp: Date
    public let speed: Double

    public init(latitude: Double, longitude: Double, timestamp: Date = Date(), speed: Double = 0.0) {
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
        self.speed = speed
    }

    public var clLocationCoordinate2D: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

public struct Trip: Identifiable, Codable, Equatable {
    public var id: UUID
    public var vehicleId: UUID
    public var vehicleName: String
    public var vehicleLicensePlate: String
    public var startTime: Date
    public var endTime: Date
    public var startAddress: String
    public var endAddress: String
    public var startCoordinate: CoordinatePoint?
    public var endCoordinate: CoordinatePoint?
    public var distanceInKm: Double
    public var startOdometer: Double
    public var endOdometer: Double
    public var tripType: TripType
    public var purposeDescription: String
    public var routePoints: [CoordinatePoint]
    public var isExported: Bool

    public init(
        id: UUID = UUID(),
        vehicleId: UUID,
        vehicleName: String,
        vehicleLicensePlate: String,
        startTime: Date = Date(),
        endTime: Date = Date(),
        startAddress: String = "Onbekend vertrekpunt",
        endAddress: String = "Onbekende bestemming",
        startCoordinate: CoordinatePoint? = nil,
        endCoordinate: CoordinatePoint? = nil,
        distanceInKm: Double = 0.0,
        startOdometer: Double = 0.0,
        endOdometer: Double = 0.0,
        tripType: TripType = .workBusiness,
        purposeDescription: String = "",
        routePoints: [CoordinatePoint] = [],
        isExported: Bool = false
    ) {
        self.id = id
        self.vehicleId = vehicleId
        self.vehicleName = vehicleName
        self.vehicleLicensePlate = vehicleLicensePlate
        self.startTime = startTime
        self.endTime = endTime
        self.startAddress = startAddress
        self.endAddress = endAddress
        self.startCoordinate = startCoordinate
        self.endCoordinate = endCoordinate
        self.distanceInKm = distanceInKm
        self.startOdometer = startOdometer
        self.endOdometer = endOdometer
        self.tripType = tripType
        self.purposeDescription = purposeDescription
        self.routePoints = routePoints
        self.isExported = isExported
    }

    public var durationInSeconds: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }

    public var formattedDuration: String {
        let minutes = Int(durationInSeconds / 60)
        let hours = minutes / 60
        let remMin = minutes % 60
        if hours > 0 {
            return "\(hours)u \(remMin)m"
        } else {
            return "\(remMin) min"
        }
    }
}
