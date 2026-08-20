import SwiftUI

public struct DashboardView: View {
    @ObservedObject var engine = TripDetectionEngine.shared
    @ObservedObject var storage = StorageManager.shared
    @ObservedObject var bluetooth = BluetoothManager.shared

    @State private var selectedVehicle: Vehicle?

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
            ZStack {
                LiquidBackground()

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
            }
            .navigationTitle("AutoLog")
            .onAppear {
                if selectedVehicle == nil {
                    selectedVehicle = storage.vehicles.first
                }
            }
        }
    }

    private var standbyCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label {
                    Text(bluetooth.isCarPlayConnected ? "CarPlay Verbonden" : (bluetooth.connectedDeviceName ?? "Stand-by"))
                        .font(.subheadline)
                        .fontWeight(.bold)
                } icon: {
                    Image(systemName: bluetooth.isCarPlayConnected ? "car.badge.gearshape.fill" : "antenna.radiowaves.left.and.right")
                        .foregroundColor(bluetooth.isCarPlayConnected ? .green : .cyan)
                        .shadow(color: (bluetooth.isCarPlayConnected ? Color.green : Color.cyan).opacity(0.6), radius: 6)
                }

                Spacer()

                Text("Automatisch")
                    .font(.caption2)
                    .fontWeight(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1))
            }

            if storage.vehicles.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nog geen voertuig toegevoegd")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("Ga naar het tabblad 'Voertuigen' om je werk- of privéauto in te stellen voor automatische herkenning.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("Ritten worden automatisch gestart zodra CarPlay of de Bluetooth-verbinding van je auto actief wordt.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Divider()
                .background(Color.white.opacity(0.15))

            HStack(spacing: 12) {
                if !storage.vehicles.isEmpty {
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
                        .fontWeight(.semibold)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.25), lineWidth: 1))
                    }

                    Button(action: {
                        if let vehicle = selectedVehicle ?? storage.vehicles.first {
                            engine.startTrip(with: vehicle)
                        }
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Handmatig Starten")
                                .fontWeight(.bold)
                        }
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .shadow(color: Color.blue.opacity(0.35), radius: 8, y: 3)
                    }
                } else {
                    NavigationLink(destination: VehicleListView()) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Voeg Eerste Voertuig Toe")
                                .fontWeight(.bold)
                        }
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
        }
        .padding(20)
        .liquidGlass(cornerRadius: 24, borderOpacity: 0.35)
    }

    private var privateTaxLimitCard: some View {
        let maxLimit = storage.settings.maxTaxFreePrivateKm
        let ratio = min(1.0, workPrivKm / maxLimit)
        let isWarning = workPrivKm > (maxLimit * 0.8)
        let isExceeded = workPrivKm > maxLimit

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Privé Werkauto (500 km norm)")
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
                .scaleEffect(x: 1, y: 1.5, anchor: .center)

            HStack {
                Text(isExceeded ? "⚠️ Limiet overschreden! Bijtelling van toepassing." :
                        (isWarning ? "⚡ Let op: je nadert de 500 km grens." : "✅ Binnen veilige marge."))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isExceeded ? .red : (isWarning ? .orange : .secondary))
            }
        }
        .padding(18)
        .liquidGlass(cornerRadius: 22, borderOpacity: 0.3)
    }

    private var monthlyOverviewCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Overzicht Deze Maand")
                .font(.headline)
                .fontWeight(.bold)

            HStack(spacing: 12) {
                statBox(title: "Totaal", value: String(format: "%.1f km", totalMonthKm), color: .blue)
                statBox(title: "Zakelijk Werk", value: String(format: "%.1f km", workBizKm), color: .cyan)
                statBox(title: "Privé Auto", value: String(format: "%.1f km", privPrivKm), color: .green)
            }
        }
        .padding(18)
        .liquidGlass(cornerRadius: 22, borderOpacity: 0.3)
    }

    private func statBox(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.black)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.3), lineWidth: 1))
    }

    private var recentTripsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recente Ritten")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                NavigationLink(destination: TripListView()) {
                    Text("Alles bekijken")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }

            if storage.trips.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "road.lanes")
                        .font(.title)
                        .foregroundColor(.secondary)
                    Text("Nog geen ritten geregistreerd.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .liquidGlass(cornerRadius: 18, borderOpacity: 0.25)
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
                    .fontWeight(.bold)
                    .lineLimit(1)
                Text("\(trip.startTime.formatted(date: .abbreviated, time: .shortened)) • \(trip.vehicleName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f km", trip.distanceInKm))
                    .font(.subheadline)
                    .fontWeight(.black)
                Text(trip.tripType.shortLabel)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(trip.tripType.badgeColor.opacity(0.2))
                    .foregroundColor(trip.tripType.badgeColor)
                    .clipShape(Capsule())
            }
        }
        .padding(14)
        .liquidGlass(cornerRadius: 16, borderOpacity: 0.25)
    }
}
