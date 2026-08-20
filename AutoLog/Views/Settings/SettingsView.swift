import SwiftUI

public struct SettingsView: View {
    @ObservedObject var storage = StorageManager.shared
    @State private var recipientEmail: String = ""
    @State private var driverName: String = ""
    @State private var autoExportMonthly: Bool = true
    @State private var resendApiKey: String = ""
    @State private var autoStartOnCarPlay: Bool = true
    @State private var autoStartOnBluetooth: Bool = true
    @State private var minimumTripDistanceMeters: Double = 150.0
    @State private var maxTaxFreePrivateKm: Double = 500.0
    @State private var showingSavedToast = false

    public var body: some View {
        NavigationStack {
            Form {
                Section("Bestuurder & E-mail Rapportage") {
                    TextField("Naam Bestuurder", text: $driverName)
                    TextField("E-mailadres voor PDF Export", text: $recipientEmail)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Toggle("Automatisch maandelijks e-mailen", isOn: $autoExportMonthly)
                }

                Section("Achtergrond E-mail API (Optioneel)") {
                    SecureField("Resend API Sleutel", text: $resendApiKey)
                    Text("Met een Resend API-sleutel (resend.com) kan de app op de 1e van de maand volledig stil op de achtergrond de PDF naar je mail sturen zonder dat je de app hoeft te openen.")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
                        Text("1.0.0 (Build 1)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Status")
                        Spacer()
                        Label("Actief", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("Instellingen")
            .onAppear(perform: loadSettings)
            .onChange(of: driverName) { _ in saveSettings() }
            .onChange(of: recipientEmail) { _ in saveSettings() }
            .onChange(of: autoExportMonthly) { _ in saveSettings() }
            .onChange(of: resendApiKey) { _ in saveSettings() }
            .onChange(of: autoStartOnCarPlay) { _ in saveSettings() }
            .onChange(of: autoStartOnBluetooth) { _ in saveSettings() }
            .onChange(of: minimumTripDistanceMeters) { _ in saveSettings() }
            .onChange(of: maxTaxFreePrivateKm) { _ in saveSettings() }
        }
    }

    private func loadSettings() {
        let s = storage.settings
        driverName = s.driverName
        recipientEmail = s.recipientEmail
        autoExportMonthly = s.autoExportMonthly
        resendApiKey = s.resendApiKey
        autoStartOnCarPlay = s.autoStartOnCarPlay
        autoStartOnBluetooth = s.autoStartOnBluetooth
        minimumTripDistanceMeters = s.minimumTripDistanceMeters
        maxTaxFreePrivateKm = s.maxTaxFreePrivateKm
    }

    private func saveSettings() {
        storage.settings = UserSettings(
            recipientEmail: recipientEmail,
            driverName: driverName,
            autoExportMonthly: autoExportMonthly,
            resendApiKey: resendApiKey,
            autoStartOnCarPlay: autoStartOnCarPlay,
            autoStartOnBluetooth: autoStartOnBluetooth,
            minimumTripDistanceMeters: minimumTripDistanceMeters,
            maxTaxFreePrivateKm: maxTaxFreePrivateKm
        )
        storage.saveSettings()
    }
}
