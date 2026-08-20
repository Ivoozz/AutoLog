import SwiftUI

public struct TripListView: View {
    @ObservedObject var storage = StorageManager.shared
    @State private var selectedFilter: TripFilter = .all
    @State private var searchText: String = ""

    enum TripFilter: String, CaseIterable, Identifiable {
        case all = "Alle"
        case workBusiness = "Zakelijk (Werk)"
        case workPrivate = "Privé (Werk)"
        case privatePrivate = "Privé (Auto)"

        var id: String { rawValue }
    }

    private var filteredTrips: [Trip] {
        storage.trips.filter { trip in
            // Filter by type
            let matchesType: Bool
            switch selectedFilter {
            case .all:
                matchesType = true
            case .workBusiness:
                matchesType = trip.tripType == .workBusiness
            case .workPrivate:
                matchesType = trip.tripType == .workPrivate
            case .privatePrivate:
                matchesType = trip.tripType == .privatePrivate
            }

            // Filter by search
            let matchesSearch: Bool
            if searchText.isEmpty {
                matchesSearch = true
            } else {
                let query = searchText.lowercased()
                matchesSearch = trip.startAddress.lowercased().contains(query) ||
                                trip.endAddress.lowercased().contains(query) ||
                                trip.purposeDescription.lowercased().contains(query) ||
                                trip.vehicleName.lowercased().contains(query) ||
                                trip.vehicleLicensePlate.lowercased().contains(query)
            }

            return matchesType && matchesSearch
        }
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(TripFilter.allCases) { filter in
                            Button(action: { selectedFilter = filter }) {
                                Text(filter.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(selectedFilter == filter ? .bold : .medium)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(selectedFilter == filter ? Color.blue : Color(UIColor.secondarySystemGroupedBackground))
                                    .foregroundColor(selectedFilter == filter ? .white : .primary)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                if filteredTrips.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "road.lanes")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("Geen ritten gevonden")
                            .font(.headline)
                        Text("Er zijn geen ritten die voldoen aan de huidige filters.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(filteredTrips) { trip in
                            NavigationLink(destination: TripDetailView(trip: trip)) {
                                tripListRow(trip: trip)
                            }
                        }
                        .onDelete(perform: deleteTrips)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Rittenregistratie")
            .searchable(text: $searchText, prompt: "Zoek op adres, kenteken of doel")
        }
    }

    private func deleteTrips(at offsets: IndexSet) {
        let tripsToDelete = offsets.map { filteredTrips[$0] }
        for trip in tripsToDelete {
            storage.deleteTrip(id: trip.id)
        }
    }

    private func tripListRow(trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(trip.startTime.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(trip.tripType.displayName)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(trip.tripType.badgeColor.opacity(0.15))
                    .foregroundColor(trip.tripType.badgeColor)
                    .cornerRadius(4)
            }

            HStack(alignment: .top, spacing: 8) {
                VStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Rectangle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 2, height: 16)
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                }
                .padding(.top, 4)

                VStack(alignment: .leading, spacing: 4) {
                    Text(trip.startAddress)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Text(trip.endAddress)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.1f km", trip.distanceInKm))
                        .font(.headline)
                        .fontWeight(.heavy)
                    Text(trip.vehicleLicensePlate)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            if !trip.purposeDescription.isEmpty {
                Text("Doel: \(trip.purposeDescription)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
    }
}
