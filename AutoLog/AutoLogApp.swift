import SwiftUI

@main
struct AutoLogApp: App {
    @StateObject private var storage = StorageManager.shared
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var bluetoothManager = BluetoothManager.shared
    @StateObject private var tripEngine = TripDetectionEngine.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(storage)
                .environmentObject(locationManager)
                .environmentObject(bluetoothManager)
                .environmentObject(tripEngine)
                .onAppear {
                    locationManager.requestPermissions()
                }
        }
    }
}
