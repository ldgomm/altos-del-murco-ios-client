//
//  OrderStatus.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

enum OrderStatus: String, Codable, Hashable, CaseIterable, Identifiable {
    case pending
    case confirmed
    case preparing
    case readyForPayment
    case paid
    case canceled

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pending: return "Pendiente"
        case .confirmed: return "Confirmado"
        case .preparing: return "En cocina"
        case .readyForPayment: return "Listo para cobrar"
        case .paid: return "Pagado"
        case .canceled: return "Cancelado"
        }
    }

    var clientTitle: String {
        switch self {
        case .pending: return "Pedido enviado"
        case .confirmed: return "Pedido confirmado"
        case .preparing: return "En cocina"
        case .readyForPayment: return "Pedido servido / listo para pagar"
        case .paid: return "Pagado"
        case .canceled: return "Cancelado"
        }
    }

    var isTerminal: Bool {
        self == .paid || self == .canceled
    }

    var countsAsRevenue: Bool {
        self == .paid
    }

    var operationalRank: Int {
        switch self {
        case .preparing: return 2
        case .confirmed: return 3
        case .pending: return 4
        case .readyForPayment: return 1
        case .paid: return 5
        case .canceled: return 6
        }
    }
}
