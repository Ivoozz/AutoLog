import SwiftUI

public struct MainTabView: View {
    public init() {}

    public var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }

            TripListView()
                .tabItem {
                    Label("Ritten", systemImage: "list.bullet.rectangle.portrait.fill")
                }

            VehicleListView()
                .tabItem {
                    Label("Voertuigen", systemImage: "car.2.fill")
                }

            MonthlyReportView()
                .tabItem {
                    Label("Rapporten", systemImage: "doc.text.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Instellingen", systemImage: "gearshape.fill")
                }
        }
    }
}
