//
//  LoyaltyLevel.swift
//  Altos del Murco
//
//  Created by José Ruiz on 19/4/26.
//

import Foundation

enum LoyaltyLevel: String, Codable, CaseIterable, Hashable, Identifiable {
    case bronze
    case silver
    case gold
    case platinum
    case diamond

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bronze: return "Bronce"
        case .silver: return "Plata"
        case .gold: return "Oro"
        case .platinum: return "Platino"
        case .diamond: return "Diamante"
        }
    }

    var systemImage: String {
        switch self {
        case .bronze: return "sparkles"
        case .silver: return "seal.fill"
        case .gold: return "star.circle.fill"
        case .platinum: return "crown.fill"
        case .diamond: return "diamond.fill"
        }
    }

    var badgeSubtitle: String {
        switch self {
        case .bronze: return "Tus primeras visitas ya empiezan a premiarte"
        case .silver: return "Más beneficios cada vez que vuelves"
        case .gold: return "Descuentos más fuertes y regalos más frecuentes"
        case .platinum: return "Nivel preferente con premios premium"
        case .diamond: return "Nuestro máximo nivel para clientes top"
        }
    }

    var minimumSpent: Double {
        switch self {
        case .bronze: return 0
        case .silver: return 100
        case .gold: return 300
        case .platinum: return 800
        case .diamond: return 1500
        }
    }

    var spendRangeText: String {
        switch self {
        case .bronze: return "De $0 a $99"
        case .silver: return "De $100 a $299"
        case .gold: return "De $300 a $799"
        case .platinum: return "De $800 a $1499"
        case .diamond: return "Desde $1500"
        }
    }

    var nextLevel: LoyaltyLevel? {
        switch self {
        case .bronze: return .silver
        case .silver: return .gold
        case .gold: return .platinum
        case .platinum: return .diamond
        case .diamond: return nil
        }
    }

    func remainingSpend(from totalSpent: Double) -> Double {
        guard let nextLevel else { return 0 }
        return max(nextLevel.minimumSpent - totalSpent, 0)
    }

    static func from(totalSpent: Double) -> LoyaltyLevel {
        switch totalSpent {
        case 0..<100: return .bronze
        case 100..<300: return .silver
        case 300..<800: return .gold
        case 800..<1500: return .platinum
        default: return .diamond
        }
    }

    static func progress(for totalSpent: Double) -> Double {
        let current = from(totalSpent: totalSpent)
        guard let next = current.nextLevel else { return 1 }

        let start = current.minimumSpent
        let end = next.minimumSpent
        guard end > start else { return 1 }

        let raw = (totalSpent - start) / (end - start)
        return min(max(raw, 0), 1)
    }
}
