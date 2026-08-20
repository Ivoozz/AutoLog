import Foundation
import CoreBluetooth
import AVFoundation
import Combine

public final class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate {
    public static let shared = BluetoothManager()

    private var centralManager: CBCentralManager!

    @Published public var isCarPlayConnected: Bool = false
    @Published public var connectedDeviceName: String?
    @Published public var isBluetoothConnectedToCar: Bool = false

    public var onDeviceConnected: ((String) -> Void)?
    public var onDeviceDisconnected: (() -> Void)?

    private override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil, options: [
            CBCentralManagerOptionShowPowerAlertKey: false
        ])
        setupAudioRouteMonitoring()
        checkCurrentAudioRoute()
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
            } else {
                if self.connectedDeviceName != nil {
                    self.connectedDeviceName = nil
                    self.onDeviceDisconnected?()
                }
            }
        }
    }

    // MARK: - CBCentralManagerDelegate

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            central.scanForPeripherals(withServices: nil, options: nil)
        }
    }

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Can be used to check known peripheral tags
    }
}
