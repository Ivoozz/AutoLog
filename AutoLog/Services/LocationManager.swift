import Foundation
import CoreLocation
import Combine

public final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    public static let shared = LocationManager()

    private let locationManager = CLLocationManager()

    @Published public var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published public var currentLocation: CLLocation?
    @Published public var isTracking: Bool = false
    @Published public var currentTripDistanceKm: Double = 0.0
    @Published public var currentSpeedKmH: Double = 0.0
    @Published public var recordedPoints: [CoordinatePoint] = []

    private var lastValidLocation: CLLocation?

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 10.0 // updates every 10 meters
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.showsBackgroundLocationIndicator = true
        self.authorizationStatus = locationManager.authorizationStatus
    }

    public func requestPermissions() {
        locationManager.requestAlwaysAuthorization()
    }

    public func startTripTracking() {
        guard !isTracking else { return }
        recordedPoints.removeAll()
        currentTripDistanceKm = 0.0
        currentSpeedKmH = 0.0
        lastValidLocation = nil
        isTracking = true

        locationManager.startUpdatingLocation()
        locationManager.startMonitoringSignificantLocationChanges()
    }

    public func stopTripTracking() -> [CoordinatePoint] {
        guard isTracking else { return recordedPoints }
        isTracking = false
        locationManager.stopUpdatingLocation()
        let finalPoints = recordedPoints
        return finalPoints
    }

    // MARK: - CLLocationManagerDelegate

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        // Filter out inaccurate points
        guard location.horizontalAccuracy >= 0 && location.horizontalAccuracy <= 30.0 else {
            return
        }

        DispatchQueue.main.async {
            self.currentLocation = location
            self.currentSpeedKmH = max(0, location.speed * 3.6)

            if self.isTracking {
                if let last = self.lastValidLocation {
                    let deltaMeters = location.distance(from: last)
                    // Avoid GPS bounce when stationary
                    if deltaMeters > 5.0 {
                        self.currentTripDistanceKm += (deltaMeters / 1000.0)
                        self.lastValidLocation = location
                        let point = CoordinatePoint(
                            latitude: location.coordinate.latitude,
                            longitude: location.coordinate.longitude,
                            timestamp: location.timestamp,
                            speed: self.currentSpeedKmH
                        )
                        self.recordedPoints.append(point)
                    }
                } else {
                    self.lastValidLocation = location
                    let point = CoordinatePoint(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude,
                        timestamp: location.timestamp,
                        speed: self.currentSpeedKmH
                    )
                    self.recordedPoints.append(point)
                }
            }
        }
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
    }
}
