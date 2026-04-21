//
//  LoyaltyLevel.swift
//  Altos del Murco
//
//  Created by José Ruiz on 19/4/26.
//

import Foundation

enum LoyaltyLevel: String, Codable, CaseIterable, Hashable {
    case bronze
    case silver
    case gold
    case platinum
    case diamond

    var title: String {
        switch self {
        case .bronze: return "Bronce"
        case .silver: return "Plata"
        case .gold: return "Oro"
        case .platinum: return "Platino"
        case .diamond: return "Diamante"
        }
    }

    var badgeSubtitle: String {
        switch self {
        case .bronze:
            return "Tus primeras visitas ya empiezan a premiarte"
        case .silver:
            return "Más beneficios cada vez que vuelves"
        case .gold:
            return "Descuentos más fuertes y regalos más frecuentes"
        case .platinum:
            return "Nivel preferente con premios premium"
        case .diamond:
            return "Nuestro máximo nivel para clientes top"
        }
    }

    var systemImage: String {
        switch self {
        case .bronze:
            return "sparkles"
        case .silver:
            return "seal.fill"
        case .gold:
            return "star.circle.fill"
        case .platinum:
            return "crown.fill"
        case .diamond:
            return "diamond.fill"
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
        case .bronze:
            return "De $0 a $99"
        case .silver:
            return "De $100 a $299"
        case .gold:
            return "De $400 a $799"
        case .platinum:
            return "De $800 a $1499"
        case .diamond:
            return "Desde $1500"
        }
    }

    var benefits: [LoyaltyBenefit] {
        switch self {
        case .bronze:
            return [
                LoyaltyBenefit(
                    id: "bronze_jugo_discount",
                    title: "5% de descuento",
                    detail: "Válido en jugo natural personal",
                    kind: .percentageDiscount(5),
                    productName: "Jugo natural personal",
                    requiredVisits: nil
                ),
                LoyaltyBenefit(
                    id: "bronze_coffee_free",
                    title: "Café gratis",
                    detail: "1 café americano gratis al completar 3 visitas",
                    kind: .freeProduct,
                    productName: "Café americano",
                    requiredVisits: 3
                )
            ]

        case .silver:
            return [
                LoyaltyBenefit(
                    id: "silver_main_discount",
                    title: "10% de descuento",
                    detail: "En platos fuertes seleccionados",
                    kind: .percentageDiscount(10),
                    productName: "Platos fuertes seleccionados",
                    requiredVisits: nil
                ),
                LoyaltyBenefit(
                    id: "silver_jugo_free",
                    title: "Jugo gratis",
                    detail: "1 jugo natural personal gratis al completar 5 visitas",
                    kind: .freeProduct,
                    productName: "Jugo natural personal",
                    requiredVisits: 5
                )
            ]

        case .gold:
            return [
                LoyaltyBenefit(
                    id: "gold_parrillada_discount",
                    title: "12% de descuento",
                    detail: "En platos fuertes y parrilladas seleccionadas",
                    kind: .percentageDiscount(12),
                    productName: "Platos fuertes y parrilladas seleccionadas",
                    requiredVisits: nil
                ),
                LoyaltyBenefit(
                    id: "gold_dessert_free",
                    title: "Postre gratis",
                    detail: "1 postre individual gratis cada 6 visitas completadas",
                    kind: .freeProduct,
                    productName: "Postre individual",
                    requiredVisits: 6
                )
            ]

        case .platinum:
            return [
                LoyaltyBenefit(
                    id: "platinum_rest_discount",
                    title: "15% de descuento",
                    detail: "En platos, jugos y postres seleccionados",
                    kind: .percentageDiscount(15),
                    productName: "Platos, jugos y postres seleccionados",
                    requiredVisits: nil
                ),
                LoyaltyBenefit(
                    id: "platinum_drink_free",
                    title: "Bebida gratis",
                    detail: "1 bebida o jugo gratis en visitas elegibles",
                    kind: .freeProduct,
                    productName: "Bebida o jugo",
                    requiredVisits: nil
                )
            ]

        case .diamond:
            return [
                LoyaltyBenefit(
                    id: "diamond_rest_discount",
                    title: "20% de descuento",
                    detail: "En consumo seleccionado de restaurante",
                    kind: .percentageDiscount(20),
                    productName: "Consumo seleccionado",
                    requiredVisits: nil
                ),
                LoyaltyBenefit(
                    id: "diamond_free_item",
                    title: "Producto gratis VIP",
                    detail: "1 plato individual o postre premium gratis en campañas VIP",
                    kind: .freeProduct,
                    productName: "Plato individual o postre premium",
                    requiredVisits: nil
                )
            ]
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
        case 0..<99:
            return .bronze
        case 100..<299:
            return .silver
        case 300..<799:
            return .gold
        case 800..<1500:
            return .platinum
        default:
            return .diamond
        }
    }

    static func progress(for totalSpent: Double) -> Double {
        let current = from(totalSpent: totalSpent)

        guard let next = current.nextLevel else {
            return 1
        }

        let start = current.minimumSpent
        let end = next.minimumSpent
        guard end > start else { return 1 }

        let raw = (totalSpent - start) / (end - start)
        return min(max(raw, 0), 1)
    }
    
    
}

struct LoyaltyBenefit: Codable, Hashable, Identifiable {
    let id: String
    let title: String
    let detail: String
    let kind: LoyaltyRewardKind
    let productName: String?
    let requiredVisits: Int?
}

enum LoyaltyRewardKind: Codable, Hashable {
    case percentageDiscount(Double)
    case freeProduct
    case campaignReward
}
