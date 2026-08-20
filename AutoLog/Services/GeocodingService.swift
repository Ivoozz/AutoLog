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

            var parts: [String] = []
            if let thoroughfare = place.thoroughfare {
                if let subThoroughfare = place.subThoroughfare {
                    parts.append("\(thoroughfare) \(subThoroughfare)")
                } else {
                    parts.append(thoroughfare)
                }
            }

            if let locality = place.locality {
                parts.append(locality)
            } else if let subLocality = place.subLocality {
                parts.append(subLocality)
            }

            if parts.isEmpty {
                return place.name ?? String(format: "%.4f, %.4f", latitude, longitude)
            }

            return parts.joined(separator: ", ")
        } catch {
            return String(format: "%.4f, %.4f", latitude, longitude)
        }
    }
}
