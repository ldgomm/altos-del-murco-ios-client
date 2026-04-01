//
//  AdventureModels.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import Foundation

enum AdventureActivityType: String, Codable, CaseIterable, Identifiable, Hashable {
    case offRoad
    case paintball
    case goKarts
    case shootingRange
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .offRoad: return "Off-Road"
        case .paintball: return "Paintball"
        case .goKarts: return "Go Karts"
        case .shootingRange: return "Shooting Range"
        }
    }
}

enum AdventurePackageType: String, Codable, CaseIterable, Identifiable, Hashable {
    case singleOffRoad
    case singlePaintball
    case singleGoKarts
    case singleShooting
    case offRoadPlusPaintball
    case fullAdventure
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .singleOffRoad:
            return "Off-Road"
        case .singlePaintball:
            return "Paintball"
        case .singleGoKarts:
            return "Go Karts"
        case .singleShooting:
            return "Shooting Range"
        case .offRoadPlusPaintball:
            return "Off-Road + Paintball"
        case .fullAdventure:
            return "Complete Adventure"
        }
    }
    
    var subtitle: String {
        switch self {
        case .singleOffRoad:
            return "1, 2 or 3 hours"
        case .singlePaintball, .singleGoKarts, .singleShooting:
            return "30 minutes"
        case .offRoadPlusPaintball:
            return "Off-road plus 30 min paintball"
        case .fullAdventure:
            return "Off-road + paintball + go karts + shooting"
        }
    }
    
    var includesOffRoad: Bool {
        switch self {
        case .singleOffRoad, .offRoadPlusPaintball, .fullAdventure:
            return true
        default:
            return false
        }
    }
    
    var activities: [AdventureActivityType] {
        switch self {
        case .singleOffRoad:
            return [.offRoad]
        case .singlePaintball:
            return [.paintball]
        case .singleGoKarts:
            return [.goKarts]
        case .singleShooting:
            return [.shootingRange]
        case .offRoadPlusPaintball:
            return [.offRoad, .paintball]
        case .fullAdventure:
            return [.offRoad, .paintball, .goKarts, .shootingRange]
        }
    }
}

enum AdventureBookingStatus: String, Codable, CaseIterable, Hashable {
    case pending
    case confirmed
    case canceled
    
    var title: String {
        switch self {
        case .pending: return "Pending"
        case .confirmed: return "Confirmed"
        case .canceled: return "Canceled"
        }
    }
}

struct AdventureBookingBlock: Identifiable, Codable, Hashable {
    let id: String
    let activity: AdventureActivityType
    let startAt: Date
    let endAt: Date
    let durationMinutes: Int
    let unitPricePerPerson: Double
}

struct AdventureBooking: Identifiable, Hashable {
    let id: String
    let clientId: String?
    let clientName: String
    let peopleCount: Int
    let dayKey: String
    let packageType: AdventurePackageType
    let offRoadHours: Int
    let totalAmount: Double
    let currency: String
    let status: AdventureBookingStatus
    let createdAt: Date
    let startAt: Date
    let endAt: Date
    let blocks: [AdventureBookingBlock]
    let notes: String?
}

struct AdventureAvailabilitySlot: Identifiable, Hashable {
    let id: String
    let startAt: Date
    let endAt: Date
    let blocks: [AdventureBookingBlock]
    let totalAmount: Double
}

struct AdventureBookingRequest: Hashable {
    let clientId: String?
    let clientName: String
    let peopleCount: Int
    let date: Date
    let packageType: AdventurePackageType
    let offRoadHours: Int
    let selectedStartAt: Date
    let notes: String?
}

struct AdventureBuildPlan: Hashable {
    let day: Date
    let packageType: AdventurePackageType
    let offRoadHours: Int
    let peopleCount: Int
    let startAt: Date
    let endAt: Date
    let blocks: [AdventureBookingBlock]
    let totalAmount: Double
}
