import SwiftUI

public enum TabItem: Int, CaseIterable, Identifiable {
    case dashboard = 0
    case trips
    case vehicles
    case reports
    case settings

    public var id: Int { rawValue }

    public var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .trips: return "Ritten"
        case .vehicles: return "Voertuigen"
        case .reports: return "Rapporten"
        case .settings: return "Instellingen"
        }
    }

    public var iconName: String {
        switch self {
        case .dashboard: return "house.fill"
        case .trips: return "list.bullet.rectangle.portrait.fill"
        case .vehicles: return "car.2.fill"
        case .reports: return "doc.text.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

public struct LiquidGlassTabBar: View {
    @Binding var selectedTab: TabItem
    @Namespace private var tabAnimation

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases) { tab in
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 4) {
                        ZStack {
                            if selectedTab == tab {
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue, Color.cyan],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 44, height: 30)
                                    .matchedGeometryEffect(id: "liquid_tab_pill", in: tabAnimation)
                                    .shadow(color: Color.blue.opacity(0.45), radius: 8, y: 3)
                            }

                            Image(systemName: tab.iconName)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(selectedTab == tab ? .white : .secondary)
                        }
                        .frame(height: 32)

                        Text(tab.title)
                            .font(.system(size: 9.5, weight: selectedTab == tab ? .bold : .medium, design: .rounded))
                            .foregroundColor(selectedTab == tab ? .primary : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .liquidGlass(cornerRadius: 30, borderOpacity: 0.45, glowColor: Color.blue.opacity(0.25), glowRadius: 16)
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }
}

public struct MainTabView: View {
    @State private var selectedTab: TabItem = .dashboard

    public init() {}

    public var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .dashboard:
                    DashboardView()
                case .trips:
                    TripListView()
                case .vehicles:
                    VehicleListView()
                case .reports:
                    MonthlyReportView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 74)
            }

            // Floating Liquid Glass Tab Bar
            LiquidGlassTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}
