import Foundation
import CoreBluetooth
import AVFoundation
import Combine

public struct DiscoveredBluetoothDevice: Identifiable, Hashable {
    public var id: String { name }
    public var name: String
    public var typeDescription: String
    public var isConnected: Bool
    public var isCarPlay: Bool

    public init(name: String, typeDescription: String, isConnected: Bool = false, isCarPlay: Bool = false) {
        self.name = name
        self.typeDescription = typeDescription
        self.isConnected = isConnected
        self.isCarPlay = isCarPlay
    }
}

public final class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate {
    public static let shared = BluetoothManager()

    private var centralManager: CBCentralManager!

    @Published public var isCarPlayConnected: Bool = false
    @Published public var connectedDeviceName: String?
    @Published public var isBluetoothConnectedToCar: Bool = false
    @Published public var discoveredDevices: [DiscoveredBluetoothDevice] = []
    @Published public var isScanning: Bool = false

    public var onDeviceConnected: ((String) -> Void)?
    public var onDeviceDisconnected: (() -> Void)?

    private override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil, options: [
            CBCentralManagerOptionShowPowerAlertKey: false
        ])
        setupAudioRouteMonitoring()
        checkCurrentAudioRoute()
        populateDefaultDevices()
    }

    private func setupAudioRouteMonitoring() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioRouteChange(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }

    @objc private func handleAudioRouteChange(_ notification: Notification) {
        checkCurrentAudioRoute()
    }

    public func checkCurrentAudioRoute() {
        let session = AVAudioSession.sharedInstance()
        let currentRoute = session.currentRoute

        var detectedCarPlay = false
        var detectedCarBT = false
        var detectedName: String?

        for output in currentRoute.outputs {
            if output.portType == .carAudio {
                detectedCarPlay = true
                detectedName = output.portName.isEmpty ? "CarPlay" : output.portName
                break
            } else if output.portType == .bluetoothA2DP || output.portType == .bluetoothHFP || output.portType == .bluetoothLE {
                detectedCarBT = true
                detectedName = output.portName
            }
        }

        DispatchQueue.main.async {
            self.isCarPlayConnected = detectedCarPlay
            self.isBluetoothConnectedToCar = detectedCarBT

            if detectedCarPlay || detectedCarBT {
                let name = detectedName ?? (detectedCarPlay ? "CarPlay" : "Bluetooth Auto")
                self.connectedDeviceName = name
                self.onDeviceConnected?(name)
                self.addDevice(name: name, typeDescription: detectedCarPlay ? "CarPlay (Verbonden)" : "Bluetooth Audio (Verbonden)", isConnected: true, isCarPlay: detectedCarPlay)
            } else {
                if self.connectedDeviceName != nil {
                    self.connectedDeviceName = nil
                    self.onDeviceDisconnected?()
                }
            }
        }
    }

    public func startScanning() {
        populateDefaultDevices()
        isScanning = true

        if centralManager.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: nil, options: [
                CBCentralManagerScanOptionAllowDuplicatesKey: false
            ])
        }

        // Auto-stop scanning after 15 seconds to save battery
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak self] in
            self?.stopScanning()
        }
    }

    public func stopScanning() {
        isScanning = false
        if centralManager.state == .poweredOn {
            centralManager.stopScan()
        }
    }

    private func populateDefaultDevices() {
        var list: [DiscoveredBluetoothDevice] = [
            DiscoveredBluetoothDevice(name: "CarPlay", typeDescription: "Apple CarPlay Verbinding", isConnected: isCarPlayConnected, isCarPlay: true)
        ]

        let session = AVAudioSession.sharedInstance()
        for output in session.currentRoute.outputs {
            if !output.portName.isEmpty && output.portName != "CarPlay" {
                list.append(DiscoveredBluetoothDevice(name: output.portName, typeDescription: "Huidige Audio-uitvoer", isConnected: true))
            }
        }

        if let inputs = session.availableInputs {
            for input in inputs {
                if (input.portType == .bluetoothHFP || input.portType == .bluetoothA2DP || input.portType == .carAudio) && !input.portName.isEmpty {
                    if !list.contains(where: { $0.name == input.portName }) {
                        list.append(DiscoveredBluetoothDevice(name: input.portName, typeDescription: "Bluetooth Handsfree", isConnected: false))
                    }
                }
            }
        }

        self.discoveredDevices = list
    }

    private func addDevice(name: String, typeDescription: String, isConnected: Bool, isCarPlay: Bool) {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        if let idx = discoveredDevices.firstIndex(where: { $0.name == name }) {
            discoveredDevices[idx].isConnected = isConnected
        } else {
            discoveredDevices.append(DiscoveredBluetoothDevice(name: name, typeDescription: typeDescription, isConnected: isConnected, isCarPlay: isCarPlay))
        }
    }

    // MARK: - CBCentralManagerDelegate

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn && isScanning {
            central.scanForPeripherals(withServices: nil, options: [
                CBCentralManagerScanOptionAllowDuplicatesKey: false
            ])
        }
    }

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? peripheral.name
        if let devName = name, !devName.isEmpty {
            DispatchQueue.main.async {
                self.addDevice(name: devName, typeDescription: "Bluetooth Apparaat", isConnected: false, isCarPlay: false)
            }
        }
    }
}
