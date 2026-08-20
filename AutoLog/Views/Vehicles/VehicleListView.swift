import SwiftUI

public struct VehicleListView: View {
    @ObservedObject var storage = StorageManager.shared
    @State private var showingAddSheet = false
    @State private var vehicleToEdit: Vehicle?

    public var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(storage.vehicles) { vehicle in
                        Button(action: { vehicleToEdit = vehicle }) {
                            vehicleRow(vehicle: vehicle)
                        }
                    }
                    .onDelete(perform: deleteVehicle)
                } header: {
                    Text("Gekoppelde Voertuigen")
                } footer: {
                    Text("Stel hier je werkauto en privéauto in. Vul de exacte Bluetooth- of CarPlay-naam in om ritten automatisch aan het juiste voertuig te koppelen.")
                }
            }
            .navigationTitle("Voertuigen")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                EditVehicleView()
            }
            .sheet(item: $vehicleToEdit) { vehicle in
                EditVehicleView(vehicle: vehicle)
            }
        }
    }

    private func deleteVehicle(at offsets: IndexSet) {
        let toDelete = offsets.map { storage.vehicles[$0] }
        for v in toDelete {
            storage.deleteVehicle(id: v.id)
        }
    }

    private func vehicleRow(vehicle: Vehicle) -> some View {
        HStack(spacing: 12) {
            Image(systemName: vehicle.isWorkVehicle ? "briefcase.fill" : "car.fill")
                .font(.title2)
                .foregroundColor(vehicle.isWorkVehicle ? .blue : .green)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(vehicle.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Text(vehicle.licensePlate)
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.yellow.opacity(0.25))
                        .foregroundColor(.primary)
                        .cornerRadius(4)
                }

                HStack {
                    Label(vehicle.bluetoothName.isEmpty ? "Geen BT gekoppeld" : vehicle.bluetoothName, systemImage: "antenna.radiowaves.left.and.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("Teller: \(String(format: "%.0f km", vehicle.currentOdometer))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
