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
    private var oneTimeLocationContinuations: [CheckedContinuation<CLLocation?, Never>] = []

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10.0
        locationManager.pausesLocationUpdatesAutomatically = false
        self.authorizationStatus = locationManager.authorizationStatus
    }

    public func requestPermissions() {
        if authorizationStatus == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        }
    }

    public func requestOneTimeLocation() async -> CLLocation? {
        if authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }

        // If we already have a recent valid location (< 30 seconds old)
        if let current = currentLocation, abs(current.timestamp.timeIntervalSinceNow) < 30 {
            return current
        }

        return await withCheckedContinuation { continuation in
            self.oneTimeLocationContinuations.append(continuation)
            self.locationManager.requestLocation()

            // Safety timeout after 6 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) { [weak self] in
                guard let self = self else { return }
                self.resolveOneTimeContinuations(with: self.currentLocation)
            }
        }
    }

    private func resolveOneTimeContinuations(with location: CLLocation?) {
        guard !oneTimeLocationContinuations.isEmpty else { return }
        let continuations = oneTimeLocationContinuations
        oneTimeLocationContinuations.removeAll()
        for cont in continuations {
            cont.resume(returning: location)
        }
    }

    public func startTripTracking() {
        guard !isTracking else { return }
        recordedPoints.removeAll()
        currentTripDistanceKm = 0.0
        currentSpeedKmH = 0.0
        lastValidLocation = nil
        isTracking = true

        if Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") != nil {
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.showsBackgroundLocationIndicator = true
        }

        locationManager.startUpdatingLocation()
        locationManager.startMonitoringSignificantLocationChanges()
    }

    public func stopTripTracking() -> [CoordinatePoint] {
        guard isTracking else { return recordedPoints }
        isTracking = false
        locationManager.stopUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = false
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

        // Filter out completely invalid or future coordinates
        guard location.horizontalAccuracy >= 0 && location.horizontalAccuracy <= 200.0 else {
            return
        }

        DispatchQueue.main.async {
            self.currentLocation = location
            self.currentSpeedKmH = max(0, location.speed * 3.6)
            self.resolveOneTimeContinuations(with: location)

            if self.isTracking {
                if let last = self.lastValidLocation {
                    let deltaMeters = location.distance(from: last)
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
        DispatchQueue.main.async {
            self.resolveOneTimeContinuations(with: self.currentLocation)
        }
    }
}
