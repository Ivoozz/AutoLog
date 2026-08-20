import SwiftUI

public struct ActiveTripCardView: View {
    @ObservedObject var engine = TripDetectionEngine.shared
    @ObservedObject var location = LocationManager.shared

    @State private var elapsedTime: String = "00:00"
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 10, height: 10)
                        .scaleEffect(1.2)
                        .shadow(color: .green.opacity(0.8), radius: 6)
                        .animation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: engine.isTripActive)

                    Text("ACTIEVE RIT")
                        .font(.caption)
                        .fontWeight(.heavy)
                        .foregroundColor(.green)
                }

                Spacer()

                Text(elapsedTime)
                    .font(.system(.subheadline, design: .monospaced))
                    .fontWeight(.bold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1))
            }

            HStack(alignment: .bottom, spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: "%.1f", engine.activeDistanceKm))
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.primary, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text("KILOMETER")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if let vehicle = engine.activeVehicle {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(vehicle.name)
                            .font(.headline)
                            .fontWeight(.bold)
                        Text(vehicle.licensePlate)
                            .font(.caption)
                            .fontWeight(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.yellow.opacity(0.35))
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.yellow.opacity(0.6), lineWidth: 1))
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Label {
                    Text(engine.activeStartAddress)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                } icon: {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.red)
                        .shadow(color: .red.opacity(0.6), radius: 4)
                }
            }

            Divider()
                .background(Color.white.opacity(0.2))

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
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [engine.activeTripType.badgeColor, engine.activeTripType.badgeColor.opacity(0.75)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: engine.activeTripType.badgeColor.opacity(0.4), radius: 8, y: 4)
                }

                Button(action: {
                    engine.stopTrip()
                }) {
                    Image(systemName: "stop.fill")
                        .font(.headline)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 18)
                        .background(.ultraThinMaterial)
                        .foregroundColor(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.red.opacity(0.5), lineWidth: 1.2))
                }
            }
        }
        .padding(20)
        .liquidGlass(cornerRadius: 26, borderOpacity: 0.45, glowColor: Color.blue.opacity(0.25), glowRadius: 18)
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
