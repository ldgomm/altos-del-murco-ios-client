//
//  OrderItemStatus.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/5/26.
//

import Foundation

enum OrderItemStatus: String, Codable, Hashable, CaseIterable, Identifiable {
    case pending
    case preparing
    case readyForDelivery
    case delivered
    case canceled

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pending: return "Pendiente"
        case .preparing: return "Preparando"
        case .readyForDelivery: return "Listo"
        case .delivered: return "Servido"
        case .canceled: return "Cancelado"
        }
    }

    var clientTitle: String {
        switch self {
        case .pending: return "En espera"
        case .preparing: return "Preparando"
        case .readyForDelivery: return "Listo"
        case .delivered: return "Servido"
        case .canceled: return "Cancelado"
        }
    }

    var isActive: Bool {
        self != .canceled
    }

    var hasStarted: Bool {
        switch self {
        case .preparing, .readyForDelivery, .delivered:
            return true
        case .pending, .canceled:
            return false
        }
    }
}
