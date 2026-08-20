import SwiftUI

public struct ActiveTripCardView: View {
    @ObservedObject var engine = TripDetectionEngine.shared
    @ObservedObject var location = LocationManager.shared

    @State private var elapsedTime: String = "00:00"
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 10, height: 10)
                        .scaleEffect(1.2)
                        .animation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: engine.isTripActive)

                    Text("ACTIEVE RIT BEZIG")
                        .font(.caption)
                        .fontWeight(.heavy)
                        .foregroundColor(.green)
                }

                Spacer()

                Text(elapsedTime)
                    .font(.system(.subheadline, design: .monospaced))
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.15))
                    .cornerRadius(6)
            }

            HStack(alignment: .bottom, spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: "%.1f", engine.activeDistanceKm))
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .foregroundColor(.primary)
                    Text("KILOMETER")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if let vehicle = engine.activeVehicle {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(vehicle.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text(vehicle.licensePlate)
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.yellow.opacity(0.25))
                            .foregroundColor(.primary)
                            .cornerRadius(4)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Label {
                    Text(engine.activeStartAddress)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } icon: {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.red)
                }
            }

            Divider()

            // Quick Toggle Type & Stop
            HStack(spacing: 12) {
                Button(action: {
                    engine.toggleTripType()
                }) {
                    HStack {
                        Image(systemName: engine.activeTripType.iconName)
                        Text(engine.activeTripType.displayName)
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(engine.activeTripType.badgeColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }

                Button(action: {
                    engine.stopTrip()
                }) {
                    Image(systemName: "stop.fill")
                        .font(.headline)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(Color.red.opacity(0.15))
                        .foregroundColor(.red)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .onReceive(timer) { _ in
            updateTimer()
        }
    }

    private func updateTimer() {
        guard let start = engine.activeStartTime else { return }
        let diff = Int(Date().timeIntervalSince(start))
        let minutes = (diff / 60)
        let seconds = diff % 60
        elapsedTime = String(format: "%02d:%02d", minutes, seconds)
    }
}
