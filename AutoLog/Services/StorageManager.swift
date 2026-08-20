import Foundation
import Combine

public final class StorageManager: ObservableObject {
    public static let shared = StorageManager()

    @Published public var vehicles: [Vehicle] = []
    @Published public var trips: [Trip] = []
    @Published public var settings: UserSettings = UserSettings()
    @Published public var savedLocations: [SavedLocation] = []

    private let vehiclesKey = "autolog_vehicles_store"
    private let tripsKey = "autolog_trips_store"
    private let settingsKey = "autolog_settings_store"
    private let locationsKey = "autolog_saved_locations_store"

    private init() {
        loadData()
        if vehicles.isEmpty {
            seedInitialVehicles()
        }
        if savedLocations.isEmpty {
            seedInitialLocations()
        }
    }

    public func loadData() {
        if let data = UserDefaults.standard.data(forKey: vehiclesKey),
           let decoded = try? JSONDecoder().decode([Vehicle].self, from: data) {
            self.vehicles = decoded
        }

        if let data = UserDefaults.standard.data(forKey: tripsKey),
           let decoded = try? JSONDecoder().decode([Trip].self, from: data) {
            self.trips = decoded.sorted(by: { $0.startTime > $1.startTime })
        }

        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(UserSettings.self, from: data) {
            self.settings = decoded
        }

        if let data = UserDefaults.standard.data(forKey: locationsKey),
           let decoded = try? JSONDecoder().decode([SavedLocation].self, from: data) {
            self.savedLocations = decoded
        }
    }

    public func saveVehicles() {
        if let encoded = try? JSONEncoder().encode(vehicles) {
            UserDefaults.standard.set(encoded, forKey: vehiclesKey)
        }
    }

    public func saveTrips() {
        if let encoded = try? JSONEncoder().encode(trips) {
            UserDefaults.standard.set(encoded, forKey: tripsKey)
        }
    }

    public func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }
    }

    public func saveLocations() {
        if let encoded = try? JSONEncoder().encode(savedLocations) {
            UserDefaults.standard.set(encoded, forKey: locationsKey)
        }
    }

    public func addTrip(_ trip: Trip) {
        trips.insert(trip, at: 0)
        saveTrips()
    }

    public func updateTrip(_ trip: Trip) {
        if let index = trips.firstIndex(where: { $0.id == trip.id }) {
            trips[index] = trip
            saveTrips()
        }
    }

    public func deleteTrip(at offsets: IndexSet) {
        trips.remove(atOffsets: offsets)
        saveTrips()
    }

    public func deleteTrip(id: UUID) {
        trips.removeAll(where: { $0.id == id })
        saveTrips()
    }

    public func addOrUpdateVehicle(_ vehicle: Vehicle) {
        if let index = vehicles.firstIndex(where: { $0.id == vehicle.id }) {
            vehicles[index] = vehicle
        } else {
            vehicles.append(vehicle)
        }
        saveVehicles()
    }

    public func deleteVehicle(id: UUID) {
        vehicles.removeAll(where: { $0.id == id })
        saveVehicles()
    }

    public func addOrUpdateLocation(_ location: SavedLocation) {
        if let index = savedLocations.firstIndex(where: { $0.id == location.id }) {
            savedLocations[index] = location
        } else {
            savedLocations.append(location)
        }
        saveLocations()
    }

    public func deleteLocation(id: UUID) {
        savedLocations.removeAll(where: { $0.id == id })
        saveLocations()
    }

    private func seedInitialVehicles() {
        let workCar = Vehicle(
            name: "Werkauto (CarPlay / BT)",
            licensePlate: "V-123-ZZ",
            isWorkVehicle: true,
            bluetoothName: "CarPlay",
            defaultTripType: .workBusiness,
            currentOdometer: 45200.0
        )
        let privateCar = Vehicle(
            name: "Privéauto",
            licensePlate: "N-456-AA",
            isWorkVehicle: false,
            bluetoothName: "Privé Bluetooth",
            defaultTripType: .privatePrivate,
            currentOdometer: 112000.0
        )
        vehicles = [workCar, privateCar]
        saveVehicles()
    }

    private func seedInitialLocations() {
        let home = SavedLocation(
            name: "Thuis",
            address: "",
            latitude: 0.0,
            longitude: 0.0,
            radiusMeters: 250.0,
            category: .home
        )
        let work = SavedLocation(
            name: "Kantoor / Werk",
            address: "",
            latitude: 0.0,
            longitude: 0.0,
            radiusMeters: 250.0,
            category: .work
        )
        savedLocations = [home, work]
        saveLocations()
    }
}
