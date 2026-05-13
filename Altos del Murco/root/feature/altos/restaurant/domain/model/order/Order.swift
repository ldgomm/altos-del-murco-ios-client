//
//  Order.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

enum OrderServiceMode: String, Codable, Hashable, CaseIterable, Identifiable {
    case now
    case scheduled

    var id: String { rawValue }

    var title: String {
        switch self {
        case .now:
            return "Pedido inmediato"
        case .scheduled:
            return "Reserva de comida"
        }
    }
}

struct Order: Identifiable, Hashable, Codable {
    let id: String

    /// Firebase Auth UID. Canonical owner field for Firestore security and all user queries.
    let userId: String
    let clientName: String
    let tableNumber: String

    /// Optional contact number used only for scheduled restaurant orders.
    /// Immediate table orders intentionally keep this empty.
    let whatsappNumber: String

    let createdAt: Date
    let updatedAt: Date
    let scheduledAt: Date
    let scheduledDayKey: String
    let serviceMode: OrderServiceMode
    let items: [OrderItem]
    let subtotal: Double
    let loyaltyDiscountAmount: Double
    let appliedRewards: [AppliedReward]
    let totalAmount: Double
    var status: OrderStatus
    let revision: Int
    let lastConfirmedRevision: Int?

    let readyForPaymentAt: Date?
    let paidAt: Date?
    let paymentMethod: String?
    let paymentReference: String?
    let paidByAdminId: String?

    init(
        id: String,
        userId: String,
        clientName: String,
        tableNumber: String,
        whatsappNumber: String = "",
        createdAt: Date,
        updatedAt: Date,
        scheduledAt: Date? = nil,
        scheduledDayKey: String? = nil,
        serviceMode: OrderServiceMode? = nil,
        items: [OrderItem],
        subtotal: Double,
        loyaltyDiscountAmount: Double = 0,
        appliedRewards: [AppliedReward] = [],
        totalAmount: Double,
        status: OrderStatus,
        revision: Int,
        lastConfirmedRevision: Int?,
        readyForPaymentAt: Date? = nil,
        paidAt: Date? = nil,
        paymentMethod: String? = nil,
        paymentReference: String? = nil,
        paidByAdminId: String? = nil
    ) {
        let resolvedScheduledAt = scheduledAt ?? createdAt
        let resolvedMode = serviceMode ?? OrderScheduleResolver.mode(
            createdAt: createdAt,
            scheduledAt: resolvedScheduledAt
        )

        let cleanUserId = userId.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanClientName = clientName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanTableNumber = tableNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanWhatsApp = whatsappNumber.trimmingCharacters(in: .whitespacesAndNewlines)

        self.id = id.trimmingCharacters(in: .whitespacesAndNewlines)
        self.userId = cleanUserId
        self.clientName = cleanClientName.isEmpty ? "Cliente" : cleanClientName
        self.tableNumber = cleanTableNumber
        self.whatsappNumber = resolvedMode == .scheduled ? cleanWhatsApp : ""
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.scheduledAt = resolvedScheduledAt
        self.scheduledDayKey = scheduledDayKey ?? OrderScheduleResolver.dayKey(from: resolvedScheduledAt)
        self.serviceMode = resolvedMode
        self.items = Order.normalizedItemLines(items)
        self.subtotal = max(0, subtotal).roundedMoney
        self.loyaltyDiscountAmount = max(0, loyaltyDiscountAmount).roundedMoney
        self.appliedRewards = appliedRewards
        self.totalAmount = max(0, totalAmount).roundedMoney
        self.status = status
        self.revision = max(0, revision)
        self.lastConfirmedRevision = lastConfirmedRevision
        self.readyForPaymentAt = readyForPaymentAt
        self.paidAt = paidAt
        self.paymentMethod = paymentMethod?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
        self.paymentReference = paymentReference?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
        self.paidByAdminId = paidByAdminId?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
    }

    var totalItems: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    var activeItems: [OrderItem] {
        items.filter { $0.status != .canceled }
    }

    var canceledItems: [OrderItem] {
        items.filter { $0.status == .canceled }
    }

    var readyForDeliveryItems: [OrderItem] {
        activeItems
            .filter { $0.status == .readyForDelivery }
            .sorted { ($0.readyForDeliveryAt ?? $0.createdAt) < ($1.readyForDeliveryAt ?? $1.createdAt) }
    }

    var deliveredItems: [OrderItem] {
        activeItems.filter { $0.status == .delivered }
    }

    var pendingOrPreparingItems: [OrderItem] {
        activeItems.filter { item in
            item.status == .pending || item.status == .preparing
        }
    }

