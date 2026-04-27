//
//  Order.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

enum OrderServiceMode: String, Codable, Hashable, CaseIterable {
    case now
    case scheduled

    var title: String {
        switch self {
        case .now: return "Pedido inmediato"
        case .scheduled: return "Reserva de comida"
        }
    }
}

struct Order: Identifiable, Hashable, Codable {
    let id: String
    let clientId: String?
    let nationalId: String?
    let clientName: String
    let tableNumber: String
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

    init(
        id: String,
        clientId: String? = nil,
        nationalId: String?,
        clientName: String,
        tableNumber: String,
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
        lastConfirmedRevision: Int?
    ) {
        let resolvedScheduledAt = scheduledAt ?? createdAt
        let resolvedMode = serviceMode ?? OrderScheduleResolver.mode(
            createdAt: createdAt,
            scheduledAt: resolvedScheduledAt
        )

        self.id = id
        self.clientId = clientId?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.nationalId = nationalId?.filter(\.isNumber)
        self.clientName = clientName
        self.tableNumber = tableNumber
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.scheduledAt = resolvedScheduledAt
        self.scheduledDayKey = scheduledDayKey ?? OrderScheduleResolver.dayKey(from: resolvedScheduledAt)
        self.serviceMode = resolvedMode
        self.items = items
        self.subtotal = max(0, subtotal)
        self.loyaltyDiscountAmount = max(0, loyaltyDiscountAmount)
        self.appliedRewards = appliedRewards
        self.totalAmount = max(0, totalAmount)
        self.status = status
        self.revision = revision
        self.lastConfirmedRevision = lastConfirmedRevision
    }

    func withClientId(_ uid: String) -> Order {
        Order(
            id: id,
            clientId: uid,
            nationalId: nationalId,
            clientName: clientName,
            tableNumber: tableNumber,
            createdAt: createdAt,
            updatedAt: updatedAt,
            scheduledAt: scheduledAt,
            scheduledDayKey: scheduledDayKey,
            serviceMode: serviceMode,
            items: items,
            subtotal: subtotal,
            loyaltyDiscountAmount: loyaltyDiscountAmount,
            appliedRewards: appliedRewards,
            totalAmount: totalAmount,
            status: status,
            revision: revision,
            lastConfirmedRevision: lastConfirmedRevision
        )
    }

    func withTrustedPricing(
        items trustedItems: [OrderItem],
        appliedRewards: [AppliedReward],
        discount: Double
    ) -> Order {
        let trustedSubtotal = trustedItems.reduce(0) { $0 + $1.totalPrice }.roundedMoney
        let safeDiscount = min(max(0, discount), trustedSubtotal).roundedMoney

        return Order(
            id: id,
            clientId: clientId,
            nationalId: nationalId,
            clientName: clientName,
            tableNumber: tableNumber,
            createdAt: createdAt,
            updatedAt: Date(),
            scheduledAt: scheduledAt,
            scheduledDayKey: scheduledDayKey,
            serviceMode: serviceMode,
            items: trustedItems,
            subtotal: trustedSubtotal,
            loyaltyDiscountAmount: safeDiscount,
            appliedRewards: appliedRewards,
            totalAmount: max(0, trustedSubtotal - safeDiscount).roundedMoney,
            status: status,
            revision: revision,
            lastConfirmedRevision: lastConfirmedRevision
        )
    }

    func withLoyalty(
        appliedRewards: [AppliedReward],
        discount: Double
    ) -> Order {
        let safeDiscount = min(max(0, discount), subtotal).roundedMoney

        return Order(
            id: id,
            clientId: clientId,
            nationalId: nationalId,
            clientName: clientName,
            tableNumber: tableNumber,
            createdAt: createdAt,
            updatedAt: updatedAt,
            scheduledAt: scheduledAt,
            scheduledDayKey: scheduledDayKey,
            serviceMode: serviceMode,
            items: items,
            subtotal: subtotal,
            loyaltyDiscountAmount: safeDiscount,
            appliedRewards: appliedRewards,
            totalAmount: max(0, subtotal - safeDiscount).roundedMoney,
            status: status,
            revision: revision,
            lastConfirmedRevision: lastConfirmedRevision
        )
    }

    var totalItems: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    var preparedItemsCount: Int {
        items.reduce(0) { $0 + $1.preparedQuantity }
    }

    var allItemsCompleted: Bool {
        !items.isEmpty && items.allSatisfy(\.isCompleted)
    }

    var hasStartedPreparing: Bool {
        items.contains(where: \.isStarted)
    }

    var requiresReconfirmation: Bool {
        lastConfirmedRevision != revision
    }

    var wasEditedAfterConfirmation: Bool {
        guard let lastConfirmedRevision else { return false }
        return revision > lastConfirmedRevision
    }

    var isScheduledForLater: Bool {
        serviceMode == .scheduled || scheduledAt.timeIntervalSince(createdAt) > OrderScheduleResolver.laterThreshold
    }

    var isScheduledForToday: Bool {
        Calendar.current.isDateInToday(scheduledAt)
    }

    var shouldConsumeCurrentMenuStock: Bool {
        !isScheduledForLater || Calendar.current.isDate(scheduledAt, inSameDayAs: Date())
    }

    var scheduleTitle: String {
        isScheduledForLater ? "Reserva para" : "Preparar ahora"
    }

    var scheduledDateText: String {
        OrderScheduleResolver.displayText(for: scheduledAt)
    }

    func recalculatedStatus() -> OrderStatus {
        if status == .canceled { return .canceled }
        if requiresReconfirmation { return .pending }
        if allItemsCompleted { return .completed }
        if hasStartedPreparing { return .preparing }
        if status == .confirmed { return .confirmed }
        return .pending
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

private extension Double {
    var roundedMoney: Double {
        (self * 100).rounded() / 100
    }
}
