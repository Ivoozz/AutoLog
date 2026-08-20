import Foundation

public struct UserSettings: Codable, Equatable {
    public var recipientEmail: String
    public var driverName: String
    public var autoExportMonthly: Bool
    public var gmailAddress: String
    public var gmailAppPassword: String
    public var sendViaGmailSmtp: Bool
    public var autoStartOnCarPlay: Bool
    public var autoStartOnBluetooth: Bool
    public var minimumTripDistanceMeters: Double
    public var maxTaxFreePrivateKm: Double

    public init(
        recipientEmail: String = "",
        driverName: String = "",
        autoExportMonthly: Bool = true,
        gmailAddress: String = "",
        gmailAppPassword: String = "",
        sendViaGmailSmtp: Bool = false,
        autoStartOnCarPlay: Bool = true,
        autoStartOnBluetooth: Bool = true,
        minimumTripDistanceMeters: Double = 150.0,
        maxTaxFreePrivateKm: Double = 500.0
    ) {
        self.recipientEmail = recipientEmail
        self.driverName = driverName
        self.autoExportMonthly = autoExportMonthly
        self.gmailAddress = gmailAddress
        self.gmailAppPassword = gmailAppPassword
        self.sendViaGmailSmtp = sendViaGmailSmtp
        self.autoStartOnCarPlay = autoStartOnCarPlay
        self.autoStartOnBluetooth = autoStartOnBluetooth
        self.minimumTripDistanceMeters = minimumTripDistanceMeters
        self.maxTaxFreePrivateKm = maxTaxFreePrivateKm
    }
}
