import Foundation
import CoreLocation

public final class GeocodingService {
    public static let shared = GeocodingService()
    private let geocoder = CLGeocoder()

    private init() {}

    public func reverseGeocode(latitude: Double, longitude: Double) async -> String {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let place = placemarks.first else {
                return String(format: "%.4f, %.4f", latitude, longitude)
            }

            var streetPart = ""
            if let thoroughfare = place.thoroughfare {
                if let subThoroughfare = place.subThoroughfare {
                    streetPart = "\(thoroughfare) \(subThoroughfare)"
                } else {
                    streetPart = thoroughfare
                }
            } else if let name = place.name, name != place.locality {
                streetPart = name
            }

            var cityPart = ""
            if let locality = place.locality {
                cityPart = locality
            } else if let subLocality = place.subLocality {
                cityPart = subLocality
            } else if let adminArea = place.administrativeArea {
                cityPart = adminArea
            }

            if !streetPart.isEmpty && !cityPart.isEmpty {
                return "\(streetPart), \(cityPart)"
            } else if !streetPart.isEmpty {
                return streetPart
            } else if !cityPart.isEmpty {
                return cityPart
            } else {
                return place.name ?? String(format: "%.4f, %.4f", latitude, longitude)
            }
        } catch {
            return String(format: "%.4f, %.4f", latitude, longitude)
        }
    }
}
