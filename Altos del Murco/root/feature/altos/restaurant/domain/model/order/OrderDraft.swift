//
//  OrderDraft.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

struct OrderDraft: Identifiable, Hashable {
    let id: UUID

    /// Firebase Auth uid. Canonical owner field.
    var userId: String

    var clientName: String
    var tableNumber: String

    /// Optional contact number used only when this draft becomes a scheduled restaurant order.
    var whatsappNumber: String

    var scheduledAt: Date
    var createdAt: Date
    var updatedAt: Date
    var items: [CartItem]
    var revision: Int?
    var lastConfirmedRevision: Int?

    init(
        id: UUID = UUID(),
        userId: String = currentUserId() ?? "",
        clientName: String = "",
        tableNumber: String = "",
        whatsappNumber: String = "",
        scheduledAt: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        items: [CartItem] = [],
        revision: Int? = nil,
        lastConfirmedRevision: Int? = nil
    ) {
        let cleanUserId = userId.trimmingCharacters(in: .whitespacesAndNewlines)

        self.id = id
        self.userId = cleanUserId
        self.clientName = clientName
        self.tableNumber = tableNumber
        self.whatsappNumber = whatsappNumber
        self.scheduledAt = scheduledAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.items = items
        self.revision = revision
        self.lastConfirmedRevision = lastConfirmedRevision
    }

    var totalItems: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    var subtotal: Double {
        items.reduce(0) { $0 + $1.totalPrice }
    }

    var totalAmount: Double {
        subtotal
    }

    var isEmpty: Bool {
        items.isEmpty
    }
}

extension OrderDraft {
    var canonicalUserId: String {
        userId.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedScheduledAt: Date {
        OrderScheduleResolver.sanitizedScheduledAt(scheduledAt)
    }

    var serviceMode: OrderServiceMode {
        OrderScheduleResolver.mode(
            createdAt: Date(),
            scheduledAt: normalizedScheduledAt
        )
    }

    var isScheduledForLater: Bool {
        serviceMode == .scheduled
    }

    var hasValidClientName: Bool {
        !clientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var hasValidTableNumber: Bool {
        !tableNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// WhatsApp is intentionally not required here.
    /// If the order is scheduled and the number is empty, the UI lets the user send and then opens WhatsApp.
    var canSubmit: Bool {
        !isEmpty &&
        hasValidClientName &&
        (hasValidTableNumber || isScheduledForLater)
    }

    func normalizedForSubmit(now: Date = Date()) -> OrderDraft {
        let resolvedScheduledAt = OrderScheduleResolver.sanitizedScheduledAt(scheduledAt, now: now)
        let resolvedMode = OrderScheduleResolver.mode(createdAt: now, scheduledAt: resolvedScheduledAt)

        return OrderDraft(
            id: id,
            userId: canonicalUserId,
            clientName: clientName.trimmingCharacters(in: .whitespacesAndNewlines),
            tableNumber: tableNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            whatsappNumber: resolvedMode == .scheduled
                ? whatsappNumber.trimmingCharacters(in: .whitespacesAndNewlines)
                : "",
            scheduledAt: resolvedScheduledAt,
            createdAt: createdAt,
            updatedAt: now,
            items: items,
            revision: revision,
            lastConfirmedRevision: lastConfirmedRevision
        )
    }

    func toOrder(
        userId: String = currentUserId() ?? "",
        orderId: String = UUID().uuidString,
        status: OrderStatus = .pending
    ) -> Order {
        let now = Date()

        let resolvedScheduledAt = OrderScheduleResolver.sanitizedScheduledAt(
            scheduledAt,
            now: now
        )

        let resolvedServiceMode = OrderScheduleResolver.mode(
            createdAt: now,
            scheduledAt: resolvedScheduledAt
        )

        let orderItems = items.map { item in
            OrderItem(
                menuItemId: item.menuItem.id,
                name: item.menuItem.name,
                unitPrice: item.unitPrice,
                quantity: item.quantity,
                notes: item.notes
            )
        }

        let cleanInputUserId = userId.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedUserId = cleanInputUserId
        let cleanClientName = clientName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanTable = tableNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanWhatsApp = whatsappNumber.trimmingCharacters(in: .whitespacesAndNewlines)

        return Order(
            id: orderId,
            userId: resolvedUserId,
            clientName: cleanClientName,
            tableNumber: cleanTable.isEmpty && resolvedServiceMode == .scheduled ? "Por asignar" : cleanTable,
            whatsappNumber: resolvedServiceMode == .scheduled ? cleanWhatsApp : "",
            createdAt: now,
            updatedAt: now,
            scheduledAt: resolvedScheduledAt,
            scheduledDayKey: OrderScheduleResolver.dayKey(from: resolvedScheduledAt),
            serviceMode: resolvedServiceMode,
            items: orderItems,
            subtotal: subtotal,
            loyaltyDiscountAmount: 0,
            appliedRewards: [],
            totalAmount: totalAmount,
            status: status,
            revision: revision ?? 0,
            lastConfirmedRevision: lastConfirmedRevision
        )
    }
}
