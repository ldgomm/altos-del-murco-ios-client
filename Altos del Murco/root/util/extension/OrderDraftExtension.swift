//
//  OrderDraft.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

extension OrderDraft {
    func toOrder(orderId: String = UUID().uuidString, status: OrderStatus = .pending) -> Order {
        let orderItems = items.map {
            OrderItem(
                menuItemId: $0.menuItem.id,
                name: $0.menuItem.name,
                unitPrice: $0.unitPrice,
                quantity: $0.quantity,
                notes: $0.notes
            )
        }
        
        return Order(
            id: orderId,
            clientId: clientId,
            clientName: clientName.trimmingCharacters(in: .whitespacesAndNewlines),
            tableNumber: tableNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: createdAt,
            updatedAt: updatedAt,
            items: orderItems,
            subtotal: subtotal,
            totalAmount: totalAmount,
            status: status,
            revision: revision ?? 0,
            lastConfirmedRevision: lastConfirmedRevision
        )
    }
    
    var hasValidClientName: Bool {
        !clientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var hasValidTableNumber: Bool {
        !tableNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var canSubmit: Bool {
        !isEmpty && hasValidClientName && hasValidTableNumber
    }
}

