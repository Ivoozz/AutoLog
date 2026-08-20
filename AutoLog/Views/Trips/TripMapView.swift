import SwiftUI
import MapKit

public struct TripMapView: View {
    let trip: Trip

    public var body: some View {
        Map {
            if let start = trip.startCoordinate {
                Marker("Vertrek", coordinate: start.clLocationCoordinate2D)
                    .tint(.green)
            }
            if let end = trip.endCoordinate {
                Marker("Aankomst", coordinate: end.clLocationCoordinate2D)
                    .tint(.red)
            }
            if trip.routePoints.count > 1 {
                MapPolyline(coordinates: trip.routePoints.map { $0.clLocationCoordinate2D })
                    .stroke(.blue, lineWidth: 4)
            }
        }
        .mapStyle(.standard(elevation: .realistic))
    }
}