    var hasReadyForDeliveryItems: Bool {
        !readyForDeliveryItems.isEmpty
    }

    var hasLoyaltyRewards: Bool {
        !appliedRewards.isEmpty || loyaltyDiscountAmount > 0
    }

    var requiresReconfirmation: Bool {
        lastConfirmedRevision != revision
    }

    var wasEditedAfterConfirmation: Bool {
        guard let lastConfirmedRevision else { return false }
        return revision > lastConfirmedRevision
    }

    var isScheduledForLater: Bool {
        serviceMode == .scheduled ||
        scheduledAt.timeIntervalSince(createdAt) > OrderScheduleResolver.laterThreshold
    }

    var shouldConsumeCurrentMenuStock: Bool {
        !isScheduledForLater
    }

    var scheduledDateText: String {
        OrderScheduleResolver.displayText(for: scheduledAt)
    }

    var contactDisplayText: String {
        whatsappNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Cliente escribirá por WhatsApp"
            : whatsappNumber
    }

    var newestReadyForDeliveryAt: Date? {
        readyForDeliveryItems.compactMap(\.readyForDeliveryAt).max()
    }

    var operationalReferenceDate: Date {
        newestReadyForDeliveryAt ?? readyForPaymentAt ?? updatedAt
    }

    func withUserId(_ uid: String) -> Order {
        replacing(userId: uid)
    }

    /// Compatibility helper for older call sites that used `clientId` wording.
    /// The stored value is still the Firebase Auth UID.
    func withClientId(_ uid: String) -> Order {
        withUserId(uid)
    }

    func withTrustedPricing(
        items trustedItems: [OrderItem],
        appliedRewards: [AppliedReward],
        discount: Double
    ) -> Order {
        let normalizedItems = Order.normalizedItemLines(trustedItems)
        let trustedSubtotal = normalizedItems.reduce(0) { $0 + $1.totalPrice }.roundedMoney
        let safeDiscount = min(max(0, discount), trustedSubtotal).roundedMoney

        return replacing(
            updatedAt: Date(),
            items: normalizedItems,
            subtotal: trustedSubtotal,
            loyaltyDiscountAmount: safeDiscount,
            appliedRewards: appliedRewards,
            totalAmount: max(0, trustedSubtotal - safeDiscount).roundedMoney
        )
    }

    func withLoyalty(
        appliedRewards: [AppliedReward],
        discount: Double
    ) -> Order {
        let safeDiscount = min(max(0, discount), subtotal).roundedMoney

        return replacing(
            updatedAt: Date(),
            loyaltyDiscountAmount: safeDiscount,
            appliedRewards: appliedRewards,
            totalAmount: max(0, subtotal - safeDiscount).roundedMoney
        )
    }

    /// Shared domain status calculation. Use this everywhere.
    func recalculatedStatus() -> OrderStatus {
        if status == .paid { return .paid }
        if status == .canceled { return .canceled }
        if status == .pending { return .pending }

        let activeItems = items.filter { $0.status != .canceled }

        guard !activeItems.isEmpty else {
            return status
        }

        if activeItems.allSatisfy({ $0.status == .delivered }) {
            return .readyForPayment
        }

        if activeItems.contains(where: {
            $0.status == .preparing ||
            $0.status == .readyForDelivery ||
            $0.status == .delivered
        }) {
            return .preparing
        }

        return .confirmed
    }

    func confirming(now: Date = Date()) -> Order {
        guard status == .pending else {
            return replacing(updatedAt: now, status: recalculatedStatus())
        }

        return replacing(
            updatedAt: now,
            status: .confirmed,
            lastConfirmedRevision: revision
        )
    }

    func canceling(reason: String? = nil, now: Date = Date()) -> Order {
        let canceledItems = items.map { item in
            item.status == .canceled
                ? item
                : item.updatingStatus(.canceled, now: now, reason: reason)
        }

        return replacing(
            updatedAt: now,
            items: canceledItems,
            status: .canceled
        )
    }

    func markingPaid(
        paymentMethod: String?,
        paymentReference: String?,
        paidByAdminId: String?,
        now: Date = Date()
    ) -> Order {
        replacing(
            updatedAt: now,
            status: .paid,
            paidAt: now,
            paymentMethod: paymentMethod,
            paymentReference: paymentReference,
            paidByAdminId: paidByAdminId
        )
    }

