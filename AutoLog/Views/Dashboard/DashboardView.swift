import SwiftUI

public struct DashboardView: View {
    @ObservedObject var engine = TripDetectionEngine.shared
    @ObservedObject var storage = StorageManager.shared
    @ObservedObject var bluetooth = BluetoothManager.shared

    @State private var selectedVehicle: Vehicle?
    @State private var showingManualStartSheet = false

    public init() {}

    private var currentMonthTrips: [Trip] {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let currentMonth = calendar.component(.month, from: Date())
        return storage.trips.filter {
            let y = calendar.component(.year, from: $0.startTime)
            let m = calendar.component(.month, from: $0.startTime)
            return y == currentYear && m == currentMonth
        }
    }

    private var totalMonthKm: Double {
        currentMonthTrips.reduce(0) { $0 + $1.distanceInKm }
    }

    private var workBizKm: Double {
        currentMonthTrips.filter { $0.tripType == .workBusiness }.reduce(0) { $0 + $1.distanceInKm }
    }

    private var workPrivKm: Double {
        currentMonthTrips.filter { $0.tripType == .workPrivate }.reduce(0) { $0 + $1.distanceInKm }
    }

    private var privPrivKm: Double {
        currentMonthTrips.filter { $0.tripType == .privatePrivate }.reduce(0) { $0 + $1.distanceInKm }
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. Active Trip or Standby Status
                    if engine.isTripActive {
                        ActiveTripCardView()
                    } else {
                        standbyCard
                    }

                    // 2. Private Km Limit Alert / Status (500 km regel)
                    privateTaxLimitCard

                    // 3. Monthly Overview Card
                    monthlyOverviewCard

                    // 4. Recent Trips Header & List
                    recentTripsSection
                }
                .padding()
            }
            .navigationTitle("AutoLog Dashboard")
            .background(Color(UIColor.systemGroupedBackground))
            .onAppear {
                if selectedVehicle == nil {
                    selectedVehicle = storage.vehicles.first
                }
            }
        }
    }

    private var standbyCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label {
                    Text(bluetooth.isCarPlayConnected ? "CarPlay Verbonden" : (bluetooth.connectedDeviceName ?? "Stand-by"))
                        .font(.subheadline)
                        .fontWeight(.bold)
                } icon: {
                    Image(systemName: bluetooth.isCarPlayConnected ? "car.badge.gearshape.fill" : "antenna.radiowaves.left.and.right")
                        .foregroundColor(bluetooth.isCarPlayConnected ? .green : .blue)
                }

                Spacer()

                Text("Automatisch")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.12))
                    .foregroundColor(.blue)
                    .cornerRadius(4)
            }

            Text("Ritten worden automatisch gestart zodra je CarPlay of de Bluetooth-verbinding van je auto activeert.")
                .font(.footnote)
                .foregroundColor(.secondary)

            Divider()

            HStack(spacing: 12) {
                Menu {
                    ForEach(storage.vehicles) { vehicle in
                        Button(action: { selectedVehicle = vehicle }) {
                            Text("\(vehicle.name) (\(vehicle.licensePlate))")
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "car.fill")
                        Text(selectedVehicle?.name ?? "Kies auto")
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .font(.subheadline)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(UIColor.tertiarySystemGroupedBackground))
                    .cornerRadius(8)
                }

                Button(action: {
                    if let vehicle = selectedVehicle ?? storage.vehicles.first {
                        engine.startTrip(with: vehicle)
                    }
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Handmatig Starten")
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
    }

    private var privateTaxLimitCard: some View {
        let maxLimit = storage.settings.maxTaxFreePrivateKm
        let ratio = min(1.0, workPrivKm / maxLimit)
        let isWarning = workPrivKm > (maxLimit * 0.8)
        let isExceeded = workPrivKm > maxLimit

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Privé Werkauto (Fiscale 500 km limiet)")
                    .font(.subheadline)
                    .fontWeight(.bold)

                Spacer()

                Text(String(format: "%.1f / %.0f km", workPrivKm, maxLimit))
                    .font(.subheadline)
                    .fontWeight(.heavy)
                    .foregroundColor(isExceeded ? .red : (isWarning ? .orange : .primary))
            }

            ProgressView(value: ratio)
                .tint(isExceeded ? .red : (isWarning ? .orange : .blue))

            HStack {
                Text(isExceeded ? "⚠️ Limiet overschreden! Bijtelling van toepassing." :
                        (isWarning ? "⚡ Let op: je nadert de 500 km grens." : "✅ Binnen veilige marge."))
                    .font(.caption)
                    .foregroundColor(isExceeded ? .red : (isWarning ? .orange : .secondary))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }

    private var monthlyOverviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overzicht Deze Maand")
                .font(.headline)
                .fontWeight(.bold)

            HStack(spacing: 10) {
                statBox(title: "Totaal", value: String(format: "%.1f km", totalMonthKm), color: .blue)
                statBox(title: "Zakelijk Werk", value: String(format: "%.1f km", workBizKm), color: .teal)
                statBox(title: "Privé Auto", value: String(format: "%.1f km", privPrivKm), color: .green)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }

    private func statBox(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.heavy)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }

    private var recentTripsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Recente Ritten")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                NavigationLink(destination: TripListView()) {
                    Text("Alles bekijken")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }

            if storage.trips.isEmpty {
                Text("Nog geen ritten geregistreerd. Zodra je gaat rijden verschijnen ze hier.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 10)
            } else {
                ForEach(storage.trips.prefix(4)) { trip in
                    NavigationLink(destination: TripDetailView(trip: trip)) {
                        tripSummaryRow(trip: trip)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func tripSummaryRow(trip: Trip) -> some View {
        HStack(spacing: 12) {
            Image(systemName: trip.tripType.iconName)
                .foregroundColor(trip.tripType.badgeColor)
                .font(.title3)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(trip.endAddress)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Text("\(trip.startTime.formatted(date: .abbreviated, time: .shortened)) • \(trip.vehicleName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f km", trip.distanceInKm))
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text(trip.tripType.shortLabel)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(trip.tripType.badgeColor.opacity(0.15))
                    .foregroundColor(trip.tripType.badgeColor)
                    .cornerRadius(4)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
}
