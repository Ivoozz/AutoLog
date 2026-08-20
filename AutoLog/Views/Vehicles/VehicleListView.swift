import SwiftUI

public struct VehicleListView: View {
    @ObservedObject var storage = StorageManager.shared
    @State private var showingAddSheet = false
    @State private var vehicleToEdit: Vehicle?

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if storage.vehicles.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "car.2.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.blue.opacity(0.8))
                                    .shadow(color: .blue.opacity(0.4), radius: 10)

                                Text("Geen voertuigen gekoppeld")
                                    .font(.headline)
                                    .fontWeight(.bold)

                                Text("Voeg je werkauto en/of privéauto toe om ritten automatisch te herkennen via CarPlay of Bluetooth.")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)

                                Button(action: { showingAddSheet = true }) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Nieuw Voertuig Toevoegen")
                                            .fontWeight(.bold)
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 20)
                                    .background(
                                        LinearGradient(
                                            colors: [.blue, .cyan],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .shadow(color: .blue.opacity(0.4), radius: 8, y: 3)
                                }
                                .padding(.top, 8)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 36)
                            .liquidGlass(cornerRadius: 24, borderOpacity: 0.35)
                        } else {
                            ForEach(storage.vehicles) { vehicle in
                                Button(action: { vehicleToEdit = vehicle }) {
                                    vehicleRow(vehicle: vehicle)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("💡 Tip voor automatische herkenning")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            Text("Vul bij elk voertuig de exacte Bluetooth- of CarPlay-naam in. Zodra je iPhone verbinding maakt, wordt het juiste profiel automatisch geactiveerd.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(14)
                        .liquidGlass(cornerRadius: 16, borderOpacity: 0.2)
                    }
                    .padding()
                }
            }
            .navigationTitle("Voertuigen")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                            .font(.headline)
                            .fontWeight(.bold)
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

    private func vehicleRow(vehicle: Vehicle) -> some View {
        HStack(spacing: 14) {
            Image(systemName: vehicle.isWorkVehicle ? "briefcase.fill" : "car.fill")
                .font(.title2)
                .foregroundColor(vehicle.isWorkVehicle ? .blue : .green)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(vehicle.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Spacer()
                    Text(vehicle.licensePlate)
                        .font(.caption)
                        .fontWeight(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.yellow.opacity(0.35))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }

                HStack {
                    Label(vehicle.bluetoothName.isEmpty ? "Geen BT gekoppeld" : vehicle.bluetoothName, systemImage: "antenna.radiowaves.left.and.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("Teller: \(String(format: "%.0f km", vehicle.currentOdometer))")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .liquidGlass(cornerRadius: 20, borderOpacity: 0.3)
    }
}