    func updatingItem(
        itemId: UUID,
        transform: (OrderItem) -> OrderItem,
        now: Date = Date()
    ) -> Order {
        let updatedItems = items.map { item in
            item.id == itemId ? transform(item) : item
        }

        var updated = replacing(
            updatedAt: now,
            items: updatedItems
        )

        let newStatus = updated.recalculatedStatus()
        let readyAt = updated.readyForPaymentAt ?? (newStatus == .readyForPayment ? now : nil)

        updated = updated.replacing(
            status: newStatus,
            readyForPaymentAt: readyAt
        )

        return updated
    }

    func updatingItems(
        _ newItems: [OrderItem],
        subtotal: Double,
        totalAmount: Double,
        now: Date = Date()
    ) -> Order {
        let normalizedItems = Order.normalizedItemLines(newItems)
        var updated = replacing(
            updatedAt: now,
            items: normalizedItems,
            subtotal: subtotal,
            totalAmount: totalAmount,
            revision: revision + 1
        )

        let nextStatus = updated.status == .pending ? .pending : updated.recalculatedStatus()
        updated = updated.replacing(status: nextStatus)
        return updated
    }

    func replacing(
        id: String? = nil,
        userId: String? = nil,
        clientName: String? = nil,
        tableNumber: String? = nil,
        whatsappNumber: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        scheduledAt: Date? = nil,
        scheduledDayKey: String? = nil,
        serviceMode: OrderServiceMode? = nil,
        items: [OrderItem]? = nil,
        subtotal: Double? = nil,
        loyaltyDiscountAmount: Double? = nil,
        appliedRewards: [AppliedReward]? = nil,
        totalAmount: Double? = nil,
        status: OrderStatus? = nil,
        revision: Int? = nil,
        lastConfirmedRevision: Int? = nil,
        readyForPaymentAt: Date? = nil,
        paidAt: Date? = nil,
        paymentMethod: String? = nil,
        paymentReference: String? = nil,
        paidByAdminId: String? = nil
    ) -> Order {
        Order(
            id: id ?? self.id,
            userId: userId ?? self.userId,
            clientName: clientName ?? self.clientName,
            tableNumber: tableNumber ?? self.tableNumber,
            whatsappNumber: whatsappNumber ?? self.whatsappNumber,
            createdAt: createdAt ?? self.createdAt,
            updatedAt: updatedAt ?? self.updatedAt,
            scheduledAt: scheduledAt ?? self.scheduledAt,
            scheduledDayKey: scheduledDayKey ?? self.scheduledDayKey,
            serviceMode: serviceMode ?? self.serviceMode,
            items: items ?? self.items,
            subtotal: subtotal ?? self.subtotal,
            loyaltyDiscountAmount: loyaltyDiscountAmount ?? self.loyaltyDiscountAmount,
            appliedRewards: appliedRewards ?? self.appliedRewards,
            totalAmount: totalAmount ?? self.totalAmount,
            status: status ?? self.status,
            revision: revision ?? self.revision,
            lastConfirmedRevision: lastConfirmedRevision ?? self.lastConfirmedRevision,
            readyForPaymentAt: readyForPaymentAt ?? self.readyForPaymentAt,
            paidAt: paidAt ?? self.paidAt,
            paymentMethod: paymentMethod ?? self.paymentMethod,
            paymentReference: paymentReference ?? self.paymentReference,
            paidByAdminId: paidByAdminId ?? self.paidByAdminId
        )
    }

    private static func normalizedItemLines(_ source: [OrderItem]) -> [OrderItem] {
        source.flatMap { item in
            guard item.quantity > 1 else { return [item] }

            return OrderItem.normalizedUnits(
                sourceCartItemId: item.sourceCartItemId,
                menuItemId: item.menuItemId,
                name: item.name,
                itemDescription: item.itemDescription,
                unitPrice: item.unitPrice,
                quantity: item.quantity,
                notes: item.notes,
                createdAt: item.createdAt
            )
        }
    }
}

enum OrderScheduleResolver {
    static let laterThreshold: TimeInterval = 5 * 60

    static func mode(createdAt: Date, scheduledAt: Date) -> OrderServiceMode {
        scheduledAt.timeIntervalSince(createdAt) > laterThreshold ? .scheduled : .now
    }

    static func sanitizedScheduledAt(_ value: Date, now: Date = Date()) -> Date {
        value < now.addingTimeInterval(-120) ? now : value
    }

    static func dayKey(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func displayText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_EC")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

private extension Optional where Wrapped == String {
    var nilIfBlank: String? {
        guard let value = self?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }
        return value
    }
}

private extension Double {
    var roundedMoney: Double {
        (self * 100).rounded() / 100
    }
}
