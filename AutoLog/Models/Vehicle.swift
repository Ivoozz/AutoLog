import Foundation

public struct Vehicle: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var licensePlate: String
    public var isWorkVehicle: Bool
    public var bluetoothName: String
    public var defaultTripType: TripType
    public var currentOdometer: Double

    public init(
        id: UUID = UUID(),
        name: String,
        licensePlate: String,
        isWorkVehicle: Bool,
        bluetoothName: String,
        defaultTripType: TripType? = nil,
        currentOdometer: Double = 0.0
    ) {
        self.id = id
        self.name = name
        self.licensePlate = licensePlate
        self.isWorkVehicle = isWorkVehicle
        self.bluetoothName = bluetoothName
        self.defaultTripType = defaultTripType ?? (isWorkVehicle ? .workBusiness : .privatePrivate)
        self.currentOdometer = currentOdometer
    }
}
