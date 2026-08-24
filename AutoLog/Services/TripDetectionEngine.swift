import Foundation
import CoreLocation
import Combine

public final class TripDetectionEngine: ObservableObject {
    public static let shared = TripDetectionEngine()

    @Published public var isTripActive: Bool = false
    @Published public var activeVehicle: Vehicle?
    @Published public var activeTripType: TripType = .workBusiness
    @Published public var activeStartTime: Date?
    @Published public var activeDistanceKm: Double = 0.0
    @Published public var activeStartAddress: String = "Locatie bepalen..."
    @Published public var startCoordinate: CoordinatePoint?

    private var matchedStartLocation: SavedLocation?
    private var cancellables = Set<AnyCancellable>()

    private let storage = StorageManager.shared
    private let locationManager = LocationManager.shared
    private let bluetoothManager = BluetoothManager.shared
    private let geocoding = GeocodingService.shared
    private let liveActivity = LiveActivityManager.shared

    private init() {
        bindLocationUpdates()
        bindBluetoothTriggers()
    }

    private func bindLocationUpdates() {
        locationManager.$currentTripDistanceKm
            .receive(on: DispatchQueue.main)
            .sink { [weak self] distance in
                guard let self = self, self.isTripActive else { return }
                self.activeDistanceKm = distance
                self.syncLiveActivity()
            }
            .store(in: &cancellables)

        locationManager.$currentLocation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                guard let self = self, self.isTripActive, let loc = location else { return }
                if self.startCoordinate == nil {
                    let pt = CoordinatePoint(
                        latitude: loc.coordinate.latitude,
                        longitude: loc.coordinate.longitude,
                        timestamp: Date(),
                        speed: 0
                    )
                    self.startCoordinate = pt
                    self.resolveStartAddress(point: pt)
                }
            }
            .store(in: &cancellables)
    }

    private func resolveStartAddress(point: CoordinatePoint) {
        Task {
            let result = await geocoding.resolveAddress(
                latitude: point.latitude,
                longitude: point.longitude,
                savedLocations: storage.savedLocations
            )
            DispatchQueue.main.async {
                self.activeStartAddress = result.displayAddress
                self.matchedStartLocation = result.matchedLocation
                self.syncLiveActivity()
            }
        }
    }

    private func bindBluetoothTriggers() {
        bluetoothManager.onDeviceConnected = { [weak self] deviceName in
            guard let self = self else { return }
            guard self.storage.settings.autoStartOnCarPlay || self.storage.settings.autoStartOnBluetooth else { return }
            guard !self.isTripActive else { return }

            // Match vehicle based on bluetooth name or default to first work vehicle
            let matchedVehicle = self.storage.vehicles.first { vehicle in
                !vehicle.bluetoothName.isEmpty && (
                    deviceName.localizedCaseInsensitiveContains(vehicle.bluetoothName) ||
                    vehicle.bluetoothName.localizedCaseInsensitiveContains(deviceName)
                )
            } ?? self.storage.vehicles.first(where: { $0.isWorkVehicle }) ?? self.storage.vehicles.first

            if let vehicle = matchedVehicle {
                self.startTrip(with: vehicle, tripType: vehicle.defaultTripType)
            }
        }

        bluetoothManager.onDeviceDisconnected = { [weak self] in
            guard let self = self, self.isTripActive else { return }
            self.stopTrip()
        }
    }

    public func startTrip(with vehicle: Vehicle, tripType: TripType? = nil) {
        guard !isTripActive else { return }

        let sTime = Date()
        self.activeVehicle = vehicle
        self.activeTripType = tripType ?? vehicle.defaultTripType
        self.activeStartTime = sTime
        self.activeDistanceKm = 0.0
        self.activeStartAddress = "Locatie bepalen..."
        self.startCoordinate = nil
        self.matchedStartLocation = nil
        self.isTripActive = true

        locationManager.startTripTracking()

        if let loc = locationManager.currentLocation {
            let startPoint = CoordinatePoint(
                latitude: loc.coordinate.latitude,
                longitude: loc.coordinate.longitude,
                timestamp: sTime,
                speed: 0
            )
            self.startCoordinate = startPoint
            resolveStartAddress(point: startPoint)
        }

        liveActivity.startLiveActivity(
            vehicleName: vehicle.name,
            licensePlate: vehicle.licensePlate,
            startAddress: self.activeStartAddress,
            tripType: self.activeTripType,
            startTime: sTime
        )
    }

    public func setTripType(_ type: TripType) {
        self.activeTripType = type
        syncLiveActivity()
    }

    public func toggleTripType() {
        guard let vehicle = activeVehicle else { return }
        if vehicle.isWorkVehicle {
            activeTripType = (activeTripType == .workBusiness) ? .workPrivate : .workBusiness
        } else {
            activeTripType = .privatePrivate
        }
        syncLiveActivity()
    }

    private func syncLiveActivity() {
        guard isTripActive, let vehicle = activeVehicle, let startTime = activeStartTime else { return }
        liveActivity.updateLiveActivity(
            distanceKm: activeDistanceKm,
            currentSpeedKmH: locationManager.currentSpeedKmH,
            tripType: activeTripType,
            startAddress: activeStartAddress,
            vehicleName: vehicle.name,
            licensePlate: vehicle.licensePlate,
            startTime: startTime
        )
    }

    public func stopTrip() {
        guard isTripActive, let vehicle = activeVehicle, let startTime = activeStartTime else {
            return
        }

        let recordedPoints = locationManager.stopTripTracking()
        let finalDistance = activeDistanceKm
        let endTime = Date()
        let startPoint = startCoordinate ?? recordedPoints.first ?? CoordinatePoint(latitude: 0, longitude: 0, timestamp: startTime, speed: 0)
        let endPoint = recordedPoints.last ?? startPoint

        isTripActive = false
        liveActivity.endLiveActivity()

        let startOdo = vehicle.currentOdometer
        let endOdo = startOdo + finalDistance

        var updatedVehicle = vehicle
        updatedVehicle.currentOdometer = endOdo
        storage.addOrUpdateVehicle(updatedVehicle)

        let startAddr = activeStartAddress
        let initialTripType = activeTripType
        let startLocationMatch = matchedStartLocation

        Task {
            let endResult = await geocoding.resolveAddress(
                latitude: endPoint.latitude,
                longitude: endPoint.longitude,
                savedLocations: storage.savedLocations
            )

            var finalTripType = initialTripType
            var purpose = ""

            if let startLoc = startLocationMatch, let endLoc = endResult.matchedLocation {
                if (startLoc.category == .home && endLoc.category == .work) ||
                   (startLoc.category == .work && endLoc.category == .home) {
                    purpose = "Woon-werkverkeer"
                    if vehicle.isWorkVehicle {
                        finalTripType = .workBusiness
                    }
                }
            }

            if purpose.isEmpty {
                purpose = finalTripType == .workBusiness ? "Zakelijk bezoek" : "Privé rit"
            }

            let newTrip = Trip(
                vehicleId: vehicle.id,
                vehicleName: vehicle.name,
                vehicleLicensePlate: vehicle.licensePlate,
                startTime: startTime,
                endTime: endTime,
                startOdometer: startOdo,
                endOdometer: endOdo,
                tripType: finalTripType,
                startAddress: startAddr,
                endAddress: endResult.displayAddress,
                startLatitude: startPoint.latitude,
                startLongitude: startPoint.longitude,
                endLatitude: endPoint.latitude,
                endLongitude: endPoint.longitude,
                routePoints: recordedPoints,
                purposeDescription: purpose
            )

            DispatchQueue.main.async {
                self.storage.addTrip(newTrip)
                self.resetActiveState()
            }
        }
    }

    private func resetActiveState() {
        self.activeVehicle = nil
        self.activeStartTime = nil
        self.activeDistanceKm = 0.0
        self.activeStartAddress = "Locatie bepalen..."
        self.startCoordinate = nil
        self.matchedStartLocation = nil
    }
}
