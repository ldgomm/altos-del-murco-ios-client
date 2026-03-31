//
//  OrderStatusExtension.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import SwiftUI

extension OrderStatus {
    var badgeColor: Color {
        switch self {
        case .pending: return .orange
        case .confirmed: return .blue
        case .preparing: return .purple
        case .completed: return .gray
        case .canceled: return .red
        }
    }
}
