import SwiftUI

public struct EditVehicleView: View {
    @ObservedObject var storage = StorageManager.shared
    @ObservedObject var bluetooth = BluetoothManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var vehicleId: UUID
    @State private var name: String
    @State private var licensePlate: String
    @State private var isWorkVehicle: Bool
    @State private var bluetoothName: String
    @State private var defaultTripType: TripType
    @State private var currentOdometer: String
    @State private var showManualInput = false

    public init(vehicle: Vehicle? = nil) {
        if let v = vehicle {
            _vehicleId = State(initialValue: v.id)
            _name = State(initialValue: v.name)
            _licensePlate = State(initialValue: v.licensePlate)
            _isWorkVehicle = State(initialValue: v.isWorkVehicle)
            _bluetoothName = State(initialValue: v.bluetoothName)
            _defaultTripType = State(initialValue: v.defaultTripType)
            _currentOdometer = State(initialValue: String(format: "%.0f", v.currentOdometer))
            _showManualInput = State(initialValue: !v.bluetoothName.isEmpty)
        } else {
            _vehicleId = State(initialValue: UUID())
            _name = State(initialValue: "")
            _licensePlate = State(initialValue: "")
            _isWorkVehicle = State(initialValue: true)
            _bluetoothName = State(initialValue: "")
            _defaultTripType = State(initialValue: .workBusiness)
            _currentOdometer = State(initialValue: "0")
            _showManualInput = State(initialValue: false)
        }
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Voertuig Informatie") {
                    TextField("Naam (bijv. BMW Werkauto of Golf)", text: $name)
                    TextField("Kenteken (bijv. V-123-ZZ)", text: $licensePlate)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()

                    Toggle("Is dit een zakelijke / werkauto?", isOn: $isWorkVehicle)
                }

                Section {
                    HStack {
                        Text("Kies Verbonden Apparaat")
                            .font(.subheadline)
                            .fontWeight(.bold)
                        Spacer()
                        Button(action: {
                            bluetooth.startScanning()
                        }) {
                            HStack(spacing: 4) {
                                if bluetooth.isScanning {
                                    ProgressView().scaleEffect(0.7)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                }
                                Text(bluetooth.isScanning ? "Scannen..." : "Zoeken")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(bluetooth.isScanning)
                    }

                    if bluetooth.discoveredDevices.isEmpty {
                        Text("Geen apparaten gevonden. Zorg dat Bluetooth aan staat of start het scannen.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(bluetooth.discoveredDevices) { device in
                            Button(action: {
                                bluetoothName = device.name
                            }) {
                                HStack {
                                    Image(systemName: device.isCarPlay ? "car.badge.gearshape.fill" : "antenna.radiowaves.left.and.right")
                                        .foregroundColor(device.isCarPlay ? .green : .blue)
                                        .frame(width: 24)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(device.name)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        Text(device.typeDescription)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    if bluetoothName == device.name {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                            .font(.headline)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Toggle("Handmatig naam invoeren", isOn: $showManualInput)

                    if showManualInput {
                        TextField("Bluetooth / CarPlay Naam", text: $bluetoothName)
                            .textFieldStyle(.roundedBorder)
                    }
                } header: {
                    Text("Automatische Herkenning")
                } footer: {
                    Text("Selecteer het Bluetooth- of CarPlay-apparaat van je auto. Zodra verbinding wordt gemaakt, wordt deze auto automatisch geactiveerd.")
                }

                Section("Standaard Rittype") {
                    Picker("Standaard Type", selection: $defaultTripType) {
                        ForEach(TripType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }

                Section("Kilometerteller") {
                    HStack {
                        Text("Huidige Tellerstand (km)")
                        Spacer()
                        TextField("Stand", text: $currentOdometer)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle("Voertuig Instellen")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                bluetooth.startScanning()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleren") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Opslaan") {
                        saveVehicle()
                    }
                    .disabled(name.isEmpty || licensePlate.isEmpty)
                }
            }
        }
    }

    private func saveVehicle() {
        let odo = Double(currentOdometer) ?? 0.0
        let v = Vehicle(
            id: vehicleId,
            name: name,
            licensePlate: licensePlate,
            isWorkVehicle: isWorkVehicle,
            bluetoothName: bluetoothName,
            defaultTripType: defaultTripType,
            currentOdometer: odo
        )
        storage.addOrUpdateVehicle(v)
        dismiss()
    }
}
