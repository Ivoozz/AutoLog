import Foundation
import CoreLocation

public enum LocationCategory: String, Codable, CaseIterable, Identifiable {
    case home = "home"
    case work = "work"
    case custom = "custom"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .home: return "Woonadres (Thuis)"
        case .work: return "Werkadres (Kantoor / Zaak)"
        case .custom: return "Favoriet Adres"
        }
    }

    public var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .work: return "building.2.fill"
        case .custom: return "mappin.and.ellipse"
        }
    }
}

public struct SavedLocation: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var address: String
    public var latitude: Double
    public var longitude: Double
    public var radiusMeters: Double
    public var category: LocationCategory

    public init(
        id: UUID = UUID(),
        name: String,
        address: String,
        latitude: Double = 0.0,
        longitude: Double = 0.0,
        radiusMeters: Double = 250.0,
        category: LocationCategory = .home
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.radiusMeters = radiusMeters
        self.category = category
    }

    public func matches(latitude: Double, longitude: Double) -> Bool {
        guard self.latitude != 0.0, self.longitude != 0.0 else { return false }
        let loc1 = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let loc2 = CLLocation(latitude: latitude, longitude: longitude)
        return loc1.distance(from: loc2) <= radiusMeters
    }
}
