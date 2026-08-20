import Foundation
import SwiftUI

public enum TripType: String, Codable, CaseIterable, Identifiable {
    case workBusiness = "work_business"
    case workPrivate = "work_private"
    case privatePrivate = "private_private"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .workBusiness:
            return "Zakelijk (Werkauto)"
        case .workPrivate:
            return "Privé (Werkauto)"
        case .privatePrivate:
            return "Privé (Privéauto)"
        }
    }

    public var shortLabel: String {
        switch self {
        case .workBusiness:
            return "Zakelijk"
        case .workPrivate:
            return "Privé (Werk)"
        case .privatePrivate:
            return "Privé"
        }
    }

    public var isBusiness: Bool {
        return self == .workBusiness
    }

    public var isWorkVehicle: Bool {
        return self == .workBusiness || self == .workPrivate
    }

    public var iconName: String {
        switch self {
        case .workBusiness:
            return "briefcase.fill"
        case .workPrivate:
            return "car.side.fill"
        case .privatePrivate:
            return "house.fill"
        }
    }

    public var badgeColor: Color {
        switch self {
        case .workBusiness:
            return .blue
        case .workPrivate:
            return .orange
        case .privatePrivate:
            return .green
        }
    }
}
