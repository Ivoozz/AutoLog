import Foundation
import AppIntents

public struct StartTripIntent: AppIntent {
    public static var title: LocalizedStringResource = "Start Rittenregistratie"
    public static var description = IntentDescription("Start direct een actieve ritregistratie voor je verbonden auto.")

    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let engine = TripDetectionEngine.shared
        let storage = StorageManager.shared

        if let vehicle = storage.vehicles.first {
            await MainActor.run {
                engine.startTrip(with: vehicle)
            }
            return .result(dialog: "Ritregistratie gestart voor \(vehicle.name).")
        } else {
            return .result(dialog: "Geen voertuig gevonden in AutoLog.")
        }
    }
}

public struct StopTripIntent: AppIntent {
    public static var title: LocalizedStringResource = "Stop Rittenregistratie"
    public static var description = IntentDescription("Beëindig de huidige actieve rit en sla de gegevens op.")

    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let engine = TripDetectionEngine.shared
        await MainActor.run {
            engine.stopTrip()
        }
        return .result(dialog: "Rit succesvol afgerond en opgeslagen.")
    }
}

public struct SwitchTripTypeIntent: AppIntent {
    public static var title: LocalizedStringResource = "Wissel Zakelijk / Privé"
    public static var description = IntentDescription("Wissel het type van de huidige actieve rit tussen Zakelijk en Privé.")

    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let engine = TripDetectionEngine.shared
        await MainActor.run {
            engine.toggleTripType()
        }
        return .result(dialog: "Rittype gewijzigd naar \(engine.activeTripType.displayName).")
    }
}

public struct AutoLogShortcuts: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartTripIntent(),
            phrases: [
                "Start rit in \(.applicationName)",
                "Begin rittenregistratie in \(.applicationName)"
            ],
            shortTitle: "Start Rit",
            systemImageName: "play.circle.fill"
        )
        AppShortcut(
            intent: StopTripIntent(),
            phrases: [
                "Stop rit in \(.applicationName)",
                "Beëindig rittenregistratie in \(.applicationName)"
            ],
            shortTitle: "Stop Rit",
            systemImageName: "stop.circle.fill"
        )
    }
}
