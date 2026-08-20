import SwiftUI

public struct TripDetailView: View {
    @ObservedObject var storage = StorageManager.shared
    @Environment(\.dismiss) private var dismiss

    @State var trip: Trip
    @State private var startAddress: String
    @State private var endAddress: String
    @State private var purposeDescription: String
    @State private var selectedTripType: TripType
    @State private var startOdometer: String
    @State private var endOdometer: String
    @State private var showingSaveAlert = false

    public init(trip: Trip) {
        _trip = State(initialValue: trip)
        _startAddress = State(initialValue: trip.startAddress)
        _endAddress = State(initialValue: trip.endAddress)
        _purposeDescription = State(initialValue: trip.purposeDescription)
        _selectedTripType = State(initialValue: trip.tripType)
        _startOdometer = State(initialValue: String(format: "%.0f", trip.startOdometer))
        _endOdometer = State(initialValue: String(format: "%.0f", trip.endOdometer))
    }

    public var body: some View {
        Form {
            // Map Section
            Section {
                TripMapView(trip: trip)
                    .frame(height: 200)
                    .listRowInsets(EdgeInsets())
            }

            // Summary Section
            Section("Ritgegevens") {
                HStack {
                    Text("Afstand")
                    Spacer()
                    Text(String(format: "%.1f km", trip.distanceInKm))
                        .fontWeight(.bold)
                }

                HStack {
                    Text("Duur")
                    Spacer()
                    Text(trip.formattedDuration)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Datum")
                    Spacer()
                    Text(trip.startTime.formatted(date: .long, time: .shortened))
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Voertuig")
                    Spacer()
                    Text("\(trip.vehicleName) (\(trip.vehicleLicensePlate))")
                        .foregroundColor(.secondary)
                }
            }

            // Classification Section
            Section("Fiscale Classificatie") {
                Picker("Type Rit", selection: $selectedTripType) {
                    ForEach(TripType.allCases) { type in
                        Label(type.displayName, systemImage: type.iconName)
                            .tag(type)
                    }
                }

                TextField("Doel van de rit (bijv. Klantbezoek)", text: $purposeDescription)
            }

            // Addresses Section
            Section("Locaties") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Vertrekadres")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("Startadres", text: $startAddress)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Aankomstadres")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("Eindadres", text: $endAddress)
                }
            }

            // Odometer Section
            Section("Kilometerteller Standen") {
                HStack {
                    Text("Beginstand")
                    Spacer()
                    TextField("Begin", text: $startOdometer)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }

                HStack {
                    Text("Eindstand")
                    Spacer()
                    TextField("Eind", text: $endOdometer)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .navigationTitle("Rit Details")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Opslaan") {
                    saveChanges()
                }
            }
        }
        .alert("Opgeslagen", isPresented: $showingSaveAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text("De ritgegevens zijn succesvol bijgewerkt.")
        }
    }

    private func saveChanges() {
        var updated = trip
        updated.startAddress = startAddress
        updated.endAddress = endAddress
        updated.purposeDescription = purposeDescription
        updated.tripType = selectedTripType
        if let sOdo = Double(startOdometer) { updated.startOdometer = sOdo }
        if let eOdo = Double(endOdometer) { updated.endOdometer = eOdo }

        storage.updateTrip(updated)
        showingSaveAlert = true
    }
}
