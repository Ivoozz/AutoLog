import Foundation
import Combine
import CoreLocation

public final class TripDetectionEngine: ObservableObject {
    public static let shared = TripDetectionEngine()

    @Published public var isTripActive: Bool = false
    @Published public var activeVehicle: Vehicle?
    @Published public var activeTripType: TripType = .workBusiness
    @Published public var activeStartTime: Date?
    @Published public var activeStartAddress: String = "Locatie bepalen..."
    @Published public var activeDistanceKm: Double = 0.0

    private var cancellables = Set<AnyCancellable>()
    private let storage = StorageManager.shared
    private let locationManager = LocationManager.shared
    private let bluetoothManager = BluetoothManager.shared
    private let geocoding = GeocodingService.shared

    private var startCoordinate: CoordinatePoint?
    private var matchedStartLocation: SavedLocation?

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

        self.activeVehicle = vehicle
        self.activeTripType = tripType ?? vehicle.defaultTripType
        self.activeStartTime = Date()
        self.activeDistanceKm = 0.0
        self.activeStartAddress = "Locatie ophalen..."
        self.startCoordinate = nil
        self.matchedStartLocation = nil
        self.isTripActive = true

        locationManager.startTripTracking()

        if let loc = locationManager.currentLocation {
            let startPoint = CoordinatePoint(
                latitude: loc.coordinate.latitude,
                longitude: loc.coordinate.longitude,
                timestamp: Date(),
                speed: 0
            )
            self.startCoordinate = startPoint
            resolveStartAddress(point: startPoint)
        }
    }

    public func setTripType(_ type: TripType) {
        self.activeTripType = type
    }

    public func toggleTripType() {
        guard let vehicle = activeVehicle else { return }
        if vehicle.isWorkVehicle {
            // Toggle between Zakelijk and Privé on work vehicle
            activeTripType = (activeTripType == .workBusiness) ? .workPrivate : .workBusiness
        } else {
            activeTripType = .privatePrivate
        }
    }

    public func stopTrip() {
        guard isTripActive, let vehicle = activeVehicle, let startTime = activeStartTime else {
            return
        }

        let recordedPoints = locationManager.stopTripTracking()
        let distanceKm = locationManager.currentTripDistanceKm
        let endTime = Date()

        isTripActive = false

        // Check if minimum distance was met
        let minDistanceKm = storage.settings.minimumTripDistanceMeters / 1000.0
        guard distanceKm >= minDistanceKm else {
            print("Rit te kort (\(distanceKm) km < \(minDistanceKm) km), genegeerd.")
            return
        }

        let startOdo = vehicle.currentOdometer
        let endOdo = startOdo + distanceKm

        // Update vehicle odometer
        var updatedVehicle = vehicle
        updatedVehicle.currentOdometer = endOdo
        storage.addOrUpdateVehicle(updatedVehicle)

        let startCoord = self.startCoordinate ?? recordedPoints.first
        let endCoord = recordedPoints.last ?? startCoord

        let currentStartAddr = self.activeStartAddress

        Task {
            var finalStartAddr = currentStartAddr
            var finalStartLoc = self.matchedStartLocation

            if (finalStartAddr.contains("Locatie") || finalStartAddr.contains("Onbekend")), let sc = startCoord {
                let sRes = await self.geocoding.resolveAddress(
                    latitude: sc.latitude,
                    longitude: sc.longitude,
                    savedLocations: self.storage.savedLocations
                )
                finalStartAddr = sRes.displayAddress
                finalStartLoc = sRes.matchedLocation
            }

            var finalEndAddr = "Onbekende bestemming"
            var finalEndLoc: SavedLocation? = nil
            if let ec = endCoord {
                let eRes = await self.geocoding.resolveAddress(
                    latitude: ec.latitude,
                    longitude: ec.longitude,
                    savedLocations: self.storage.savedLocations
                )
                finalEndAddr = eRes.displayAddress
                finalEndLoc = eRes.matchedLocation
            }

            // Auto-detect Woon-werkverkeer
            var autoPurpose = self.activeTripType == .workBusiness ? "Zakelijke rit" : "Privé rit"
            if let sl = finalStartLoc, let el = finalEndLoc {
                if (sl.category == .home && el.category == .work) || (sl.category == .work && el.category == .home) {
                    autoPurpose = "Woon-werkverkeer"
                }
            }

            let newTrip = Trip(
                vehicleId: vehicle.id,
                vehicleName: vehicle.name,
                vehicleLicensePlate: vehicle.licensePlate,
                startTime: startTime,
                endTime: endTime,
                startAddress: finalStartAddr,
                endAddress: finalEndAddr,
                startCoordinate: startCoord,
                endCoordinate: endCoord,
                distanceInKm: distanceKm,
                startOdometer: startOdo,
                endOdometer: endOdo,
                tripType: self.activeTripType,
                purposeDescription: autoPurpose,
                routePoints: recordedPoints,
                isExported: false
            )

            DispatchQueue.main.async {
                self.storage.addTrip(newTrip)
            }
        }
    }
}
