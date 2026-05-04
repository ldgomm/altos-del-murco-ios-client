//
//  LoyaltyRewardModels.swift
//  Altos del Murco
//
//  Created by José Ruiz on 21/4/26.
//

import Foundation

enum LoyaltyRewardScope: String, Codable, CaseIterable, Identifiable, Hashable {
    case restaurant
    case adventure
    case both

    var id: String { rawValue }

    var title: String {
        switch self {
        case .restaurant: return "Restaurante"
        case .adventure: return "Aventura"
        case .both: return "Ambos"
        }
    }

    func matchesRestaurant() -> Bool {
        self == .restaurant || self == .both
    }

    func matchesAdventure() -> Bool {
        self == .adventure || self == .both
    }
}

enum LoyaltyRewardTriggerMode: String, Codable, CaseIterable, Identifiable, Hashable {
    case automatic
    case manual

    var id: String { rawValue }
}

enum LoyaltyRewardRuleType: String, Codable, CaseIterable, Identifiable, Hashable {
    case mostExpensiveMenuItemPercentage
    case specificMenuItemPercentage
    case activityPercentage
    case freeMenuItem
    case buyXGetYFree

    var id: String { rawValue }
}

struct LoyaltyRewardRule: Codable, Hashable {
    var type: LoyaltyRewardRuleType
    var percentage: Double?
    var menuItemId: String?
    var activityId: String?
    var quantity: Int?
    var buyQuantity: Int?
    var freeQuantity: Int?
    var repeatable: Bool?

    static func mostExpensiveMenuItemDiscount(_ percentage: Double) -> LoyaltyRewardRule {
        LoyaltyRewardRule(
            type: .mostExpensiveMenuItemPercentage,
            percentage: percentage,
            menuItemId: nil,
            activityId: nil,
            quantity: 1,
            buyQuantity: nil,
            freeQuantity: nil,
            repeatable: nil
        )
    }

    static func specificMenuItemDiscount(
        menuItemId: String,
        percentage: Double,
        quantity: Int = 1
    ) -> LoyaltyRewardRule {
        LoyaltyRewardRule(
            type: .specificMenuItemPercentage,
            percentage: percentage,
            menuItemId: menuItemId,
            activityId: nil,
            quantity: max(1, quantity),
            buyQuantity: nil,
            freeQuantity: nil,
            repeatable: nil
        )
    }

    static func activityDiscount(
        activityId: String,
        percentage: Double
    ) -> LoyaltyRewardRule {
        LoyaltyRewardRule(
            type: .activityPercentage,
            percentage: percentage,
            menuItemId: nil,
            activityId: activityId,
            quantity: 1,
            buyQuantity: nil,
            freeQuantity: nil,
            repeatable: nil
        )
    }

    static func freeMenuItem(
        menuItemId: String,
        quantity: Int = 1
    ) -> LoyaltyRewardRule {
        LoyaltyRewardRule(
            type: .freeMenuItem,
            percentage: nil,
            menuItemId: menuItemId,
            activityId: nil,
            quantity: max(1, quantity),
            buyQuantity: nil,
            freeQuantity: nil,
            repeatable: nil
        )
    }

    static func buyXGetYFree(
        menuItemId: String,
        buyQuantity: Int,
        freeQuantity: Int = 1,
        repeatable: Bool = true
    ) -> LoyaltyRewardRule {
        LoyaltyRewardRule(
            type: .buyXGetYFree,
            percentage: nil,
            menuItemId: menuItemId,
            activityId: nil,
            quantity: nil,
            buyQuantity: max(1, buyQuantity),
            freeQuantity: max(1, freeQuantity),
            repeatable: repeatable
        )
    }
}

struct LoyaltyRewardTemplate: Identifiable, Codable, Hashable {
    let id: String
    var title: String
    var subtitle: String
    var scope: LoyaltyRewardScope
    var minimumLevel: LoyaltyLevel
    var triggerMode: LoyaltyRewardTriggerMode
    var isActive: Bool
    var canStack: Bool
    var priority: Int
    var maxUsesPerClient: Int
    var expiresInDays: Int?
    var rule: LoyaltyRewardRule
    var createdAt: Date
    var updatedAt: Date

