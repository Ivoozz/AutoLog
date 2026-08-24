import ActivityKit
import WidgetKit
import SwiftUI

public struct AutoLogLiveActivity: Widget {
    public init() {}

    public var body: some WidgetConfiguration {
        ActivityConfiguration(for: AutoLogActivityAttributes.self) { context in
            // Lock Screen / StandBy Live Activity Banner
            lockScreenBanner(context: context)
                .activityBackgroundTint(Color.black.opacity(0.65))
                .activitySystemActionForegroundColor(Color.white)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Dynamic Island
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Image(systemName: "car.fill")
                            .font(.title3)
                            .foregroundColor(context.state.isBusiness ? .blue : .green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.state.vehicleName)
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text(context.state.licensePlate)
                                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.yellow.opacity(0.8))
                                .foregroundColor(.black)
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        }
                    }
                    .padding(.leading, 4)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 3) {
                            Text(String(format: "%.1f", context.state.distanceKm))
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundColor(.cyan)
                                .monospacedDigit()
                            Text("KM")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                        }

                        Text(context.state.startTime, style: .timer)
                            .font(.system(.caption2, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                    }
                    .padding(.trailing, 4)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(.red)
                                .font(.caption2)
                            Text(context.state.startAddress)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(1)
                            Spacer()
                            Text(context.state.tripTypeShortLabel)
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(context.state.isBusiness ? Color.blue.opacity(0.8) : Color.green.opacity(0.8))
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.top, 4)
                }
            } compactLeading: {
                HStack(spacing: 4) {
                    Image(systemName: "car.fill")
                        .foregroundColor(context.state.isBusiness ? .blue : .green)
                        .font(.caption2)
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                }
            } compactTrailing: {
                Text(String(format: "%.1f km", context.state.distanceKm))
                    .font(.system(.caption2, design: .rounded))
                    .fontWeight(.black)
                    .foregroundColor(.cyan)
                    .monospacedDigit()
            } minimal: {
                Image(systemName: "car.fill")
                    .foregroundColor(context.state.isBusiness ? .blue : .green)
                    .font(.caption2)
            }
        }
    }

    @ViewBuilder
    private func lockScreenBanner(context: ActivityViewContext<AutoLogActivityAttributes>) -> some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("AUTOLOG • RIT ACTIEF")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundColor(.green)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text(context.state.startTime, style: .timer)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.12))
                .clipShape(Capsule())
            }

            // Central Metric Row
            HStack(alignment: .bottom, spacing: 16) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", context.state.distanceKm))
                            .font(.system(size: 44, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .monospacedDigit()
                        Text("KM")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundColor(.cyan)
                    }

                    if context.state.currentSpeedKmH > 0 {
                        Text(String(format: "%.0f km/u", context.state.currentSpeedKmH))
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text(context.state.vehicleName)
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text(context.state.tripTypeDisplayName)
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            LinearGradient(
                                colors: context.state.isBusiness ? [Color.blue, Color.cyan] : [Color.green, Color.mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            }

            // Start location footer
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.red)
                    .font(.caption)
                Text("Van: \(context.state.startAddress)")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(1)
                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
                .background(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.15), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.4), Color.white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
        )
    }
}
