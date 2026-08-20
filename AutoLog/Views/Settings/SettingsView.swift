import SwiftUI
import CoreLocation

public struct SettingsView: View {
    @ObservedObject var storage = StorageManager.shared
    @ObservedObject var locationManager = LocationManager.shared

    @State private var recipientEmail: String = ""
    @State private var driverName: String = ""
    @State private var autoExportMonthly: Bool = true
    @State private var gmailAddress: String = ""
    @State private var gmailAppPassword: String = ""
    @State private var sendViaGmailSmtp: Bool = false
    @State private var autoStartOnCarPlay: Bool = true
    @State private var autoStartOnBluetooth: Bool = true
    @State private var minimumTripDistanceMeters: Double = 150.0
    @State private var maxTaxFreePrivateKm: Double = 500.0

    // Saved Addresses
    @State private var homeAddress: String = ""
    @State private var workAddress: String = ""
    @State private var isGeocodingHome = false
    @State private var isGeocodingWork = false
    @State private var homeGeocodedSuccess = false
    @State private var workGeocodedSuccess = false

    public var body: some View {
        NavigationStack {
            Form {
                Section("Vaste Adressen (Woon-werk Herkenning)") {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Woonadres (Thuis)", systemImage: "house.fill")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)

                        TextField("Bijv. Kerkstraat 1, 1000AA Amsterdam", text: $homeAddress)
                            .textFieldStyle(.roundedBorder)

                        HStack {
                            Button(action: useCurrentLocationForHome) {
                                Label("GPS Opslaan", systemImage: "location.fill")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)

                            Spacer()

                            Button(action: geocodeHome) {
                                if isGeocodingHome {
                                    ProgressView().scaleEffect(0.8)
                                } else {
                                    Text("Valideer")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }

                        if homeGeocodedSuccess {
                            Text("✅ Woonlocatie gekoppeld aan GPS")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Werkadres (Kantoor / Zaak)", systemImage: "building.2.fill")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.indigo)

                        TextField("Bijv. Industrieweg 10, 3000BB Rotterdam", text: $workAddress)
                            .textFieldStyle(.roundedBorder)

                        HStack {
                            Button(action: useCurrentLocationForWork) {
                                Label("GPS Opslaan", systemImage: "location.fill")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)

                            Spacer()

                            Button(action: geocodeWork) {
                                if isGeocodingWork {
                                    ProgressView().scaleEffect(0.8)
                                } else {
                                    Text("Valideer")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }

                        if workGeocodedSuccess {
                            Text("✅ Werklocatie gekoppeld aan GPS")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.vertical, 4)

                    Text("Ritten tussen je woon- en werkadres worden automatisch gelabeld als 'Woon-werkverkeer'.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("Bestuurder & E-mail Rapportage") {
                    TextField("Naam Bestuurder", text: $driverName)
                    TextField("Ontvangend e-mailadres voor PDF", text: $recipientEmail)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Toggle("Automatisch maandelijks e-mailen", isOn: $autoExportMonthly)
                }

                Section("Gmail Koppeling (Voor automatische verzending)") {
                    Toggle("Verzend direct via eigen Gmail", isOn: $sendViaGmailSmtp)

                    if sendViaGmailSmtp {
                        TextField("Jouw Gmail-adres (bijv. ivo@gmail.com)", text: $gmailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        SecureField("Google App-wachtwoord (16 tekens)", text: $gmailAppPassword)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        Text("💡 Tip: Maak een veilig App-wachtwoord aan via myaccount.google.com/apppasswords. Zo kan de app op de 1e van de maand stil de PDF naar je mailen.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Section("Automatische Detectie") {
                    Toggle("Automatisch starten bij CarPlay", isOn: $autoStartOnCarPlay)
                    Toggle("Automatisch starten bij Bluetooth Auto", isOn: $autoStartOnBluetooth)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Minimale ritafstand")
                            Spacer()
                            Text(String(format: "%.0f meter", minimumTripDistanceMeters))
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $minimumTripDistanceMeters, in: 50...500, step: 25)
                    }
                }

                Section("Belastingdienst Richtlijnen") {
                    HStack {
                        Text("Privé Kilometers Werkauto Norm")
                        Spacer()
                        Text(String(format: "%.0f km / jr", maxTaxFreePrivateKm))
                            .fontWeight(.bold)
                    }
                    Text("In Nederland geldt maximaal 500 privékilometers per kalenderjaar in een zakelijke lease- of werkauto om bijtelling te voorkomen.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("Over AutoLog") {
                    HStack {
                        Text("Versie")
                        Spacer()
                        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.6.0"
                        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "7"
                        Text("\(appVersion) (Build \(buildNumber))")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Design")
                        Spacer()
                        Text("iOS 26+ Liquid Glass")
                            .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("Instellingen")
            .onAppear(perform: loadSettings)
            .onChange(of: driverName) { saveSettings() }
            .onChange(of: recipientEmail) { saveSettings() }
            .onChange(of: autoExportMonthly) { saveSettings() }
            .onChange(of: gmailAddress) { saveSettings() }
            .onChange(of: gmailAppPassword) { saveSettings() }
            .onChange(of: sendViaGmailSmtp) { saveSettings() }
            .onChange(of: autoStartOnCarPlay) { saveSettings() }
            .onChange(of: autoStartOnBluetooth) { saveSettings() }
            .onChange(of: minimumTripDistanceMeters) { saveSettings() }
            .onChange(of: maxTaxFreePrivateKm) { saveSettings() }
        }
    }

    private func loadSettings() {
        let s = storage.settings
        driverName = s.driverName
        recipientEmail = s.recipientEmail
        autoExportMonthly = s.autoExportMonthly
        gmailAddress = s.gmailAddress
        gmailAppPassword = s.gmailAppPassword
        sendViaGmailSmtp = s.sendViaGmailSmtp
        autoStartOnCarPlay = s.autoStartOnCarPlay
        autoStartOnBluetooth = s.autoStartOnBluetooth
        minimumTripDistanceMeters = s.minimumTripDistanceMeters
        maxTaxFreePrivateKm = s.maxTaxFreePrivateKm

        if let home = storage.savedLocations.first(where: { $0.category == .home }) {
            homeAddress = home.address
            homeGeocodedSuccess = (home.latitude != 0.0)
        }
        if let work = storage.savedLocations.first(where: { $0.category == .work }) {
            workAddress = work.address
            workGeocodedSuccess = (work.latitude != 0.0)
        }
    }

    private func saveSettings() {
        storage.settings = UserSettings(
            recipientEmail: recipientEmail,
            driverName: driverName,
            autoExportMonthly: autoExportMonthly,
            gmailAddress: gmailAddress,
            gmailAppPassword: gmailAppPassword,
            sendViaGmailSmtp: sendViaGmailSmtp,
            autoStartOnCarPlay: autoStartOnCarPlay,
            autoStartOnBluetooth: autoStartOnBluetooth,
            minimumTripDistanceMeters: minimumTripDistanceMeters,
            maxTaxFreePrivateKm: maxTaxFreePrivateKm
        )
        storage.saveSettings()
    }

    private func geocodeHome() {
        guard !homeAddress.isEmpty else { return }
        isGeocodingHome = true
        Task {
            if let coord = await GeocodingService.shared.geocodeAddress(homeAddress) {
                var home = storage.savedLocations.first(where: { $0.category == .home }) ?? SavedLocation(name: "Thuis", address: homeAddress, category: .home)
                home.address = homeAddress
                home.latitude = coord.latitude
                home.longitude = coord.longitude
                DispatchQueue.main.async {
                    storage.addOrUpdateLocation(home)
                    isGeocodingHome = false
                    homeGeocodedSuccess = true
                }
            } else {
                DispatchQueue.main.async {
                    isGeocodingHome = false
                    homeGeocodedSuccess = false
                }
            }
        }
    }

    private func useCurrentLocationForHome() {
        guard let loc = locationManager.currentLocation else { return }
        Task {
            let addr = await GeocodingService.shared.reverseGeocode(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude)
            var home = storage.savedLocations.first(where: { $0.category == .home }) ?? SavedLocation(name: "Thuis", address: addr, category: .home)
            home.address = addr
            home.latitude = loc.coordinate.latitude
            home.longitude = loc.coordinate.longitude
            DispatchQueue.main.async {
                self.homeAddress = addr
                self.storage.addOrUpdateLocation(home)
                self.homeGeocodedSuccess = true
            }
        }
    }

    private func geocodeWork() {
        guard !workAddress.isEmpty else { return }
        isGeocodingWork = true
        Task {
            if let coord = await GeocodingService.shared.geocodeAddress(workAddress) {
                var work = storage.savedLocations.first(where: { $0.category == .work }) ?? SavedLocation(name: "Kantoor / Werk", address: workAddress, category: .work)
                work.address = workAddress
                work.latitude = coord.latitude
                work.longitude = coord.longitude
                DispatchQueue.main.async {
                    storage.addOrUpdateLocation(work)
                    isGeocodingWork = false
                    workGeocodedSuccess = true
                }
            } else {
                DispatchQueue.main.async {
                    isGeocodingWork = false
                    workGeocodedSuccess = false
                }
            }
        }
    }

    private func useCurrentLocationForWork() {
        guard let loc = locationManager.currentLocation else { return }
        Task {
            let addr = await GeocodingService.shared.reverseGeocode(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude)
            var work = storage.savedLocations.first(where: { $0.category == .work }) ?? SavedLocation(name: "Kantoor / Werk", address: addr, category: .work)
            work.address = addr
            work.latitude = loc.coordinate.latitude
            work.longitude = loc.coordinate.longitude
            DispatchQueue.main.async {
                self.workAddress = addr
                self.storage.addOrUpdateLocation(work)
                self.workGeocodedSuccess = true
            }
        }
    }
}