    var displaySummary: String {
        switch rule.type {
        case .mostExpensiveMenuItemPercentage:
            return "\(Int(rule.percentage ?? 0))% en el plato elegible más caro"
        case .specificMenuItemPercentage:
            return "\(Int(rule.percentage ?? 0))% en item específico"
        case .activityPercentage:
            return "\(Int(rule.percentage ?? 0))% en actividad específica"
        case .freeMenuItem:
            return "\(max(1, rule.quantity ?? 1)) item(s) gratis"
        case .buyXGetYFree:
            return "Compra \(max(1, rule.buyQuantity ?? 1)) y recibe \(max(1, rule.freeQuantity ?? 1)) gratis"
        }
    }

    func isEligible(for level: LoyaltyLevel) -> Bool {
        level.minimumSpent >= minimumLevel.minimumSpent
    }

    var expirationDate: Date? {
        guard let expiresInDays, expiresInDays > 0 else { return nil }
        return Calendar.current.date(byAdding: .day, value: expiresInDays, to: updatedAt)
    }

    var isExpired: Bool {
        guard let expirationDate else { return false }
        return Date() > expirationDate
    }

    var expirationText: String? {
        guard let expirationDate else { return nil }
        return "Vence \(expirationDate.formatted(date: .abbreviated, time: .omitted))"
    }

    var targetMenuItemId: String? {
        let value = rule.menuItemId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? nil : value
    }

    var targetActivityId: String? {
        let value = rule.activityId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? nil : value
    }
}

enum LoyaltyRewardReferenceType: String, Codable, Hashable {
    case order
    case booking
}

enum LoyaltyWalletEventStatus: String, Codable, CaseIterable, Hashable {
    case reserved
    case consumed
    case released
    case expired
}

struct LoyaltyWalletEvent: Identifiable, Codable, Hashable {
    let id: String
    let templateId: String
    let templateTitle: String
    let referenceType: LoyaltyRewardReferenceType
    let referenceId: String
    let status: LoyaltyWalletEventStatus
    let amount: Double
    let createdAt: Date
    let updatedAt: Date
}

struct AppliedReward: Identifiable, Codable, Hashable {
    let id: String
    let templateId: String
    let title: String
    let amount: Double
    let note: String
    let affectedMenuItemIds: [String]
    let affectedActivityIds: [String]
}

struct RewardWalletSnapshot: Hashable {
    /// Firebase Auth UID. Canonical wallet owner identifier.
    let userId: String

    /// Legacy/display only. Do not use this for Firestore document IDs or queries.
    let nationalId: String?

    let currentLevel: LoyaltyLevel
    let totalSpent: Double
    let points: Int
    let availableTemplates: [LoyaltyRewardTemplate]
    let reservedEvents: [LoyaltyWalletEvent]
    let consumedEvents: [LoyaltyWalletEvent]
    let releasedEvents: [LoyaltyWalletEvent]

    static func empty(nationalId: String) -> RewardWalletSnapshot {
        RewardWalletSnapshot(
            userId: nationalId,
            nationalId: nil,
            currentLevel: .bronze,
            totalSpent: 0,
            points: 0,
            availableTemplates: [],
            reservedEvents: [],
            consumedEvents: [],
            releasedEvents: []
        )
    }

    static func empty(userId: String) -> RewardWalletSnapshot {
        RewardWalletSnapshot(
            userId: userId,
            nationalId: nil,
            currentLevel: .bronze,
            totalSpent: 0,
            points: 0,
            availableTemplates: [],
            reservedEvents: [],
            consumedEvents: [],
            releasedEvents: []
        )
    }
}

struct RewardComputationResult: Hashable {
    let appliedRewards: [AppliedReward]
    let totalDiscount: Double
    let walletSnapshot: RewardWalletSnapshot

    static func empty(wallet: RewardWalletSnapshot) -> RewardComputationResult {
        RewardComputationResult(
            appliedRewards: [],
            totalDiscount: 0,
            walletSnapshot: wallet
        )
    }
}

struct RewardMenuLine: Hashable {
    let menuItemId: String
    let name: String
    let unitPrice: Double
    let quantity: Int
}

struct RewardActivityLine: Hashable {
    let activityId: String
    let title: String
    let linePrice: Double
}
