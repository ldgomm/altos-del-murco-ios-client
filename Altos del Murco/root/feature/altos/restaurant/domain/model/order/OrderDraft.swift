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
    var userId: String?

    /// Backwards-compatible alias. New code should store the same value as userId.
    var clientId: String?

    /// Legacy/profile/display only. Do not use this for requests, matching, ownership, rewards, or history.
    var nationalId: String?

    var clientName: String
    var tableNumber: String
    var scheduledAt: Date
    var createdAt: Date
    var updatedAt: Date
    var items: [CartItem]
    var revision: Int?
    var lastConfirmedRevision: Int?

    init(
        id: UUID = UUID(),
        userId: String? = nil,
        clientId: String? = nil,
        nationalId: String? = nil,
        clientName: String = "",
        tableNumber: String = "",
        scheduledAt: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        items: [CartItem] = [],
        revision: Int? = nil,
        lastConfirmedRevision: Int? = nil
    ) {
        let cleanUserId = userId?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfBlank

        let cleanClientId = clientId?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfBlank

        self.id = id
        self.userId = cleanUserId ?? cleanClientId
        self.clientId = cleanClientId ?? cleanUserId
        self.nationalId = nationalId
        self.clientName = clientName
        self.tableNumber = tableNumber
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
    var canonicalUserId: String? {
        let cleanUserId = userId?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfBlank

        let cleanClientId = clientId?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfBlank

        return cleanUserId ?? cleanClientId
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

    /// National ID is no longer required.
    var hasValidNationalId: Bool {
        true
    }

    var canSubmit: Bool {
        !isEmpty &&
        hasValidClientName &&
        (hasValidTableNumber || isScheduledForLater)
    }

    func normalizedForSubmit(now: Date = Date()) -> OrderDraft {
        OrderDraft(
            id: id,
            userId: canonicalUserId,
            clientId: canonicalUserId,
            nationalId: nil,
            clientName: clientName,
            tableNumber: tableNumber,
            scheduledAt: OrderScheduleResolver.sanitizedScheduledAt(scheduledAt, now: now),
            createdAt: createdAt,
            updatedAt: now,
            items: items,
            revision: revision,
            lastConfirmedRevision: lastConfirmedRevision
        )
    }

    func toOrder(
        clientId: String? = nil,
        userId: String? = nil,
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

        let cleanInputUserId = userId?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfBlank

        let cleanInputClientId = clientId?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfBlank

        let resolvedUserId = cleanInputUserId ?? cleanInputClientId ?? canonicalUserId

        let cleanClientName = clientName
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let cleanTable = tableNumber
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return Order(
            id: orderId,
            userId: resolvedUserId,
            clientId: resolvedUserId,
            nationalId: nil,
            clientName: cleanClientName,
            tableNumber: cleanTable.isEmpty && resolvedServiceMode == .scheduled ? "Por asignar" : cleanTable,
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

private extension String {
    var nilIfBlank: String? {
        isEmpty ? nil : self
    }
}
