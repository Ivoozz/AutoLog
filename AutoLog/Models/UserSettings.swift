import Foundation

public struct UserSettings: Codable, Equatable {
    public var recipientEmail: String
    public var driverName: String
    public var autoExportMonthly: Bool
    public var resendApiKey: String
    public var autoStartOnCarPlay: Bool
    public var autoStartOnBluetooth: Bool
    public var minimumTripDistanceMeters: Double
    public var maxTaxFreePrivateKm: Double

    public init(
        recipientEmail: String = "",
        driverName: String = "Ivo",
        autoExportMonthly: Bool = true,
        resendApiKey: String = "",
        autoStartOnCarPlay: Bool = true,
        autoStartOnBluetooth: Bool = true,
        minimumTripDistanceMeters: Double = 150.0,
        maxTaxFreePrivateKm: Double = 500.0
    ) {
        self.recipientEmail = recipientEmail
        self.driverName = driverName
        self.autoExportMonthly = autoExportMonthly
        self.resendApiKey = resendApiKey
        self.autoStartOnCarPlay = autoStartOnCarPlay
        self.autoStartOnBluetooth = autoStartOnBluetooth
        self.minimumTripDistanceMeters = minimumTripDistanceMeters
        self.maxTaxFreePrivateKm = maxTaxFreePrivateKm
    }
}
