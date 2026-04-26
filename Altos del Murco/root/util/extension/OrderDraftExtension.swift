//
//  OrderDraft.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

extension OrderDraft {
    var normalizedScheduledAt: Date {
        OrderScheduleResolver.sanitizedScheduledAt(scheduledAt)
    }

    var serviceMode: OrderServiceMode {
        OrderScheduleResolver.mode(createdAt: Date(), scheduledAt: normalizedScheduledAt)
    }

    var isScheduledForLater: Bool {
        serviceMode == .scheduled
    }

    func toOrder(orderId: String = UUID().uuidString, status: OrderStatus = .pending) -> Order {
        let now = Date()
        let resolvedScheduledAt = OrderScheduleResolver.sanitizedScheduledAt(scheduledAt, now: now)
        let resolvedServiceMode = OrderScheduleResolver.mode(createdAt: now, scheduledAt: resolvedScheduledAt)

        let orderItems = items.map {
            OrderItem(
                menuItemId: $0.menuItem.id,
                name: $0.menuItem.name,
                unitPrice: $0.unitPrice,
                quantity: $0.quantity,
                notes: $0.notes
            )
        }

        let cleanTable = tableNumber.trimmingCharacters(in: .whitespacesAndNewlines)

        return Order(
            id: orderId,
            nationalId: nationalId?.trimmingCharacters(in: .whitespacesAndNewlines),
            clientName: clientName.trimmingCharacters(in: .whitespacesAndNewlines),
            tableNumber: cleanTable.isEmpty && resolvedServiceMode == .scheduled ? "Por asignar" : cleanTable,
            createdAt: now,
            updatedAt: now,
            scheduledAt: resolvedScheduledAt,
            scheduledDayKey: OrderScheduleResolver.dayKey(from: resolvedScheduledAt),
            serviceMode: resolvedServiceMode,
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
        !isEmpty && hasValidClientName && (hasValidTableNumber || isScheduledForLater)
    }
}
