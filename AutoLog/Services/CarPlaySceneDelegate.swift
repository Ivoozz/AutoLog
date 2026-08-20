import Foundation
import CarPlay
import Combine

public final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    public var interfaceController: CPInterfaceController?
    private var cancellables = Set<AnyCancellable>()

    public func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController
        setupObservers()
        updateCarPlayInterface()
    }

    public func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
        self.interfaceController = nil
        cancellables.removeAll()
    }

    private func setupObservers() {
        let engine = TripDetectionEngine.shared
        let storage = StorageManager.shared

        Publishers.Merge4(
            engine.$isTripActive.map { _ in () },
            engine.$activeTripType.map { _ in () },
            engine.$activeDistanceKm.map { _ in () },
            storage.$trips.map { _ in () }
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.updateCarPlayInterface()
        }
        .store(in: &cancellables)
    }

    private func updateCarPlayInterface() {
        guard let interfaceController = interfaceController else { return }

        let engine = TripDetectionEngine.shared
        let storage = StorageManager.shared

        // Tab 1: Live Status & Quick Action Template
        let statusTemplate = createStatusTemplate(engine: engine, storage: storage)

        // Tab 2: Recent Trips List Template
        let recentTripsTemplate = createRecentTripsTemplate(storage: storage)

        let tabBar = CPTabBarTemplate(templates: [statusTemplate, recentTripsTemplate])
        interfaceController.setRootTemplate(tabBar, animated: false, completion: nil)
    }

    private func createStatusTemplate(engine: TripDetectionEngine, storage: StorageManager) -> CPInformationTemplate {
        var items: [CPInformationItem] = []
        var actions: [CPTextButton] = []

        if engine.isTripActive {
            let typeLabel = engine.activeTripType.displayName
            let vehicleName = engine.activeVehicle?.name ?? "Werkauto"
            let licensePlate = engine.activeVehicle?.licensePlate ?? ""
            let distance = String(format: "%.1f km", engine.activeDistanceKm)
            let startAddr = engine.activeStartAddress

            items = [
                CPInformationItem(title: "Status", detail: "🟢 Rit Actief (\(distance))"),
                CPInformationItem(title: "Type", detail: typeLabel),
                CPInformationItem(title: "Voertuig", detail: "\(vehicleName) [\(licensePlate)]"),
                CPInformationItem(title: "Vertrekpunt", detail: startAddr)
            ]

            // Action 1: Switch between Zakelijk and Privé
            let isCurrentlyBiz = engine.activeTripType == .workBusiness
            let switchTitle = isCurrentlyBiz ? "Wissel naar Privé ➔" : "Wissel naar Zakelijk ➔"

            let switchButton = CPTextButton(title: switchTitle, textStyle: .confirm) { [weak self] _ in
                engine.toggleTripType()
                self?.updateCarPlayInterface()
            }

            // Action 2: Stop Trip
            let stopButton = CPTextButton(title: "Beëindig Rit ⏹", textStyle: .cancel) { [weak self] _ in
                engine.stopTrip()
                self?.updateCarPlayInterface()
            }

            actions = [switchButton, stopButton]
        } else {
            let activeVeh = storage.vehicles.first(where: { $0.isWorkVehicle }) ?? storage.vehicles.first
            let vehicleName = activeVeh?.name ?? "Geen auto"
            let plate = activeVeh?.licensePlate ?? "-"

            // Calculate current month stats
            let calendar = Calendar.current
            let curMonth = calendar.component(.month, from: Date())
            let curYear = calendar.component(.year, from: Date())
            let monthTrips = storage.trips.filter {
                let m = calendar.component(.month, from: $0.startTime)
                let y = calendar.component(.year, from: $0.startTime)
                return m == curMonth && y == curYear
            }
            let privWorkKm = monthTrips.filter { $0.tripType == .workPrivate }.reduce(0) { $0 + $1.distanceInKm }

            items = [
                CPInformationItem(title: "Status", detail: "Stand-by (Wacht op vertrek)"),
                CPInformationItem(title: "Geselecteerd", detail: "\(vehicleName) [\(plate)]"),
                CPInformationItem(title: "Privé Werk (500 km norm)", detail: String(format: "%.1f / 500 km", privWorkKm))
            ]

            let startButton = CPTextButton(title: "Start Rit Handmatig ▶", textStyle: .confirm) { [weak self] _ in
                if let v = activeVeh {
                    engine.startTrip(with: v)
                    self?.updateCarPlayInterface()
                }
            }

            actions = [startButton]
        }

        let template = CPInformationTemplate(
            title: engine.isTripActive ? "AutoLog - Rit Actief" : "AutoLog Dashboard",
            layout: .twoColumn,
            items: items,
            actions: actions
        )
        template.tabTitle = "Dashboard"
        template.tabImage = UIImage(systemName: "car.circle.fill")
        return template
    }

    private func createRecentTripsTemplate(storage: StorageManager) -> CPListTemplate {
        var listItems: [CPListItem] = []

        let df = DateFormatter()
        df.dateFormat = "dd-MM HH:mm"

        for trip in storage.trips.prefix(10) {
            let dateStr = df.string(from: trip.startTime)
            let kmStr = String(format: "%.1f km", trip.distanceInKm)
            let title = "\(trip.startAddress) ➔ \(trip.endAddress)"
            let detail = "\(dateStr) • \(kmStr) • \(trip.tripType.shortLabel)"

            let item = CPListItem(text: title, detailText: detail)
            item.accessoryType = .none
            listItems.append(item)
        }

        let section = CPListSection(items: listItems, header: "Laatste Ritten", sectionIndexTitle: nil)
        let listTemplate = CPListTemplate(title: "Rittenhistorie", sections: [section])
        listTemplate.tabTitle = "Ritten"
        listTemplate.tabImage = UIImage(systemName: "list.bullet.rectangle.fill")
        return listTemplate
    }
}
