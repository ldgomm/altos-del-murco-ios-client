//
//  OrderStatus.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

enum OrderStatus: String, Codable, Hashable, CaseIterable {
    case pending
    case confirmed
    case preparing
    case completed
    case canceled

    var title: String {
        switch self {
        case .pending: return "Pending"
        case .confirmed: return "Confirmed"
        case .preparing: return "Preparing"
        case .completed: return "Completed"
        case .canceled: return "Canceled"
        }
    }
}
