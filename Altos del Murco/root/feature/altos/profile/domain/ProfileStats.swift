//
//  ProfileStats.swift
//  Altos del Murco
//
//  Created by José Ruiz on 19/4/26.
//

import Foundation

enum LoyaltyLevel: String, Codable, CaseIterable, Hashable {
    case silver
    case gold
    case diamond

    var title: String { rawValue.capitalized }

    var badgeSubtitle: String {
        switch self {
        case .silver:
            return "Building your rewards history"
        case .gold:
            return "Strong loyalty across experiences"
        case .diamond:
            return "Top guest level"
        }
    }

    static func from(totalSpent: Double) -> LoyaltyLevel {
        switch totalSpent {
        case 0..<200:
            return .silver
        case 200..<800:
            return .gold
        default:
            return .diamond
        }
    }
}
