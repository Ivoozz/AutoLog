import SwiftUI

public struct EditVehicleView: View {
    @ObservedObject var storage = StorageManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var vehicleId: UUID
    @State private var name: String
    @State private var licensePlate: String
    @State private var isWorkVehicle: Bool
    @State private var bluetoothName: String
    @State private var defaultTripType: TripType
    @State private var currentOdometer: String

    public init(vehicle: Vehicle? = nil) {
        if let v = vehicle {
            _vehicleId = State(initialValue: v.id)
            _name = State(initialValue: v.name)
            _licensePlate = State(initialValue: v.licensePlate)
            _isWorkVehicle = State(initialValue: v.isWorkVehicle)
            _bluetoothName = State(initialValue: v.bluetoothName)
            _defaultTripType = State(initialValue: v.defaultTripType)
            _currentOdometer = State(initialValue: String(format: "%.0f", v.currentOdometer))
        } else {
            _vehicleId = State(initialValue: UUID())
            _name = State(initialValue: "")
            _licensePlate = State(initialValue: "")
            _isWorkVehicle = State(initialValue: true)
            _bluetoothName = State(initialValue: "")
            _defaultTripType = State(initialValue: .workBusiness)
            _currentOdometer = State(initialValue: "0")
        }
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Voertuig Informatie") {
                    TextField("Naam (bijv. BMW Werkauto)", text: $name)
                    TextField("Kenteken (bijv. V-123-ZZ)", text: $licensePlate)
                    Toggle("Is dit een zakelijke / werkauto?", isOn: $isWorkVehicle)
                }

                Section("Automatische Herkenning") {
                    TextField("Bluetooth / CarPlay Naam", text: $bluetoothName)
                    Text("Vul hier de naam in zoals deze op je iPhone verschijnt bij Bluetooth of CarPlay (bijv. 'CarPlay', 'BMW 320d'). Zodra verbinding wordt gemaakt, wordt deze auto automatisch geselecteerd.")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
            .navigationTitle("Voertuig Bewerken")
            .navigationBarTitleDisplayMode(.inline)
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
